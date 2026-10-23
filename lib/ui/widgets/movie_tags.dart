import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/country.dart';
import '../../domain/models/genre.dart';

IconData genreIcon(Genre genre) => switch (genre) {
  Genre.action => Icons.local_fire_department_outlined,
  Genre.adventure => Icons.explore_outlined,
  Genre.animation => Icons.animation,
  Genre.comedy => Icons.sentiment_very_satisfied_outlined,
  Genre.crime => Icons.local_police_outlined,
  Genre.documentary => Icons.videocam_outlined,
  Genre.drama => Icons.theater_comedy_outlined,
  Genre.family => Icons.family_restroom,
  Genre.fantasy => Icons.auto_awesome_outlined,
  Genre.scienceFiction => Icons.rocket_launch_outlined,
  Genre.history => Icons.account_balance_outlined,
  Genre.horror => Icons.dark_mode_outlined,
  Genre.musical => Icons.music_note_outlined,
  Genre.mystery => Icons.search,
  Genre.romance => Icons.favorite_border,
  Genre.thriller => Icons.visibility_outlined,
  Genre.war => Icons.military_tech_outlined,
  Genre.western => Icons.landscape_outlined,
};

/// Etiqueta de gênero (somente leitura).
class GenreTag extends StatelessWidget {
  const GenreTag(this.genre, {super.key});

  final Genre genre;

  @override
  Widget build(BuildContext context) {
    return _Tag(
      leading: Icon(
        genreIcon(genre),
        size: 15,
        color: AppColors.terracottaDark,
      ),
      label: genre.label,
    );
  }
}

/// Bandeira + nome do país. A bandeira é apenas apoio visual: o nome
/// sempre aparece.
class CountryTag extends StatelessWidget {
  const CountryTag(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final flag = Country.flagFor(code);
    return _Tag(
      leading: flag.isEmpty
          ? const Icon(Icons.public, size: 15, color: AppColors.sageDark)
          : ExcludeSemantics(
              child: Text(flag, style: const TextStyle(fontSize: 14)),
            ),
      label: Country.nameFor(code),
    );
  }
}

class YearTag extends StatelessWidget {
  const YearTag(this.year, {super.key});

  final int year;

  @override
  Widget build(BuildContext context) => _Tag(
    leading: const Icon(
      Icons.calendar_today_outlined,
      size: 14,
      color: AppColors.goldDark,
    ),
    label: '$year',
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha compacta "1999 · 🇧🇷 🇫🇷 · Drama, Comédia" para cartões.
String compactMeta({
  int? year,
  List<String> countries = const [],
  List<Genre> genres = const [],
}) {
  final parts = <String>[
    if (year != null) '$year',
    if (countries.isNotEmpty)
      countries
          .map(
            (c) => Country.flagFor(c).isEmpty
                ? Country.nameFor(c)
                : Country.flagFor(c),
          )
          .join(' '),
    if (genres.isNotEmpty) genres.map((g) => g.label).join(', '),
  ];
  return parts.join('  ·  ');
}

/// Descrição acessível dos países (nomes, sem emoji).
String countriesLabel(List<String> countries) =>
    countries.map(Country.nameFor).join(', ');
