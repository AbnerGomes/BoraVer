import 'package:boraver/domain/models/country.dart';
import 'package:boraver/domain/models/genre.dart';
import 'package:boraver/domain/models/movie.dart';
import 'package:boraver/domain/services/duplicate_checker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  group('Movie', () {
    test('JSON ida e volta preserva todos os campos', () {
      final original = Movie(
        id: 'x1',
        title: 'Central do Brasil',
        originalTitle: 'Central Station',
        year: 1998,
        countries: ['BR', 'FR'],
        genres: [Genre.drama],
        synopsis: 'Dora escreve cartas.',
        posterUrl: 'https://exemplo.com/p.jpg',
        watched: true,
        rating: 5,
        review: 'Lindo.\nChorei.',
        watchSessions: [DateTime(2024, 5, 1), DateTime(2020, 1, 1)],
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2024, 5, 1),
        tmdbId: 666,
      );
      final copy = Movie.fromJson(original.toJson());
      expect(copy.toJson(), original.toJson());
      // Sessões ficam em ordem cronológica e o contador vem do histórico.
      expect(copy.watchSessions.first, DateTime(2020, 1, 1));
      expect(copy.watchCount, 2);
      expect(copy.lastWatchedAt, DateTime(2024, 5, 1));
    });

    test('fromJson rejeita registro sem título e ignora campos inválidos', () {
      expect(() => Movie.fromJson({'id': 'a'}), throwsFormatException);
      final m = Movie.fromJson({
        'id': 'a',
        'title': 'Ok',
        'rating': 9,
        'genres': ['comedia', 'inexistente'],
        'countries': ['br', 'BRA'],
        'watchSessions': ['2024-01-01T00:00:00.000', 'lixo'],
      });
      expect(m.rating, isNull);
      expect(m.genres, [Genre.comedy]);
      expect(m.countries, ['BR']);
      expect(m.watchCount, 1);
    });

    test('copyWith permite limpar campos opcionais', () {
      final m = movie('1', rating: 4, year: 2000);
      expect(m.copyWith(rating: null).rating, isNull);
      expect(m.copyWith(title: 'Outro').rating, 4);
      expect(m.copyWith(year: null).year, isNull);
    });
  });

  group('Country', () {
    test('bandeira e nome padronizado', () {
      expect(Country.flagFor('BR'), '🇧🇷');
      expect(Country.nameFor('br'), 'Brasil');
      expect(Country.nameFor('US'), 'Estados Unidos');
      // Código desconhecido: mostra o código, sem inventar nome.
      expect(Country.nameFor('ZZ'), 'ZZ');
      expect(Country.flagFor('SU'), '');
    });

    test('busca ignora acentos', () {
      expect(Country.search('japao').map((c) => c.code), contains('JP'));
      expect(Country.search('méxico').map((c) => c.code), contains('MX'));
    });
  });

  group('findDuplicate', () {
    final existing = [
      movie('1', title: 'O Auto da Compadecida', year: 2000),
      movie('2', title: 'Parasita', originalTitle: 'Gisaengchung', year: 2019),
      movie('3', title: 'Sem Ano'),
      movie('4', title: 'Outro', tmdbId: 99),
    ];

    test('mesmo título (sem acento/maiúscula) e mesmo ano', () {
      expect(
        findDuplicate(existing, title: 'o auto da compadecida', year: 2000)?.id,
        '1',
      );
    });

    test('mesmo título com ano diferente não é duplicata (remake)', () {
      expect(
        findDuplicate(existing, title: 'O Auto da Compadecida', year: 2024),
        isNull,
      );
    });

    test('título original também conta', () {
      expect(
        findDuplicate(existing, title: 'Gisaengchung', year: 2019)?.id,
        '2',
      );
      expect(
        findDuplicate(
          existing,
          title: 'Parasite',
          originalTitle: 'Gisaengchung',
        )?.id,
        '2',
      );
    });

    test('sem ano em um dos lados compara só o título', () {
      expect(findDuplicate(existing, title: 'Sem ano', year: 1990)?.id, '3');
      expect(findDuplicate(existing, title: 'Parasita')?.id, '2');
    });

    test('mesmo id do TMDB e exclusão do próprio filme ao editar', () {
      expect(findDuplicate(existing, title: 'Qualquer', tmdbId: 99)?.id, '4');
      expect(
        findDuplicate(existing, title: 'Parasita', year: 2019, excludeId: '2'),
        isNull,
      );
    });
  });
}
