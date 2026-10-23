import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/domain/models/movie_filter.dart';
import 'package:boraver/domain/services/movie_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  final brComedy = movie(
    '1',
    genres: [Genre.comedy],
    countries: ['BR'],
    year: 2003,
    title: 'Lisbela',
  );
  final usComedy = movie(
    '2',
    genres: [Genre.comedy, Genre.romance],
    countries: ['US'],
    year: 1999,
  );
  final brDrama = movie(
    '3',
    genres: [Genre.drama],
    countries: ['BR', 'FR'],
    year: 2019,
  );
  final noYear = movie('4', genres: [Genre.comedy], countries: ['BR']);
  final all = [brComedy, usComedy, brDrama, noYear];

  List<String> ids(MovieFilter f) =>
      all.where(f.matches).map((m) => m.id).toList();

  test('filtro vazio aceita tudo', () {
    expect(MovieFilter.empty.isEmpty, isTrue);
    expect(ids(MovieFilter.empty), ['1', '2', '3', '4']);
  });

  test('gênero e país se combinam (E)', () {
    final f = MovieFilter(genres: {Genre.comedy}, countries: {'BR'});
    expect(ids(f), ['1', '4']);
  });

  test('vários gêneros: qualquer um por padrão, todos quando exigido', () {
    final any = MovieFilter(genres: {Genre.comedy, Genre.drama});
    expect(ids(any), ['1', '2', '3', '4']);
    final both = MovieFilter(
      genres: {Genre.comedy, Genre.romance},
      matchAllGenres: true,
    );
    expect(ids(both), ['2']);
  });

  test('filme com vários países atende a qualquer um deles', () {
    expect(ids(const MovieFilter(countries: {'FR'})), ['3']);
  });

  test('intervalo de anos e ano exato; sem ano nunca passa', () {
    expect(ids(const MovieFilter().withYears(2000, 2020)), ['1', '3']);
    expect(ids(const MovieFilter().withYears(1999, 1999)), ['2']);
    expect(ids(const MovieFilter().withYears(2010, null)), ['3']);
    expect(ids(const MovieFilter().withYears(null, 2000)), ['2']);
  });

  test('três critérios combinados', () {
    final f = MovieFilter(
      genres: {Genre.comedy},
      countries: {'BR'},
    ).withYears(2000, 2010);
    expect(ids(f), ['1']);
  });

  test('remoção individual de filtros', () {
    final f = MovieFilter(
      genres: {Genre.comedy, Genre.drama},
      countries: {'BR'},
    ).withYears(2000, 2010);
    expect(f.activeCount, 4);
    expect(f.withoutGenre(Genre.drama).genres, {Genre.comedy});
    expect(f.withoutCountry('BR').countries, isEmpty);
    expect(f.withoutYears().hasYear, isFalse);
    expect(f.yearLabel, '2000–2010');
  });

  test('igualdade ignora a ordem dos conjuntos', () {
    expect(
      MovieFilter(genres: {Genre.comedy, Genre.drama}),
      MovieFilter(genres: {Genre.drama, Genre.comedy}),
    );
  });

  group('queryMovies', () {
    test('busca ignora acentos e maiúsculas e olha o título original', () {
      final m = movie(
        '9',
        title: 'Cidade de Deus',
        originalTitle: 'City of God',
      );
      expect(queryMovies([m], search: 'cidade de deus').length, 1);
      expect(queryMovies([m], search: 'CIDADE'), isNotEmpty);
      expect(queryMovies([m], search: 'city'), isNotEmpty);
      expect(queryMovies([brComedy], search: 'lísbela'), isNotEmpty);
      expect(queryMovies([m], search: 'matrix'), isEmpty);
    });

    test('status separa as listas', () {
      final w = movie('w', watched: true);
      final u = movie('u');
      expect(
        queryMovies([w, u], status: WatchStatusView.toWatch).single.id,
        'u',
      );
      expect(
        queryMovies([w, u], status: WatchStatusView.watched).single.id,
        'w',
      );
      expect(queryMovies([w, u]).length, 2);
    });

    test('ordenação por ano deixa filmes sem ano no fim', () {
      final r = queryMovies(all, sort: MovieSort.yearDesc).map((m) => m.id);
      expect(r, ['3', '1', '2', '4']);
      final a = queryMovies(all, sort: MovieSort.yearAsc).map((m) => m.id);
      expect(a, ['2', '1', '3', '4']);
    });

    test('ordenação por nota e por data de inclusão', () {
      final a = movie('a', rating: 3, createdAt: DateTime(2026, 1, 2));
      final b = movie('b', rating: 5, createdAt: DateTime(2026, 1, 1));
      final c = movie('c', createdAt: DateTime(2026, 1, 3));
      expect(
        queryMovies([a, b, c], sort: MovieSort.ratingDesc).map((m) => m.id),
        ['b', 'a', 'c'],
      );
      expect(
        queryMovies([a, b, c], sort: MovieSort.recentlyAdded).map((m) => m.id),
        ['c', 'a', 'b'],
      );
    });
  });
}
