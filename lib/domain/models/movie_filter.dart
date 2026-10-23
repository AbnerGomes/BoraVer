import 'genre.dart';
import 'movie.dart';

/// Filtros combináveis por gênero, país e ano de lançamento.
///
/// Entre categorias diferentes os critérios se somam (E): "Comédia" + "Brasil"
/// retorna apenas comédias brasileiras. Dentro de uma mesma categoria vale
/// "qualquer um" (OU), exceto gêneros com [matchAllGenres] ativo, quando o
/// filme precisa ter todos os gêneros selecionados.
class MovieFilter {
  const MovieFilter({
    this.genres = const {},
    this.matchAllGenres = false,
    this.countries = const {},
    this.yearFrom,
    this.yearTo,
  });

  static const empty = MovieFilter();

  final Set<Genre> genres;
  final bool matchAllGenres;
  final Set<String> countries;
  final int? yearFrom;
  final int? yearTo;

  bool get hasYear => yearFrom != null || yearTo != null;
  bool get isEmpty => genres.isEmpty && countries.isEmpty && !hasYear;
  int get activeCount => genres.length + countries.length + (hasYear ? 1 : 0);

  bool matches(Movie movie) {
    if (genres.isNotEmpty) {
      final ok = matchAllGenres
          ? genres.every(movie.genres.contains)
          : genres.any(movie.genres.contains);
      if (!ok) return false;
    }
    if (countries.isNotEmpty && !countries.any(movie.countries.contains)) {
      return false;
    }
    if (hasYear) {
      final year = movie.year;
      // Sem ano registrado não há como garantir que atende ao filtro.
      if (year == null) return false;
      if (yearFrom != null && year < yearFrom!) return false;
      if (yearTo != null && year > yearTo!) return false;
    }
    return true;
  }

  /// Texto curto para o filtro de ano, ex.: "1990–1999", "a partir de 2000", "2010".
  String? get yearLabel {
    if (!hasYear) return null;
    if (yearFrom != null && yearTo != null) {
      return yearFrom == yearTo ? '$yearFrom' : '$yearFrom–$yearTo';
    }
    return yearFrom != null ? 'A partir de $yearFrom' : 'Até $yearTo';
  }

  MovieFilter copyWith({
    Set<Genre>? genres,
    bool? matchAllGenres,
    Set<String>? countries,
  }) => MovieFilter(
    genres: genres ?? this.genres,
    matchAllGenres: matchAllGenres ?? this.matchAllGenres,
    countries: countries ?? this.countries,
    yearFrom: yearFrom,
    yearTo: yearTo,
  );

  MovieFilter withYears(int? from, int? to) => MovieFilter(
    genres: genres,
    matchAllGenres: matchAllGenres,
    countries: countries,
    yearFrom: from,
    yearTo: to,
  );

  MovieFilter withoutGenre(Genre genre) =>
      copyWith(genres: {...genres}..remove(genre));

  MovieFilter withoutCountry(String code) =>
      copyWith(countries: {...countries}..remove(code));

  MovieFilter withoutYears() => withYears(null, null);

  @override
  bool operator ==(Object other) =>
      other is MovieFilter &&
      other.matchAllGenres == matchAllGenres &&
      other.yearFrom == yearFrom &&
      other.yearTo == yearTo &&
      other.genres.length == genres.length &&
      other.genres.containsAll(genres) &&
      other.countries.length == countries.length &&
      other.countries.containsAll(countries);

  @override
  int get hashCode => Object.hash(
    matchAllGenres,
    yearFrom,
    yearTo,
    Object.hashAllUnordered(genres),
    Object.hashAllUnordered(countries),
  );
}
