import 'package:flutter/foundation.dart';

import '../domain/models/movie.dart';
import '../domain/models/movie_filter.dart';
import '../domain/services/movie_draw.dart';

/// Filtros e resultado do sorteio. O resultado é guardado pelo id para que a
/// tela reflita alterações feitas no filme (ex.: marcar como assistido).
class DrawController extends ChangeNotifier {
  DrawController({MovieDraw? draw}) : _draw = draw ?? MovieDraw();

  final MovieDraw _draw;

  MovieFilter _filter = MovieFilter.empty;
  bool _includeWatched = false;
  String? _resultId;

  MovieFilter get filter => _filter;
  bool get includeWatched => _includeWatched;
  String? get resultId => _resultId;

  set filter(MovieFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  set includeWatched(bool value) {
    if (value == _includeWatched) return;
    _includeWatched = value;
    notifyListeners();
  }

  void clearFilters() => filter = MovieFilter.empty;

  List<Movie> candidates(Iterable<Movie> movies) => _draw.candidates(
    movies,
    filter: _filter,
    includeWatched: _includeWatched,
  );

  /// Sorteia entre os candidatos atuais. Retorna `null` se não houver nenhum.
  Movie? draw(Iterable<Movie> movies) {
    final picked = _draw.pick(candidates(movies), avoidId: _resultId);
    _resultId = picked?.id;
    notifyListeners();
    return picked;
  }

  void clearResult() {
    if (_resultId == null) return;
    _resultId = null;
    notifyListeners();
  }
}
