import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/state/draw_controller.dart';
import 'package:boraver/state/library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryMovieRepository repo;
  late LibraryController library;
  var now = DateTime(2026, 3, 10, 20);

  setUp(() async {
    now = DateTime(2026, 3, 10, 20);
    repo = InMemoryMovieRepository();
    library = LibraryController(repo, clock: () => now);
    await library.load();
  });

  test('filme adicionado vai para "Quero assistir" e é gravado', () async {
    final m = await library.add(
      const MovieInput(
        title: '  Bacurau ',
        year: 2019,
        countries: ['BR'],
        genres: [Genre.thriller],
        originalTitle: '',
      ),
    );
    expect(m.title, 'Bacurau');
    expect(m.originalTitle, isNull);
    expect(m.watched, isFalse);
    expect(m.watchCount, 0);
    expect(m.createdAt, now);
    expect(library.toWatchCount, 1);
    expect(library.watchedCount, 0);
    expect(repo.stored[m.id]!.title, 'Bacurau');
  });

  test('cadastrar como "já assisti" registra a primeira sessão', () async {
    final m = await library.add(
      const MovieInput(title: 'Tropa de Elite', watched: true),
    );
    expect(m.watched, isTrue);
    expect(m.watchSessions, [now]);
  });

  test('ciclo de visualizações e estados', () async {
    final id = (await library.add(const MovieInput(title: 'Aquarius'))).id;

    // Primeira vez: move de lista e registra 1 sessão.
    await library.markWatched(id);
    expect(library.byId(id)!.watched, isTrue);
    expect(library.byId(id)!.watchCount, 1);
    expect(library.watchedCount, 1);

    // Marcar de novo não duplica.
    await library.markWatched(id);
    expect(library.byId(id)!.watchCount, 1);

    // "Assisti novamente" incrementa.
    now = now.add(const Duration(days: 30));
    await library.watchAgain(id);
    expect(library.byId(id)!.watchCount, 2);
    expect(library.byId(id)!.lastWatchedAt, now);

    // Nota e resenha não mexem no contador.
    await library.setRating(id, 4);
    await library.setReview(id, 'Sonia Braga brilha.');
    expect(library.byId(id)!.watchCount, 2);

    // Voltar para "Quero assistir" preserva histórico, nota e resenha.
    await library.markUnwatched(id);
    final back = library.byId(id)!;
    expect(back.watched, isFalse);
    expect(back.watchCount, 2);
    expect(back.rating, 4);
    expect(back.review, 'Sonia Braga brilha.');
    expect(library.toWatchCount, 1);

    // Marcar como assistido de novo restaura o estado sem inflar o contador.
    await library.markWatched(id);
    expect(library.byId(id)!.watchCount, 2);

    // Remover uma sessão do histórico.
    await library.removeSession(id, library.byId(id)!.watchSessions.first);
    expect(library.byId(id)!.watchCount, 1);
    expect(repo.stored[id]!.watchCount, 1);
  });

  test('sessão em data passada', () async {
    final id = (await library.add(const MovieInput(title: 'X'))).id;
    await library.watchAgain(id, at: DateTime(2010, 6, 1, 12));
    expect(library.byId(id)!.watchSessions, [DateTime(2010, 6, 1, 12)]);
    expect(library.byId(id)!.watched, isTrue);
  });

  test('nota pode ser alterada e removida; resenha vazia vira nula', () async {
    final id = (await library.add(const MovieInput(title: 'Y'))).id;
    await library.setRating(id, 2);
    await library.setRating(id, 5);
    expect(library.byId(id)!.rating, 5);
    await library.setRating(id, null);
    expect(library.byId(id)!.isRated, isFalse);
    await library.setReview(id, '   ');
    expect(library.byId(id)!.review, isNull);
  });

  test('editar atualiza campos e a data de atualização', () async {
    final id = (await library.add(
      const MovieInput(title: 'Errado', year: 1990),
    )).id;
    now = now.add(const Duration(hours: 1));
    await library.update(
      id,
      const MovieInput(title: 'Certo', year: 1991, genres: [Genre.war]),
    );
    final m = library.byId(id)!;
    expect(m.title, 'Certo');
    expect(m.year, 1991);
    expect(m.genres, [Genre.war]);
    expect(m.updatedAt, now);
    expect(m.createdAt, isNot(now));
  });

  test('excluir remove da memória e do armazenamento', () async {
    final id = (await library.add(const MovieInput(title: 'Some'))).id;
    await library.delete(id);
    expect(library.byId(id), isNull);
    expect(repo.stored, isEmpty);
  });

  test('falha ao gravar não altera o estado em memória', () async {
    final id = (await library.add(const MovieInput(title: 'Z'))).id;
    repo.failWrites = true;
    await expectLater(library.markWatched(id), throwsException);
    expect(library.byId(id)!.watched, isFalse);
    await expectLater(library.delete(id), throwsException);
    expect(library.byId(id), isNotNull);
  });

  test('desfazer restaura a versão anterior', () async {
    final before = await library.add(const MovieInput(title: 'W'));
    await library.markWatched(before.id);
    await library.restore(before);
    expect(library.byId(before.id)!.watched, isFalse);
    expect(library.byId(before.id)!.watchCount, 0);
  });

  test('importação mescla sem duplicar', () async {
    final local = await library.add(
      const MovieInput(title: 'Local', year: 2000),
    );
    final newer = local.copyWith(
      title: 'Local editado',
      updatedAt: now.add(const Duration(days: 1)),
    );
    final older = movie('old', title: 'Outro');
    await library.importMovies([older]);
    final result = await library.importMovies([
      newer,
      movie('dup', title: 'local editado', year: 2000), // mesmo filme, outro id
      older, // já importado, sem mudanças
      movie('novo', title: 'Novo'),
    ], invalid: 2);
    expect(result.added, 1);
    expect(result.updated, 1);
    expect(result.unchanged, 1);
    expect(result.duplicates, 1);
    expect(result.invalid, 2);
    expect(library.totalCount, 3);
    expect(library.byId(local.id)!.title, 'Local editado');
    expect(repo.stored.length, 3);
  });

  test('sorteio usa a biblioteca e reflete marcação de assistido', () async {
    final a = await library.add(
      const MovieInput(title: 'A', genres: [Genre.comedy]),
    );
    await library.add(
      const MovieInput(title: 'B', genres: [Genre.drama], watched: true),
    );
    final draw = DrawController();

    expect(draw.draw(library.movies)!.id, a.id);

    await library.markWatched(a.id);
    expect(draw.draw(library.movies), isNull);
    expect(draw.resultId, isNull);

    draw.includeWatched = true;
    expect(draw.candidates(library.movies).length, 2);
    expect(draw.draw(library.movies), isNotNull);
    // Sortear não altera o filme nem o contador.
    expect(library.byId(a.id)!.watchCount, 1);
  });
}
