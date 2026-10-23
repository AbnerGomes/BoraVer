import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Avaliação de 1 a 5 estrelas. Com [onChanged], vira editável: tocar na
/// estrela já selecionada remove a avaliação.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final double size;

  static String describe(int? value) =>
      value == null ? 'Sem avaliação' : '$value de 5 estrelas';

  @override
  Widget build(BuildContext context) {
    final current = value ?? 0;
    final editable = onChanged != null;

    Widget star(int i) {
      final selected = i <= current;
      final icon = Icon(
        selected ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: selected ? AppColors.gold : AppColors.warmGray,
      );
      if (!editable) return icon;
      return Semantics(
        button: true,
        selected: i == current,
        label: '$i ${i == 1 ? 'estrela' : 'estrelas'}',
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => onChanged!(i == current ? null : i),
          radius: size * 0.9,
          child: Padding(padding: EdgeInsets.all(size * 0.15), child: icon),
        ),
      );
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 1; i <= 5; i++) star(i)],
    );
    if (editable) {
      return Semantics(label: 'Avaliação: ${describe(value)}', child: row);
    }
    return Semantics(
      label: describe(value),
      excludeSemantics: true,
      child: row,
    );
  }
}
