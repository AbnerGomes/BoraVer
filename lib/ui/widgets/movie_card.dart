import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/movie.dart';
import '../movie_actions.dart';
import 'movie_poster.dart';
import 'movie_tags.dart';
import 'star_rating.dart';

/// Cartão de filme para listas, com menu de ações rápidas.
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = compactMeta(
      year: movie.year,
      countries: movie.countries,
      genres: movie.genres,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => MovieActions.openDetails(context, movie.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MoviePoster(url: movie.posterUrl, title: movie.title, width: 64),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Semantics(
                        label: [
                          if (movie.year != null) '${movie.year}',
                          if (movie.countries.isNotEmpty)
                            countriesLabel(movie.countries),
                          if (movie.genres.isNotEmpty)
                            movie.genres.map((g) => g.label).join(', '),
                        ].join(', '),
                        excludeSemantics: true,
                        child: Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s),
                    Wrap(
                      spacing: AppSpacing.m,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (movie.isRated)
                          StarRating(value: movie.rating, size: 16),
                        if (movie.watchCount > 0)
                          _Pill(
                            icon: Icons.replay,
                            text: movie.watchCount == 1
                                ? 'Visto 1 vez'
                                : 'Visto ${movie.watchCount} vezes',
                          ),
                        if (movie.hasReview)
                          const _Pill(icon: Icons.notes, text: 'Resenha'),
                      ],
                    ),
                  ],
                ),
              ),
              _MovieMenu(movie: movie),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.sageDark),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: AppColors.sageDark),
        ),
      ],
    );
  }
}

enum _MenuAction { watched, again, unwatched, edit, delete }

class _MovieMenu extends StatelessWidget {
  const _MovieMenu({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<_MenuAction> item(
      _MenuAction value,
      IconData icon,
      String text,
    ) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.m),
          Text(text),
        ],
      ),
    );

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Ações de ${movie.title}',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => switch (action) {
        _MenuAction.watched => MovieActions.markWatched(context, movie),
        _MenuAction.again => MovieActions.watchAgain(context, movie),
        _MenuAction.unwatched => MovieActions.markUnwatched(context, movie),
        _MenuAction.edit => MovieActions.openForm(context, movie: movie),
        _MenuAction.delete => MovieActions.delete(context, movie),
      },
      itemBuilder: (_) => [
        if (!movie.watched)
          item(
            _MenuAction.watched,
            Icons.check_circle_outline,
            'Marcar como assistido',
          )
        else ...[
          item(_MenuAction.again, Icons.replay, 'Assisti novamente'),
          item(
            _MenuAction.unwatched,
            Icons.bookmark_add_outlined,
            'Mover para Quero assistir',
          ),
        ],
        item(_MenuAction.edit, Icons.edit_outlined, 'Editar'),
        item(_MenuAction.delete, Icons.delete_outline, 'Excluir'),
      ],
    );
  }
}
