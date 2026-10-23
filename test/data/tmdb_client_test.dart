import 'dart:convert';

import 'package:boraver/data/tmdb/tmdb_client.dart';
import 'package:boraver/domain/models/genre.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('busca com chave v3 vai como parâmetro e em português', () async {
    late Uri called;
    final client = TmdbClient(
      'chave-v3',
      httpClient: MockClient((req) async {
        called = req.url;
        expect(req.headers.containsKey('Authorization'), isFalse);
        return _json({
          'results': [
            {
              'id': 1,
              'title': 'Cidade de Deus',
              'original_title': 'Cidade de Deus',
              'release_date': '2002-08-30',
              'poster_path': '/p.jpg',
            },
            {'id': 2, 'title': 'Sem data', 'release_date': ''},
          ],
        });
      }),
    );
    final results = await client.search(' cidade ');
    expect(called.path, '/3/search/movie');
    expect(called.queryParameters['api_key'], 'chave-v3');
    expect(called.queryParameters['language'], 'pt-BR');
    expect(called.queryParameters['query'], 'cidade');
    expect(results.first.year, 2002);
    expect(results.first.thumbnailUrl, 'https://image.tmdb.org/t/p/w154/p.jpg');
    expect(results.last.year, isNull);
    expect(results.last.thumbnailUrl, isNull);
  });

  test('token v4 vai no cabeçalho Bearer', () async {
    final client = TmdbClient(
      'eyJhbGciOi.abc.def',
      httpClient: MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer eyJhbGciOi.abc.def');
        expect(req.url.queryParameters.containsKey('api_key'), isFalse);
        return _json({'results': []});
      }),
    );
    expect(await client.search('x'), isEmpty);
  });

  test(
    'detalhes mapeiam gêneros, países e pôster sem inventar dados',
    () async {
      final client = TmdbClient(
        'k',
        httpClient: MockClient((req) async {
          return _json({
            'id': 598,
            'title': 'Cidade de Deus',
            'original_title': 'Cidade de Deus',
            'release_date': '2002-08-30',
            'origin_country': ['BR'],
            'production_countries': [
              {'iso_3166_1': 'BR'},
              {'iso_3166_1': 'FR'},
            ],
            'genres': [
              {'id': 18, 'name': 'Drama'},
              {'id': 80, 'name': 'Crime'},
              {'id': 10770, 'name': 'Cinema TV'},
            ],
            'overview': '',
            'poster_path': null,
          });
        }),
      );
      final d = await client.details(598);
      expect(d.title, 'Cidade de Deus');
      expect(d.originalTitle, isNull, reason: 'igual ao título');
      expect(d.year, 2002);
      expect(d.countries, ['BR']);
      expect(d.genres, [Genre.drama, Genre.crime]);
      expect(d.overview, isNull);
      expect(d.posterUrl, isNull);
    },
  );

  test('em alta usa o endpoint de tendências', () async {
    final client = TmdbClient(
      'k',
      httpClient: MockClient((req) async {
        expect(req.url.path, '/3/trending/movie/week');
        return _json({
          'results': [
            {'id': 5, 'title': 'Em Alta'},
            {'title': 'Sem id é ignorado'},
          ],
        });
      }),
    );
    expect((await client.trending()).map((m) => m.title), ['Em Alta']);
  });

  test('sem sinopse em português usa a do TMDB em inglês', () async {
    final client = TmdbClient(
      'k',
      httpClient: MockClient((req) async {
        final english = req.url.queryParameters['language'] == 'en-US';
        return _json({
          'id': 7,
          'title': english ? 'Title' : 'Título',
          'overview': english ? 'English overview.' : '',
        });
      }),
    );
    final d = await client.details(7);
    expect(d.title, 'Título');
    expect(d.overview, 'English overview.');
  });

  test('usa países de produção quando não há país de origem', () async {
    final client = TmdbClient(
      'k',
      httpClient: MockClient(
        (req) async => _json({
          'id': 1,
          'title': 'T',
          'production_countries': [
            {'iso_3166_1': 'fr'},
          ],
        }),
      ),
    );
    expect((await client.details(1)).countries, ['FR']);
  });

  test('erros viram mensagens claras', () async {
    final unauthorized = TmdbClient(
      'k',
      httpClient: MockClient((_) async => _json({'status_message': 'x'}, 401)),
    );
    await expectLater(
      unauthorized.search('a'),
      throwsA(
        isA<TmdbException>().having(
          (e) => e.message,
          'message',
          contains('inválida'),
        ),
      ),
    );
    final offline = TmdbClient(
      'k',
      httpClient: MockClient(
        (_) async => throw http.ClientException('sem rede'),
      ),
    );
    await expectLater(
      offline.trending(),
      throwsA(
        isA<TmdbException>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        ),
      ),
    );
  });
}
