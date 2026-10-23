import 'dart:math';

import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/domain/models/movie_filter.dart';
import 'package:boraver/domain/services/movie_draw.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  final unwatchedComedy = movie(
    '1',
    genres: [Genre.comedy],
    countries: ['BR'],
    year: 2010,
  );
  final unwatchedDrama = movie(
    '2',
    genres: [Genre.drama],
    countries: ['BR'],
    year: 2015,
  );
  final watchedComedy = movie(
    '3',
    genres: [Genre.comedy],
    countries: ['BR'],
    watched: true,
    year: 2012,
  );
  final unwatchedUs = movie(
    '4',
    genres: [Genre.comedy],
    countries: ['US'],
    year: 2010,
  );
  final library = [unwatchedComedy, unwatchedDrama, watchedComedy, unwatchedUs];

  test('por padrão considera apenas não assistidos', () {
    final c = MovieDraw().candidates(
      library,
      filter: MovieFilter.empty,
      includeWatched: false,
    );
    expect(c.map((m) => m.id), ['1', '2', '4']);
  });

  test('incluir assistidos considera toda a biblioteca', () {
    final c = MovieDraw().candidates(
      library,
      filter: MovieFilter.empty,
      includeWatched: true,
    );
    expect(c.length, 4);
  });

  test('o sorteado sempre respeita todos os filtros', () {
    final draw = MovieDraw(random: Random(42));
    final filter = MovieFilter(genres: {Genre.comedy}, countries: {'BR'});
    for (var i = 0; i < 200; i++) {
      final picked = draw.pick(
        draw.candidates(library, filter: filter, includeWatched: false),
      );
      expect(picked!.id, '1');
    }
    for (var i = 0; i < 200; i++) {
      final picked = draw.pick(
        draw.candidates(library, filter: filter, includeWatched: true),
      )!;
      expect(['1', '3'], contains(picked.id));
      expect(filter.matches(picked), isTrue);
    }
  });

  test('sem candidatos retorna null', () {
    final draw = MovieDraw();
    final c = draw.candidates(
      library,
      filter: const MovieFilter(countries: {'JP'}),
      includeWatched: true,
    );
    expect(c, isEmpty);
    expect(draw.pick(c), isNull);
  });

  test('distribuição uniforme entre candidatos', () {
    final draw = MovieDraw(random: Random(7));
    final candidates = [movie('a'), movie('b'), movie('c'), movie('d')];
    final counts = <String, int>{};
    const n = 40000;
    for (var i = 0; i < n; i++) {
      final id = draw.pick(candidates)!.id;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    for (final count in counts.values) {
      // Esperado 25% para cada; tolerância de 1,5 ponto percentual.
      expect(count / n, closeTo(0.25, 0.015));
    }
  });

  test('"sortear outro" evita repetir o anterior quando há alternativa', () {
    final draw = MovieDraw(random: Random(1));
    final candidates = [movie('a'), movie('b')];
    for (var i = 0; i < 50; i++) {
      expect(draw.pick(candidates, avoidId: 'a')!.id, 'b');
    }
    // Com um único candidato, ele pode (e deve) ser sorteado de novo.
    expect(draw.pick([movie('a')], avoidId: 'a')!.id, 'a');
  });
}
