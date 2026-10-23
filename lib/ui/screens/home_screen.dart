import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/movie.dart';
import '../../domain/services/movie_query.dart';
import '../../state/app_navigation.dart';
import '../../state/draw_controller.dart';
import '../../state/library_controller.dart';
import '../movie_actions.dart';
import '../shell/app_shell.dart';
import '../widgets/cinema_decor.dart';
import '../widgets/common.dart';
import '../widgets/movie_poster.dart';
import 'draw_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final theme = Theme.of(context);

    if (!library.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: pagePadding(
            context,
          ).copyWith(top: AppSpacing.l, bottom: AppSpacing.xxl),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Em telas largas o logotipo completo já está na barra lateral.
                      if (MediaQuery.sizeOf(context).width <
                          AppShell.extendedRailBreakpoint)
                        const BoraVerLogo(size: 30),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'Adicionar filme',
                        onPressed: () => MovieActions.openAdd(context),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (library.loadError != null) ...[
                    const SizedBox(height: AppSpacing.l),
                    _ErrorBanner(message: library.loadError!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    greetingFor(DateTime.now()),
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    'Pipoca pronta? Deixa que a gente escolhe o filme.',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _DrawHero(),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bookmark_outline,
                          color: AppColors.terracottaDark,
                          label: 'Quero assistir',
                          count: library.toWatchCount,
                          onTap: () => context
                              .read<AppNavigation>()
                              .openLibrary(WatchStatusView.toWatch),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          color: AppColors.sageDark,
                          label: 'Já assisti',
                          count: library.watchedCount,
                          onTap: () => context
                              .read<AppNavigation>()
                              .openLibrary(WatchStatusView.watched),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionTitle(
                    'Adicionados recentemente',
                    icon: Icons.schedule,
                    trailing: library.totalCount == 0
                        ? null
                        : TextButton(
                            onPressed: () => context
                                .read<AppNavigation>()
                                .openLibrary(WatchStatusView.all),
                            child: const Text('Ver todos'),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (library.totalCount == 0)
                    Card(
                      child: EmptyState(
                        icon: Icons.movie_filter_outlined,
                        title: 'Sua biblioteca está vazia',
                        message:
                            'Adicione os filmes que você quer ver para começar a sortear.',
                        actions: [
                          FilledButton.icon(
                            onPressed: () => MovieActions.openAdd(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar primeiro filme'),
                          ),
                        ],
                      ),
                    )
                  else
                    _RecentStrip(movies: library.recentlyAdded()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão-ingresso com a ação principal do app.
class _DrawHero extends StatelessWidget {
  const _DrawHero();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final draw = context.watch<DrawController>();
    final theme = Theme.of(context);
    final candidates = draw.candidates(library.movies).length;
    final empty = library.totalCount == 0;

    final subtitle = empty
        ? 'Adicione alguns filmes e o sorteio fica com a gente.'
        : candidates == 0
        ? 'Nenhum filme combina com o sorteio atual. Ajuste os filtros.'
        : candidates == 1
        ? '1 filme no páreo${draw.includeWatched ? '' : ' na sua lista'}.'
        : '$candidates filmes no páreo${draw.includeWatched ? '' : ' na sua lista'}.';

    return Material(
      color: AppColors.espresso,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DotTexture(color: AppColors.cream.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_activity_outlined,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          'SESSÃO SURPRESA',
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: AppColors.gold,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Bora ver o quê?',
                      style: theme.textTheme.headlineLarge!.copyWith(
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: AppColors.cream.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              TicketDivider(lineColor: AppColors.cream.withValues(alpha: 0.25)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.m,
                  AppSpacing.xl,
                  AppSpacing.l,
                ),
                child: Wrap(
                  spacing: AppSpacing.m,
                  runSpacing: AppSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.espresso,
                        minimumSize: const Size(160, 52),
                      ),
                      onPressed: empty
                          ? () => MovieActions.openAdd(context)
                          : () => context.read<AppNavigation>().startDraw(),
                      icon: Icon(empty ? Icons.add : Icons.shuffle),
                      label: Text(empty ? 'Adicionar filme' : 'Bora ver?'),
                    ),
                    if (!empty)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.cream,
                        ),
                        onPressed: () => openDrawFilters(context),
                        icon: const Icon(Icons.tune),
                        label: Text(
                          draw.filter.isEmpty
                              ? 'Filtros'
                              : 'Filtros (${draw.filter.activeCount})',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '$label: $count ${count == 1 ? 'filme' : 'filmes'}',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: AppSpacing.s),
                Text(
                  '$count',
                  style: theme.textTheme.headlineMedium!.copyWith(
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(label, style: theme.textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentStrip extends StatelessWidget {
  const _RecentStrip({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    const posterWidth = 108.0;
    return SizedBox(
      height: posterWidth * 1.5 + 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.m),
        itemBuilder: (context, i) {
          final movie = movies[i];
          return SizedBox(
            width: posterWidth,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.s),
              onTap: () => MovieActions.openDetails(context, movie.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoviePoster(
                    url: movie.posterUrl,
                    title: movie.title,
                    width: posterWidth,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(message)),
            TextButton(
              onPressed: () => context.read<LibraryController>().load(),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
