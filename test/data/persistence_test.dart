import 'dart:io';

import 'package:boraver/data/backup_codec.dart';
import 'package:boraver/data/hive_storage.dart';
import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/state/library_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../helpers/fakes.dart';

/// Usa o Hive de verdade (em uma pasta temporária) e fecha/reabre o banco
/// para simular o app sendo encerrado e aberto de novo.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('boraver_test_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<LibraryController> reopen() async {
    await Hive.close();
    Hive.init(dir.path);
    final storage = await HiveStorage.open();
    final library = LibraryController(storage.movies);
    await library.load();
    return library;
  }

  test(
    'filmes, nota, resenha e sessões sobrevivem a reiniciar o app',
    () async {
      var storage = await HiveStorage.open();
      var library = LibraryController(storage.movies);
      await library.load();

      final m = await library.add(
        const MovieInput(
          title: 'Que Horas Ela Volta?',
          year: 2015,
          countries: ['BR'],
          genres: [Genre.drama, Genre.comedy],
        ),
      );
      await library.markWatched(m.id);
      await library.watchAgain(m.id);
      await library.setRating(m.id, 5);
      await library.setReview(m.id, 'Regina Casé perfeita.');
      final deleted = await library.add(const MovieInput(title: 'Apagar'));
      await library.delete(deleted.id);

      library = await reopen();
      expect(library.totalCount, 1);
      final saved = library.byId(m.id)!;
      expect(saved.title, 'Que Horas Ela Volta?');
      expect(saved.year, 2015);
      expect(saved.countries, ['BR']);
      expect(saved.genres, [Genre.drama, Genre.comedy]);
      expect(saved.watched, isTrue);
      expect(saved.watchCount, 2);
      expect(saved.rating, 5);
      expect(saved.review, 'Regina Casé perfeita.');
    },
  );

  test('registro corrompido é ignorado sem impedir a abertura', () async {
    final box = await Hive.openBox<String>(HiveStorage.moviesBox);
    await box.put('ruim', '{não é json');
    await box.put(
      'bom',
      '{"id":"bom","title":"Ok","createdAt":"2026-01-01T00:00:00.000"}',
    );
    final library = await reopen();
    expect(library.movies.map((m) => m.id), ['bom']);
    expect(library.loadError, isNull);
  });

  group('BackupCodec', () {
    test('exporta e importa a biblioteca', () {
      final movies = [
        movie('1', title: 'A', rating: 3, watched: true),
        movie('2', title: 'B', genres: [Genre.horror], countries: ['JP']),
      ];
      final json = BackupCodec.encode(movies);
      final back = BackupCodec.decode(json);
      expect(back.skipped, 0);
      expect(back.movies.map((m) => m.toJson()), movies.map((m) => m.toJson()));
    });

    test('rejeita arquivos que não são backup e conta registros inválidos', () {
      expect(() => BackupCodec.decode('oi'), throwsFormatException);
      expect(
        () => BackupCodec.decode('{"format":"outro"}'),
        throwsFormatException,
      );
      expect(
        () => BackupCodec.decode(
          '{"format":"boraver-backup","version":99,"movies":[]}',
        ),
        throwsFormatException,
      );
      final r = BackupCodec.decode(
        '{"format":"boraver-backup","version":1,"movies":[{"id":"x","title":"Ok"},{"id":"y"},3]}',
      );
      expect(r.movies.single.id, 'x');
      expect(r.skipped, 2);
    });
  });
}
