import 'dart:convert';

import '../domain/models/movie.dart';

/// Formato do arquivo de backup (JSON), compartilhado entre Web e Android.
class BackupCodec {
  static const format = 'boraver-backup';
  static const version = 1;

  static String encode(List<Movie> movies, {DateTime? exportedAt}) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'movies': [for (final m in movies) m.toJson()],
    });
  }

  /// Lê um backup. Lança [FormatException] com mensagem amigável se o
  /// arquivo não for um backup do BoraVer.
  static BackupContents decode(String source) {
    final Object? data;
    try {
      data = jsonDecode(source);
    } on FormatException {
      throw const FormatException('O arquivo não é um JSON válido.');
    }
    if (data is! Map<String, dynamic> || data['format'] != format) {
      throw const FormatException('Este arquivo não é um backup do BoraVer.');
    }
    final fileVersion = data['version'];
    if (fileVersion is! int || fileVersion > version) {
      throw const FormatException(
        'Backup criado por uma versão mais nova do BoraVer.',
      );
    }
    final rawMovies = data['movies'];
    if (rawMovies is! List) {
      throw const FormatException('O backup não contém a lista de filmes.');
    }
    final movies = <Movie>[];
    var skipped = 0;
    for (final raw in rawMovies) {
      try {
        movies.add(Movie.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        skipped++;
      }
    }
    return BackupContents(movies, skipped);
  }
}

class BackupContents {
  const BackupContents(this.movies, this.skipped);

  final List<Movie> movies;

  /// Registros inválidos que não puderam ser lidos.
  final int skipped;
}
