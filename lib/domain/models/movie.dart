import 'genre.dart';

/// Marca "não alterar" nos parâmetros anuláveis de [Movie.copyWith].
const Object _keep = Object();

/// Um filme da biblioteca. É imutável: alterações geram uma nova instância.
///
/// O número de visualizações é derivado de [watchSessions], que guarda a data
/// de cada sessão. [watched] indica em qual lista o filme aparece; voltar um
/// filme para "Quero assistir" não apaga sessões, nota nem resenha.
class Movie {
  Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.year,
    List<String> countries = const [],
    List<Genre> genres = const [],
    this.synopsis,
    this.posterUrl,
    this.watched = false,
    this.rating,
    this.review,
    List<DateTime> watchSessions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.tmdbId,
  }) : assert(rating == null || (rating >= 1 && rating <= 5)),
       countries = List.unmodifiable(countries),
       genres = List.unmodifiable(genres),
       watchSessions = List.unmodifiable([...watchSessions]..sort());

  final String id;
  final String title;
  final String? originalTitle;

  /// Ano de lançamento do filme (não confundir com [createdAt]).
  final int? year;

  /// Códigos ISO 3166-1 alfa-2.
  final List<String> countries;
  final List<Genre> genres;
  final String? synopsis;
  final String? posterUrl;
  final bool watched;

  /// Nota pessoal de 1 a 5; `null` significa "sem avaliação".
  final int? rating;
  final String? review;

  /// Datas das sessões, em ordem cronológica.
  final List<DateTime> watchSessions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? tmdbId;

  int get watchCount => watchSessions.length;
  DateTime? get lastWatchedAt =>
      watchSessions.isEmpty ? null : watchSessions.last;
  bool get isRated => rating != null;
  bool get hasReview => review != null && review!.trim().isNotEmpty;

  Movie copyWith({
    String? title,
    Object? originalTitle = _keep,
    Object? year = _keep,
    List<String>? countries,
    List<Genre>? genres,
    Object? synopsis = _keep,
    Object? posterUrl = _keep,
    bool? watched,
    Object? rating = _keep,
    Object? review = _keep,
    List<DateTime>? watchSessions,
    DateTime? updatedAt,
    Object? tmdbId = _keep,
  }) {
    return Movie(
      id: id,
      title: title ?? this.title,
      originalTitle: identical(originalTitle, _keep)
          ? this.originalTitle
          : originalTitle as String?,
      year: identical(year, _keep) ? this.year : year as int?,
      countries: countries ?? this.countries,
      genres: genres ?? this.genres,
      synopsis: identical(synopsis, _keep)
          ? this.synopsis
          : synopsis as String?,
      posterUrl: identical(posterUrl, _keep)
          ? this.posterUrl
          : posterUrl as String?,
      watched: watched ?? this.watched,
      rating: identical(rating, _keep) ? this.rating : rating as int?,
      review: identical(review, _keep) ? this.review : review as String?,
      watchSessions: watchSessions ?? this.watchSessions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tmdbId: identical(tmdbId, _keep) ? this.tmdbId : tmdbId as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'originalTitle': originalTitle,
    'year': year,
    'countries': countries,
    'genres': [for (final g in genres) g.id],
    'synopsis': synopsis,
    'posterUrl': posterUrl,
    'watched': watched,
    'rating': rating,
    'review': review,
    'watchSessions': [for (final d in watchSessions) d.toIso8601String()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tmdbId': tmdbId,
  };

  /// Lê um filme salvo. Lança [FormatException] se os campos obrigatórios
  /// estiverem ausentes ou inválidos; campos opcionais inválidos são ignorados.
  factory Movie.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        title.trim().isEmpty) {
      throw const FormatException('Filme sem id ou título.');
    }
    final createdAt = _parseDate(json['createdAt']) ?? DateTime.now();
    final rating = json['rating'];
    return Movie(
      id: id,
      title: title.trim(),
      originalTitle: _optionalString(json['originalTitle']),
      year: json['year'] is int ? json['year'] as int : null,
      countries: [
        for (final c in _list(json['countries']))
          if (c is String && c.length == 2) c.toUpperCase(),
      ],
      genres: [
        for (final g in _list(json['genres']))
          if (g is String && Genre.fromId(g) != null) Genre.fromId(g)!,
      ],
      synopsis: _optionalString(json['synopsis']),
      posterUrl: _optionalString(json['posterUrl']),
      watched: json['watched'] == true,
      rating: rating is int && rating >= 1 && rating <= 5 ? rating : null,
      review: _optionalString(json['review']),
      watchSessions: [
        for (final d in _list(json['watchSessions']))
          if (_parseDate(d) != null) _parseDate(d)!,
      ],
      createdAt: createdAt,
      updatedAt: _parseDate(json['updatedAt']) ?? createdAt,
      tmdbId: json['tmdbId'] is int ? json['tmdbId'] as int : null,
    );
  }

  static List<dynamic> _list(Object? value) => value is List ? value : const [];

  static String? _optionalString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
