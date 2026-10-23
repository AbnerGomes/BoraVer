import '../../core/utils/text_normalize.dart';
import '../models/movie.dart';

/// Procura um filme já cadastrado que pareça ser o mesmo.
///
/// Considera duplicado quando o id do TMDB coincide, ou quando o título
/// (ou título original) é igual, ignorando acentos e maiúsculas, e o ano
/// também coincide. Se algum dos dois não tiver ano, basta o título.
Movie? findDuplicate(
  Iterable<Movie> movies, {
  required String title,
  String? originalTitle,
  int? year,
  int? tmdbId,
  String? excludeId,
}) {
  final titles = {
    normalizeText(title),
    if (originalTitle != null && originalTitle.trim().isNotEmpty)
      normalizeText(originalTitle),
  }..remove('');

  for (final movie in movies) {
    if (movie.id == excludeId) continue;
    if (tmdbId != null && movie.tmdbId == tmdbId) return movie;

    final existing = {
      normalizeText(movie.title),
      if (movie.originalTitle != null) normalizeText(movie.originalTitle!),
    };
    final sameTitle = titles.any(existing.contains);
    final sameYear = year == null || movie.year == null || movie.year == year;
    if (sameTitle && sameYear) return movie;
  }
  return null;
}
