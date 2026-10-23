import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/movie_repository.dart';
import '../data/tmdb/tmdb_client.dart';
import '../domain/models/genre.dart';
import '../domain/models/movie.dart';
import '../domain/services/duplicate_checker.dart' as dup;
import '../domain/services/movie_query.dart';

/// Campos editáveis no formulário de cadastro/edição.
class MovieInput {
  const MovieInput({
    required this.title,
    this.originalTitle,
    this.year,
    this.countries = const [],
    this.genres = const [],
    this.synopsis,
    this.posterUrl,
    this.rating,
    this.review,
    this.tmdbId,
    this.watched = false,
  });

  final String title;
  final String? originalTitle;
  final int? year;
  final List<String> countries;
  final List<Genre> genres;
  final String? synopsis;
  final String? posterUrl;
  final int? rating;
  final String? review;
  final int? tmdbId;

  /// Só é usado ao adicionar; depois o estado muda pelas ações de visualização.
  final bool watched;
}

class ImportResult {
  const ImportResult({
    this.added = 0,
    this.updated = 0,
    this.unchanged = 0,
    this.duplicates = 0,
    this.invalid = 0,
  });

  final int added;
  final int updated;
  final int unchanged;
  final int duplicates;
  final int invalid;
}

/// Mantém a biblioteca em memória, sincronizada com o [MovieRepository].
///
/// Toda alteração é gravada primeiro no armazenamento; o estado em memória só
/// muda se a gravação der certo, evitando mostrar algo que não foi salvo.
class LibraryController extends ChangeNotifier {
  LibraryController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MovieRepository _repository;
  final DateTime Function() _clock;
  final Map<String, Movie> _movies = {};
  final Random _random = Random();

  bool _loaded = false;
  String? _loadError;

  bool get isLoaded => _loaded;
  String? get loadError => _loadError;

  List<Movie> get movies => List.unmodifiable(_movies.values);
  int get totalCount => _movies.length;
  int get watchedCount => _movies.values.where((m) => m.watched).length;
  int get toWatchCount => totalCount - watchedCount;

  Movie? byId(String id) => _movies[id];

  List<Movie> recentlyAdded({int limit = 10}) => queryMovies(
    _movies.values,
    sort: MovieSort.recentlyAdded,
  ).take(limit).toList();

  Future<void> load() async {
    try {
      final list = await _repository.loadAll();
      _movies
        ..clear()
        ..addEntries(list.map((m) => MapEntry(m.id, m)));
      _loadError = null;
    } catch (error) {
      debugPrint('BoraVer: falha ao carregar biblioteca ($error)');
      _loadError = 'Não foi possível abrir sua biblioteca neste dispositivo.';
    }
    _loaded = true;
    notifyListeners();
  }

  Movie? findDuplicate({
    required String title,
    String? originalTitle,
    int? year,
    int? tmdbId,
    String? excludeId,
  }) => dup.findDuplicate(
    _movies.values,
    title: title,
    originalTitle: originalTitle,
    year: year,
    tmdbId: tmdbId,
    excludeId: excludeId,
  );

  /// Filme da biblioteca que corresponde a um resultado do TMDB, se houver.
  Movie? findByTmdb(int tmdbId, {required String title, int? year}) =>
      findDuplicate(title: title, year: year, tmdbId: tmdbId);

  /// Adiciona um filme com todos os dados vindos do TMDB.
  Future<Movie> addFromTmdb(TmdbMovieDetails d, {bool watched = false}) => add(
    MovieInput(
      title: d.title,
      originalTitle: d.originalTitle,
      year: d.year,
      countries: d.countries,
      genres: d.genres,
      synopsis: d.overview,
      posterUrl: d.posterUrl,
      tmdbId: d.id,
      watched: watched,
    ),
  );

  Future<Movie> add(MovieInput input) async {
    final now = _clock();
    final movie = Movie(
      id: _newId(now),
      title: input.title.trim(),
      originalTitle: _clean(input.originalTitle),
      year: input.year,
      countries: input.countries,
      genres: input.genres,
      synopsis: _clean(input.synopsis),
      posterUrl: _clean(input.posterUrl),
      rating: input.rating,
      review: _clean(input.review),
      tmdbId: input.tmdbId,
      watched: input.watched,
      // Cadastrar como "já assisti" registra a primeira visualização.
      watchSessions: input.watched ? [now] : const [],
      createdAt: now,
      updatedAt: now,
    );
    await _persist(movie);
    return movie;
  }

  Future<void> update(String id, MovieInput input) => _change(
    id,
    (m) => m.copyWith(
      title: input.title.trim(),
      originalTitle: _clean(input.originalTitle),
      year: input.year,
      countries: input.countries,
      genres: input.genres,
      synopsis: _clean(input.synopsis),
      posterUrl: _clean(input.posterUrl),
      rating: input.rating,
      review: _clean(input.review),
      tmdbId: input.tmdbId,
    ),
  );

  /// Move para "Já assisti". Registra uma visualização apenas se ainda não
  /// houver nenhuma: assim, desfazer e refazer a marcação não infla o
  /// contador. Para novas sessões existe [watchAgain].
  Future<void> markWatched(String id) => _change(id, (m) {
    if (m.watched) return m;
    return m.copyWith(
      watched: true,
      watchSessions: m.watchSessions.isEmpty ? [_clock()] : null,
    );
  });

  /// "Assisti novamente": nova sessão (na data informada ou agora).
  Future<void> watchAgain(String id, {DateTime? at}) => _change(
    id,
    (m) => m.copyWith(
      watched: true,
      watchSessions: [...m.watchSessions, at ?? _clock()],
    ),
  );

  /// Volta para "Quero assistir" preservando sessões, nota e resenha.
  Future<void> markUnwatched(String id) =>
      _change(id, (m) => m.watched ? m.copyWith(watched: false) : m);

  /// Remove uma sessão do histórico (ex.: registrada por engano).
  Future<void> removeSession(String id, DateTime session) => _change(
    id,
    (m) => m.copyWith(watchSessions: [...m.watchSessions]..remove(session)),
  );

  Future<void> setRating(String id, int? rating) {
    assert(rating == null || (rating >= 1 && rating <= 5));
    return _change(id, (m) => m.copyWith(rating: rating));
  }

  Future<void> setReview(String id, String? review) =>
      _change(id, (m) => m.copyWith(review: _clean(review)));

  /// Restaura uma versão anterior do filme (usado pelo "Desfazer").
  Future<void> restore(Movie previous) =>
      _persist(previous.copyWith(updatedAt: _clock()));

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _movies.remove(id);
    notifyListeners();
  }

  /// Mescla filmes de um backup: novos são adicionados; os já existentes
  /// (mesmo id) são substituídos só se a versão do backup for mais recente.
  /// Filmes com outro id mas mesmo título/ano são ignorados como duplicatas.
  Future<ImportResult> importMovies(
    List<Movie> incoming, {
    int invalid = 0,
  }) async {
    final toSave = <Movie>[];
    var added = 0, updated = 0, unchanged = 0, duplicates = 0;
    final merged = Map.of(_movies);

    for (final movie in incoming) {
      final existing = merged[movie.id];
      if (existing != null) {
        if (movie.updatedAt.isAfter(existing.updatedAt)) {
          merged[movie.id] = movie;
          toSave.add(movie);
          updated++;
        } else {
          unchanged++;
        }
        continue;
      }
      final duplicate = dup.findDuplicate(
        merged.values,
        title: movie.title,
        originalTitle: movie.originalTitle,
        year: movie.year,
        tmdbId: movie.tmdbId,
      );
      if (duplicate != null) {
        duplicates++;
        continue;
      }
      merged[movie.id] = movie;
      toSave.add(movie);
      added++;
    }

    if (toSave.isNotEmpty) {
      await _repository.saveAll(toSave);
      _movies
        ..clear()
        ..addAll(merged);
      notifyListeners();
    }
    return ImportResult(
      added: added,
      updated: updated,
      unchanged: unchanged,
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  Future<void> _change(String id, Movie Function(Movie) transform) async {
    final current = _movies[id];
    if (current == null) {
      throw StateError('Filme não encontrado.');
    }
    final next = transform(current);
    if (identical(next, current)) return;
    await _persist(next.copyWith(updatedAt: _clock()));
  }

  Future<void> _persist(Movie movie) async {
    await _repository.save(movie);
    _movies[movie.id] = movie;
    notifyListeners();
  }

  // Atenção: na Web, `1 << 32` vale 0 (operações de bits são de 32 bits no
  // JavaScript); por isso o limite é escrito como literal.
  static const _idRandomMax = 0xFFFFFFFF;

  String _newId(DateTime now) =>
      '${now.microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(_idRandomMax).toRadixString(36).padLeft(7, '0')}';

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
