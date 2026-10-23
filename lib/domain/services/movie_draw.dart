import 'dart:math';

import '../models/movie.dart';
import '../models/movie_filter.dart';

/// Regras do sorteio.
class MovieDraw {
  MovieDraw({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Filmes que podem ser sorteados: não assistidos (ou todos, se
  /// [includeWatched]) que atendem a todos os filtros.
  List<Movie> candidates(
    Iterable<Movie> movies, {
    required MovieFilter filter,
    required bool includeWatched,
  }) => movies
      .where((m) => (includeWatched || !m.watched) && filter.matches(m))
      .toList();

  /// Sorteia com probabilidade uniforme entre os candidatos.
  ///
  /// [avoidId] evita repetir o resultado anterior em "Sortear outro" quando
  /// existe mais de uma opção; os demais continuam igualmente prováveis.
  Movie? pick(List<Movie> candidates, {String? avoidId}) {
    if (candidates.isEmpty) return null;
    var pool = candidates;
    if (avoidId != null && candidates.length > 1) {
      pool = candidates.where((m) => m.id != avoidId).toList();
    }
    return pool[_random.nextInt(pool.length)];
  }
}
