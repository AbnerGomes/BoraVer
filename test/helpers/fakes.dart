import 'dart:convert';

import 'package:boraver/data/movie_repository.dart';
import 'package:boraver/data/tmdb/tmdb_client.dart';
import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/domain/models/movie.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Repositório em memória para testes de estado e interface.
class InMemoryMovieRepository implements MovieRepository {
  InMemoryMovieRepository([Iterable<Movie> initial = const []])
    : stored = {for (final m in initial) m.id: m};

  final Map<String, Movie> stored;

  /// Quando verdadeiro, toda gravação falha (simula disco cheio, etc.).
  bool failWrites = false;

  @override
  Future<List<Movie>> loadAll() async => stored.values.toList();

  @override
  Future<void> save(Movie movie) async {
    if (failWrites) throw Exception('falha simulada');
    stored[movie.id] = movie;
  }

  @override
  Future<void> saveAll(Iterable<Movie> movies) async {
    if (failWrites) throw Exception('falha simulada');
    for (final m in movies) {
      stored[m.id] = m;
    }
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw Exception('falha simulada');
    stored.remove(id);
  }
}

final _baseDate = DateTime(2026, 1, 1);

/// Cria um filme de teste com valores padrão razoáveis.
Movie movie(
  String id, {
  String? title,
  int? year,
  List<String> countries = const [],
  List<Genre> genres = const [],
  bool watched = false,
  int? rating,
  List<DateTime>? sessions,
  DateTime? createdAt,
  int? tmdbId,
  String? originalTitle,
}) {
  final created = createdAt ?? _baseDate;
  return Movie(
    id: id,
    title: title ?? 'Filme $id',
    originalTitle: originalTitle,
    year: year,
    countries: countries,
    genres: genres,
    watched: watched,
    rating: rating,
    watchSessions: sessions ?? (watched ? [created] : const []),
    createdAt: created,
    updatedAt: created,
    tmdbId: tmdbId,
  );
}

/// TMDB simulado: "Em alta", busca por "matrix" e detalhes do filme 603.
TmdbClient fakeTmdb() => TmdbClient(
  'k',
  httpClient: MockClient((req) async {
    final Object body = switch (req.url.path) {
      '/3/trending/movie/week' => {
        'results': [
          {'id': 1, 'title': 'Filme em Alta', 'release_date': '2026-01-01'},
        ],
      },
      '/3/search/movie' => {
        'results': [
          if (req.url.queryParameters['query'] == 'matrix')
            {
              'id': 603,
              'title': 'Matrix',
              'original_title': 'The Matrix',
              'release_date': '1999-03-31',
              'poster_path': '/m.jpg',
              'overview': 'Neo descobre a verdade.',
            },
        ],
      },
      '/3/movie/603' => {
        'id': 603,
        'title': 'Matrix',
        'original_title': 'The Matrix',
        'release_date': '1999-03-31',
        'poster_path': '/m.jpg',
        'overview': 'Neo descobre a verdade.',
        'origin_country': ['US'],
        'genres': [
          {'id': 28},
          {'id': 878},
        ],
      },
      _ => throw StateError('rota inesperada ${req.url}'),
    };
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);
