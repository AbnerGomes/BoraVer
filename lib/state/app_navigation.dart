import 'package:flutter/foundation.dart';

import '../domain/services/movie_query.dart';

enum AppSection { home, library, draw, settings }

/// Seção atual da navegação principal, para que qualquer tela possa levar a
/// outra (ex.: o resumo da tela inicial abre a lista "Já assisti").
class AppNavigation extends ChangeNotifier {
  AppSection _section = AppSection.home;
  WatchStatusView _librarySegment = WatchStatusView.toWatch;
  int _drawRequest = 0;

  AppSection get section => _section;
  WatchStatusView get librarySegment => _librarySegment;

  /// Incrementado a cada pedido de sorteio vindo de outra tela; a tela de
  /// sorteio observa a mudança e sorteia automaticamente.
  int get drawRequest => _drawRequest;

  void go(AppSection section) {
    if (section == _section) return;
    _section = section;
    notifyListeners();
  }

  void openLibrary(WatchStatusView segment) {
    _section = AppSection.library;
    _librarySegment = segment;
    notifyListeners();
  }

  set librarySegment(WatchStatusView segment) {
    if (segment == _librarySegment) return;
    _librarySegment = segment;
    notifyListeners();
  }

  void startDraw() {
    _section = AppSection.draw;
    _drawRequest++;
    notifyListeners();
  }
}
