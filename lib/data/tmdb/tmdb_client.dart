import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/genre.dart';

/// Integração com o TMDB (themoviedb.org): é daqui que vêm título, pôster,
/// sinopse, gêneros, países e ano dos filmes adicionados.
///
/// A chave do app é injetada no build (`--dart-define=TMDB_API_KEY=...`),
/// nunca escrita no código-fonte. Aceita a "API Key" (v3) ou o
/// "Read Access Token" (v4).
class TmdbClient {
  TmdbClient(this.apiKey, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  /// Chave definida no build; vazia quando o app foi compilado sem ela.
  static const buildApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// Cliente com a chave do build, ou `null` se o build não tiver chave.
  static TmdbClient? fromBuild() =>
      buildApiKey.trim().isEmpty ? null : TmdbClient(buildApiKey.trim());

  final String apiKey;
  final http.Client _http;

  static const _host = 'api.themoviedb.org';
  static const _imageBase = 'https://image.tmdb.org/t/p';
  static const _timeout = Duration(seconds: 12);

  bool get _isBearerToken => apiKey.startsWith('eyJ') && apiKey.contains('.');

  Future<List<TmdbMovieSummary>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return _summaries(
      await _get('/3/search/movie', {
        'query': trimmed,
        'include_adult': 'false',
      }),
    );
  }

  /// Filmes em alta na semana (sugestões antes de digitar).
  Future<List<TmdbMovieSummary>> trending() async =>
      _summaries(await _get('/3/trending/movie/week', const {}));

  /// Detalhes completos. Se não houver sinopse em português, usa a original
  /// em inglês do próprio TMDB (nunca inventa um texto).
  Future<TmdbMovieDetails> details(int id) async {
    final details = TmdbMovieDetails.fromJson(
      await _get('/3/movie/$id', const {}),
    );
    if (details.overview != null) return details;
    try {
      final english = TmdbMovieDetails.fromJson(
        await _get('/3/movie/$id', const {}, language: 'en-US'),
      );
      return details.withOverview(english.overview);
    } on TmdbException {
      return details;
    }
  }

  List<TmdbMovieSummary> _summaries(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is! List) return const [];
    return [
      for (final r in results)
        if (r is Map<String, dynamic> && r['id'] is int)
          TmdbMovieSummary.fromJson(r),
    ];
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params, {
    String language = 'pt-BR',
  }) async {
    final uri = Uri.https(_host, path, {
      ...params,
      'language': language,
      if (!_isBearerToken) 'api_key': apiKey,
    });
    final http.Response response;
    try {
      response = await _http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (_isBearerToken) 'Authorization': 'Bearer $apiKey',
            },
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const TmdbException(
        'O TMDB demorou para responder. Tente de novo.',
      );
    } catch (_) {
      throw const TmdbException(
        'Não foi possível conectar ao TMDB. Verifique sua internet.',
      );
    }
    if (response.statusCode == 401) {
      throw const TmdbException(
        'A busca de filmes está indisponível (chave do TMDB inválida).',
      );
    }
    if (response.statusCode == 404) {
      throw const TmdbException('Filme não encontrado no TMDB.');
    }
    if (response.statusCode != 200) {
      throw TmdbException(
        'O TMDB respondeu com erro (${response.statusCode}).',
      );
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const TmdbException('Resposta inesperada do TMDB.');
    }
  }

  static String? posterUrl(String? path, {String size = 'w500'}) =>
      path == null || path.isEmpty ? null : '$_imageBase/$size$path';

  void close() => _http.close();
}

class TmdbException implements Exception {
  const TmdbException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TmdbMovieSummary {
  const TmdbMovieSummary({
    required this.id,
    required this.title,
    this.originalTitle,
    this.year,
    this.posterPath,
    this.overview,
  });

  factory TmdbMovieSummary.fromJson(Map<String, dynamic> json) =>
      TmdbMovieSummary(
        id: json['id'] as int,
        title: (json['title'] as String?)?.trim() ?? '',
        originalTitle: _nonEmpty(json['original_title']),
        year: _year(json['release_date']),
        posterPath: _nonEmpty(json['poster_path']),
        overview: _nonEmpty(json['overview']),
      );

  final int id;
  final String title;
  final String? originalTitle;
  final int? year;
  final String? posterPath;
  final String? overview;

  String? get thumbnailUrl => TmdbClient.posterUrl(posterPath, size: 'w154');
}

class TmdbMovieDetails {
  const TmdbMovieDetails({
    required this.id,
    required this.title,
    this.originalTitle,
    this.year,
    this.countries = const [],
    this.genres = const [],
    this.overview,
    this.posterUrl,
  });

  factory TmdbMovieDetails.fromJson(Map<String, dynamic> json) {
    // Prefere o país de origem; se ausente, usa os países de produção.
    final origin = [
      for (final c in json['origin_country'] as List? ?? const [])
        if (c is String && c.length == 2) c.toUpperCase(),
    ];
    final production = [
      for (final c in json['production_countries'] as List? ?? const [])
        if (c is Map && c['iso_3166_1'] is String)
          (c['iso_3166_1'] as String).toUpperCase(),
    ];
    final genres = <Genre>{
      for (final g in json['genres'] as List? ?? const [])
        if (g is Map && _genreByTmdbId[g['id']] != null)
          _genreByTmdbId[g['id']]!,
    };
    final title = (json['title'] as String?)?.trim() ?? '';
    final originalTitle = _nonEmpty(json['original_title']);
    return TmdbMovieDetails(
      id: json['id'] as int,
      title: title,
      originalTitle: originalTitle == title ? null : originalTitle,
      year: _year(json['release_date']),
      countries: origin.isNotEmpty ? origin : production,
      genres: genres.toList(),
      overview: _nonEmpty(json['overview']),
      posterUrl: TmdbClient.posterUrl(_nonEmpty(json['poster_path'])),
    );
  }

  final int id;
  final String title;
  final String? originalTitle;
  final int? year;
  final List<String> countries;
  final List<Genre> genres;
  final String? overview;
  final String? posterUrl;

  TmdbMovieDetails withOverview(String? overview) => TmdbMovieDetails(
    id: id,
    title: title,
    originalTitle: originalTitle,
    year: year,
    countries: countries,
    genres: genres,
    overview: overview,
    posterUrl: posterUrl,
  );
}

const _genreByTmdbId = <int, Genre>{
  28: Genre.action,
  12: Genre.adventure,
  16: Genre.animation,
  35: Genre.comedy,
  80: Genre.crime,
  99: Genre.documentary,
  18: Genre.drama,
  10751: Genre.family,
  14: Genre.fantasy,
  36: Genre.history,
  27: Genre.horror,
  10402: Genre.musical,
  9648: Genre.mystery,
  10749: Genre.romance,
  878: Genre.scienceFiction,
  53: Genre.thriller,
  10752: Genre.war,
  37: Genre.western,
};

String? _nonEmpty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

int? _year(Object? releaseDate) =>
    releaseDate is String && releaseDate.length >= 4
    ? int.tryParse(releaseDate.substring(0, 4))
    : null;
