import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../domain/models/movie.dart';
import 'movie_repository.dart';

/// Armazenamento local com Hive: arquivos no diretório do app no Android e
/// IndexedDB no navegador. Cada filme é salvo como JSON sob o seu id, o que
/// dispensa geração de código e facilita o backup.
class HiveStorage {
  HiveStorage._(this._movies);

  static const moviesBox = 'movies';

  final Box<String> _movies;

  /// [Hive] já deve estar inicializado (Hive.initFlutter() no app,
  /// Hive.init(dir) nos testes).
  static Future<HiveStorage> open() async {
    final movies = await Hive.openBox<String>(moviesBox);
    return HiveStorage._(movies);
  }

  MovieRepository get movies => _HiveMovieRepository(_movies);

  Future<void> close() async {
    await _movies.close();
  }
}

class _HiveMovieRepository implements MovieRepository {
  _HiveMovieRepository(this._box);

  final Box<String> _box;

  @override
  Future<List<Movie>> loadAll() async {
    final movies = <Movie>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        movies.add(Movie.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (error) {
        // Um registro corrompido não pode impedir o app de abrir; ele é
        // mantido no banco (não é apagado) e apenas ignorado na leitura.
        debugPrint('BoraVer: registro "$key" ignorado ($error)');
      }
    }
    return movies;
  }

  @override
  Future<void> save(Movie movie) =>
      _box.put(movie.id, jsonEncode(movie.toJson()));

  @override
  Future<void> saveAll(Iterable<Movie> movies) =>
      _box.putAll({for (final m in movies) m.id: jsonEncode(m.toJson())});

  @override
  Future<void> delete(String id) => _box.delete(id);
}
