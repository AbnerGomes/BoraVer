// Gera capturas de tela das principais telas para revisão visual
// (em build/screenshots/, fora do controle de versão).
//
// Uso (no container):
//   docker compose run --rm flutter flutter test tool/screenshots_test.dart --update-goldens
//
// Os filmes abaixo existem só para ilustrar as capturas; nada disso entra no app.
import 'package:boraver/app.dart';
import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/domain/models/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers/fakes.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('Poppins', [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
  ]);
  await load('DMSerifDisplay', ['assets/fonts/DMSerifDisplay-Regular.ttf']);
  await load('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
}

List<Movie> _sample() {
  final d = DateTime(2026, 10, 1);
  Movie m(
    String id,
    String title,
    int year,
    List<String> c,
    List<Genre> g, {
    bool watched = false,
    int? rating,
    int views = 0,
    String? review,
    String? original,
  }) => Movie(
    id: id,
    title: title,
    originalTitle: original,
    year: year,
    countries: c,
    genres: g,
    watched: watched,
    rating: rating,
    review: review,
    synopsis: watched
        ? null
        : 'Sinopse de exemplo para visualizar o layout do cartão.',
    watchSessions: [
      for (var i = 0; i < views; i++) d.subtract(Duration(days: 40 * (i + 1))),
    ],
    createdAt: d.subtract(Duration(days: int.parse(id))),
    updatedAt: d,
  );
  return [
    m('1', 'Filme Exemplo Um', 2019, ['BR'], [Genre.drama, Genre.thriller]),
    m(
      '2',
      'Uma Comédia de Exemplo',
      2003,
      ['BR', 'PT'],
      [Genre.comedy, Genre.romance],
    ),
    m(
      '3',
      'Aventura Espacial',
      2014,
      ['US', 'GB'],
      [Genre.scienceFiction, Genre.adventure],
      original: 'Space Adventure',
    ),
    m(
      '4',
      'Animação Visto',
      2001,
      ['JP'],
      [Genre.animation, Genre.fantasy],
      watched: true,
      rating: 5,
      views: 3,
      review: 'Revi e continua lindo.',
    ),
    m(
      '5',
      'Documentário Visto',
      2020,
      ['FR'],
      [Genre.documentary],
      watched: true,
      rating: 3,
      views: 1,
    ),
  ];
}

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Size size,
    Future<void> Function()? navigate,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BoraVerApp(
        movieRepository: InMemoryMovieRepository(_sample()),
        tmdb: fakeTmdb(),
      ),
    );
    await tester.pumpAndSettle();
    if (navigate != null) await navigate();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/screenshots/$name.png'),
    );
  }

  const phone = Size(400, 860);
  const desktop = Size(1280, 800);

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text).first);
    await t.pumpAndSettle();
  }

  testWidgets('home phone', (t) => shoot(t, 'home_phone', phone, null));
  testWidgets('home desktop', (t) => shoot(t, 'home_desktop', desktop, null));
  testWidgets(
    'library phone',
    (t) => shoot(t, 'library_phone', phone, () => tapText(t, 'Biblioteca')),
  );
  testWidgets(
    'library desktop',
    (t) => shoot(t, 'library_desktop', desktop, () => tapText(t, 'Biblioteca')),
  );
  testWidgets(
    'draw phone',
    (t) => shoot(t, 'draw_phone', phone, () async {
      await t.tap(find.text('Bora ver?').first);
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
    }),
  );
  testWidgets(
    'draw desktop',
    (t) => shoot(t, 'draw_desktop', desktop, () async {
      await t.tap(find.text('Bora ver?').first);
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
    }),
  );
  testWidgets(
    'detail phone',
    (t) => shoot(t, 'detail_phone', phone, () async {
      await tapText(t, 'Biblioteca');
      await tapText(t, 'Já assisti (2)');
      await tapText(t, 'Animação Visto');
    }),
  );
  testWidgets(
    'form phone',
    (t) => shoot(
      t,
      'form_phone',
      phone,
      () => tapText(t, 'Biblioteca').then((_) => tapText(t, 'Adicionar')),
    ),
  );
  testWidgets(
    'filters phone',
    (t) => shoot(t, 'filters_phone', phone, () async {
      await tapText(t, 'Sortear');
      await t.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilterChip, 'Comédia'));
      await t.pumpAndSettle();
    }),
  );
  testWidgets(
    'settings phone',
    (t) => shoot(t, 'settings_phone', phone, () => tapText(t, 'Ajustes')),
  );
  testWidgets(
    'add phone',
    (t) => shoot(t, 'add_phone', phone, () async {
      await t.tap(find.byTooltip('Adicionar filme'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'matrix');
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
    }),
  );
}
