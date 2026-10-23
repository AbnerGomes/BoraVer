import '../../core/utils/text_normalize.dart';
import '../models/movie.dart';
import '../models/movie_filter.dart';

/// Qual parte da biblioteca exibir.
enum WatchStatusView {
  toWatch('Quero assistir'),
  watched('Já assisti'),
  all('Todos');

  const WatchStatusView(this.label);
  final String label;

  bool includes(Movie movie) => switch (this) {
    WatchStatusView.toWatch => !movie.watched,
    WatchStatusView.watched => movie.watched,
    WatchStatusView.all => true,
  };
}

enum MovieSort {
  recentlyAdded('Adicionados recentemente'),
  titleAsc('Título (A–Z)'),
  yearDesc('Lançamento (mais novos)'),
  yearAsc('Lançamento (mais antigos)'),
  ratingDesc('Melhor avaliados'),
  recentlyWatched('Assistidos recentemente');

  const MovieSort(this.label);
  final String label;
}

/// Busca por título (ou título original), ignorando maiúsculas e acentos.
bool matchesSearch(Movie movie, String query) {
  final q = normalizeText(query);
  if (q.isEmpty) return true;
  return normalizeText(movie.title).contains(q) ||
      (movie.originalTitle != null &&
          normalizeText(movie.originalTitle!).contains(q));
}

/// Aplica status, busca, filtros e ordenação.
List<Movie> queryMovies(
  Iterable<Movie> movies, {
  WatchStatusView status = WatchStatusView.all,
  String search = '',
  MovieFilter filter = MovieFilter.empty,
  MovieSort sort = MovieSort.recentlyAdded,
}) {
  final result = movies
      .where(
        (m) =>
            status.includes(m) && matchesSearch(m, search) && filter.matches(m),
      )
      .toList();
  sortMovies(result, sort);
  return result;
}

void sortMovies(List<Movie> movies, MovieSort sort) {
  int byTitle(Movie a, Movie b) => compareText(a.title, b.title);
  // Valores ausentes (ano, nota, data) vão sempre para o fim da lista.
  int nullsLast(Comparable? a, Comparable? b, {bool desc = false}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return desc ? b.compareTo(a) : a.compareTo(b);
  }

  movies.sort((a, b) {
    final primary = switch (sort) {
      MovieSort.recentlyAdded => b.createdAt.compareTo(a.createdAt),
      MovieSort.titleAsc => byTitle(a, b),
      MovieSort.yearDesc => nullsLast(a.year, b.year, desc: true),
      MovieSort.yearAsc => nullsLast(a.year, b.year),
      MovieSort.ratingDesc => nullsLast(a.rating, b.rating, desc: true),
      MovieSort.recentlyWatched => nullsLast(
        a.lastWatchedAt,
        b.lastWatchedAt,
        desc: true,
      ),
    };
    return primary != 0 ? primary : byTitle(a, b);
  });
}
