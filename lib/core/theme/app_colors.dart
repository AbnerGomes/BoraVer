import 'package:flutter/material.dart';

/// Paleta do BoraVer. Os tons "escuros" das cores de destaque existem para
/// garantir contraste mínimo (WCAG AA) quando usados em texto ou botões.
abstract final class AppColors {
  static const beige = Color(0xFFF2E9DC);
  static const beigeDeep = Color(0xFFE8DCC9);
  static const cream = Color(0xFFFAF7F1);
  static const espresso = Color(0xFF40352E);
  static const terracotta = Color(0xFFC8795A);
  static const terracottaDark = Color(0xFFA2553A);
  static const sage = Color(0xFF879780);
  static const sageDark = Color(0xFF56664F);
  static const gold = Color(0xFFD6AE61);
  static const goldDark = Color(0xFF9A7426);
  static const warmGray = Color(0xFF8A8178);
  static const warmGrayText = Color(0xFF6B625A);
  static const line = Color(0xFFDDD0BD);
  static const error = Color(0xFFB3402E);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Largura máxima do conteúdo em telas grandes.
  static const maxContentWidth = 960.0;
}

abstract final class AppRadius {
  static const s = 10.0;
  static const m = 16.0;
  static const l = 24.0;
}
