import 'package:boraver/app.dart';
import 'package:boraver/data/tmdb/tmdb_client.dart';
import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/domain/models/movie.dart';
import 'package:boraver/ui/screens/add_movie_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Testes de fluxo completos, como um usuário usaria o app.
void main() {
  late InMemoryMovieRepository repo;

  Future<void> startApp(
    WidgetTester tester, {
    List<Movie> movies = const [],
    Size size = const Size(420, 900),
    TmdbClient? tmdb,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repo = InMemoryMovieRepository(movies);
    await tester.pumpWidget(BoraVerApp(movieRepository: repo, tmdb: tmdb));
    await tester.pumpAndSettle();
  }

  Finder navItem(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> drawAndWait(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Bora ver?').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('sem TMDB: cadastro manual e filme em "Quero assistir"', (
    tester,
  ) async {
    await startApp(tester);
    expect(find.text('Sua biblioteca está vazia'), findsOneWidget);

    await tapVisible(tester, find.text('Adicionar primeiro filme'));
    await tester.pumpAndSettle();

    // Título é obrigatório.
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o título do filme.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título *'),
      'O Som ao Redor',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ano de lançamento (opcional)'),
      '2012',
    );
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Drama'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(repo.stored.values.single.title, 'O Som ao Redor');
    expect(repo.stored.values.single.genres, [Genre.drama]);

    await tester.tap(navItem('Biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('O Som ao Redor'), findsOneWidget);
    expect(find.text('Quero ver (1)'), findsOneWidget);
  });

  Future<void> searchFor(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(AddMovieScreen),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pump(
      AddMovieScreen.debounce + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('adicionar = pesquisar o nome e tocar em +; dados vêm do TMDB', (
    tester,
  ) async {
    await startApp(tester, tmdb: fakeTmdb());
    await tapVisible(tester, find.text('Adicionar primeiro filme'));
    expect(find.text('Em alta nesta semana'), findsOneWidget);
    expect(find.text('Filme em Alta'), findsOneWidget);

    await searchFor(tester, 'matrix');
    expect(find.text('Matrix'), findsOneWidget);
    expect(find.text('1999 · The Matrix'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar Matrix'));
    await tester.pumpAndSettle();

    final saved = repo.stored.values.single;
    expect(saved.title, 'Matrix');
    expect(saved.originalTitle, 'The Matrix');
    expect(saved.year, 1999);
    expect(saved.countries, ['US']);
    expect(saved.genres, [Genre.action, Genre.scienceFiction]);
    expect(saved.synopsis, 'Neo descobre a verdade.');
    expect(saved.posterUrl, 'https://image.tmdb.org/t/p/w500/m.jpg');
    expect(saved.tmdbId, 603);
    expect(saved.watched, isFalse);
    // O resultado passa a indicar que já está na biblioteca.
    expect(find.text('Na lista'), findsOneWidget);
    expect(find.byTooltip('Adicionar Matrix'), findsNothing);
  });

  testWidgets('prévia do filme permite adicionar como "Já assisti"', (
    tester,
  ) async {
    await startApp(tester, tmdb: fakeTmdb());
    await tapVisible(tester, find.text('Adicionar primeiro filme'));
    await searchFor(tester, 'matrix');

    await tester.tap(find.text('Matrix'));
    await tester.pumpAndSettle();
    expect(find.text('Neo descobre a verdade.'), findsWidgets);
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Já assisti'));

    final saved = repo.stored.values.single;
    expect(saved.watched, isTrue);
    expect(saved.watchCount, 1);
  });

  testWidgets('busca sem resultado oferece cadastro manual', (tester) async {
    await startApp(tester, tmdb: fakeTmdb());
    await tapVisible(tester, find.text('Adicionar primeiro filme'));
    await searchFor(tester, 'xyz inexistente');
    expect(find.text('Nenhum filme encontrado'), findsOneWidget);
    await tapVisible(tester, find.text('Não achou? Cadastrar manualmente'));
    expect(find.text('Cadastro manual'), findsOneWidget);
  });

  testWidgets('aviso de duplicata ao cadastrar o mesmo filme', (tester) async {
    await startApp(tester, movies: [movie('1', title: 'Bacurau', year: 2019)]);
    await tester.tap(find.byTooltip('Adicionar filme'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título *'),
      'bacurau',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Esse filme já está na biblioteca?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.stored.length, 1);
  });

  testWidgets('sortear, marcar como assistido e ver a troca de lista', (
    tester,
  ) async {
    await startApp(
      tester,
      movies: [
        movie(
          '1',
          title: 'Filme Elegível',
          genres: [Genre.comedy],
          countries: ['BR'],
        ),
        movie('2', title: 'Filme Visto', watched: true),
      ],
    );

    await drawAndWait(tester);
    expect(find.text('HOJE É DIA DE…'), findsOneWidget);
    // Só há um não assistido elegível.
    expect(find.text('Filme Elegível'), findsWidgets);
    expect(
      repo.stored['1']!.watched,
      isFalse,
      reason: 'sortear não marca como assistido',
    );

    await tapVisible(tester, find.text('Marcar como assistido'));
    await tester.pumpAndSettle();
    expect(repo.stored['1']!.watched, isTrue);
    expect(repo.stored['1']!.watchCount, 1);
    expect(find.text('Assisti novamente'), findsOneWidget);

    await tester.tap(navItem('Início'));
    await tester.pumpAndSettle();
    final watchedCard = find.bySemanticsLabel('Já assisti: 2 filmes');
    expect(watchedCard, findsOneWidget);
  });

  testWidgets('sem candidatos mostra mensagem e permite incluir assistidos', (
    tester,
  ) async {
    await startApp(
      tester,
      movies: [movie('1', title: 'Já Visto', watched: true)],
    );

    await drawAndWait(tester);
    expect(find.text('Você já assistiu a tudo!'), findsOneWidget);

    await tapVisible(tester, find.text('Incluir já assistidos'));
    await tester.pumpAndSettle();
    await drawAndWait(tester);
    expect(find.text('HOJE É DIA DE…'), findsOneWidget);
    expect(find.text('Já Visto'), findsWidgets);
  });

  testWidgets('filtros sem resultado oferecem limpar filtros', (tester) async {
    await startApp(
      tester,
      movies: [
        movie(
          '1',
          title: 'Comédia BR',
          genres: [Genre.comedy],
          countries: ['BR'],
        ),
      ],
    );
    await tester.tap(navItem('Sortear'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Terror'));
    await tester.pumpAndSettle();
    expect(find.text('Aplicar · 0 filmes'), findsOneWidget);
    await tester.tap(find.text('Aplicar · 0 filmes'));
    await tester.pumpAndSettle();
    expect(find.text('0 filmes no páreo'), findsOneWidget);

    await drawAndWait(tester);
    expect(find.text('Nenhum filme combina com esses filtros'), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Limpar filtros'),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 filme no páreo'), findsOneWidget);
  });

  testWidgets('detalhes: avaliar, assistir de novo e excluir com confirmação', (
    tester,
  ) async {
    await startApp(
      tester,
      movies: [movie('1', title: 'Aquarius', watched: true)],
    );
    await tapVisible(tester, find.text('Aquarius').first);
    await tester.pumpAndSettle();
    expect(find.text('Assistido 1 vez'), findsOneWidget);

    await tapVisible(tester, find.bySemanticsLabel('4 estrelas'));
    await tester.pumpAndSettle();
    expect(repo.stored['1']!.rating, 4);

    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Assisti novamente'),
    );
    await tester.pumpAndSettle();
    expect(repo.stored['1']!.watchCount, 2);
    expect(find.text('Assistido 2 vezes'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir filme?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(repo.stored, isEmpty);
    expect(find.text('Sua biblioteca está vazia'), findsOneWidget);
  });

  testWidgets('layout largo usa barra lateral', (tester) async {
    await startApp(tester, size: const Size(1280, 800), movies: [movie('1')]);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
