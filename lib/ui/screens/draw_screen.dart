import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/movie.dart';
import '../../domain/services/movie_query.dart';
import '../../state/app_navigation.dart';
import '../../state/draw_controller.dart';
import '../../state/library_controller.dart';
import '../movie_actions.dart';
import '../widgets/cinema_decor.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_tags.dart';
import '../widgets/star_rating.dart';

/// Abre os filtros do sorteio (usado aqui e na tela inicial).
Future<void> openDrawFilters(BuildContext context) async {
  final draw = context.read<DrawController>();
  final library = context.read<LibraryController>();
  final movies = library.movies;
  final result = await showFilterSheet(
    context,
    initial: draw.filter,
    libraryCountries: {for (final m in movies) ...m.countries},
    countFor: (f) => movies
        .where((m) => (draw.includeWatched || !m.watched) && f.matches(m))
        .length,
  );
  if (result != null) draw.filter = result;
}

enum _Phase { idle, rolling, result, noCandidates }

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  /// Duração da animação de "embaralhar" antes de revelar o filme.
  static const rollDuration = Duration(milliseconds: 1100);

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  _Phase _phase = _Phase.idle;
  int _handledRequest = 0;
  Timer? _ticker;
  Timer? _stopper;
  List<String> _rollingTitles = const [];
  int _rollingIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pedidos de sorteio vindos de outras telas (ex.: botão da tela inicial).
    final request = context.watch<AppNavigation>().drawRequest;
    if (request != _handledRequest) {
      _handledRequest = request;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _draw();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopper?.cancel();
    super.dispose();
  }

  void _draw() {
    if (_phase == _Phase.rolling) return;
    final library = context.read<LibraryController>();
    final draw = context.read<DrawController>();
    final candidates = draw.candidates(library.movies);
    final picked = draw.draw(library.movies);
    if (picked == null) {
      setState(() => _phase = _Phase.noCandidates);
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion || candidates.length == 1) {
      setState(() => _phase = _Phase.result);
      return;
    }

    // Animação curta: títulos dos candidatos passando, como uma roleta.
    final titles = candidates.map((m) => m.title).toList()..shuffle(Random());
    setState(() {
      _phase = _Phase.rolling;
      _rollingTitles = titles;
      _rollingIndex = 0;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 85), (_) {
      if (mounted) setState(() => _rollingIndex++);
    });
    _stopper = Timer(DrawScreen.rollDuration, () {
      _ticker?.cancel();
      if (mounted) setState(() => _phase = _Phase.result);
    });
  }

  void _onCriteriaChanged() {
    if (_phase == _Phase.noCandidates) setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final draw = context.watch<DrawController>();
    final theme = Theme.of(context);
    final candidates = draw.candidates(library.movies).length;
    final result = draw.resultId == null ? null : library.byId(draw.resultId!);

    // Resultado excluído enquanto exibido: volta ao estado inicial.
    var phase = _phase;
    if (phase == _Phase.result && result == null) phase = _Phase.idle;

    return Scaffold(
      appBar: AppBar(title: const Text('Sorteio')),
      body: ListView(
        padding: pagePadding(context).copyWith(bottom: AppSpacing.xxl),
        children: [
          ContentWidth(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Bora ver o quê?', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'O sorteio escolhe ao acaso entre os filmes que atendem a '
                  'todos os filtros. Nada é marcado como assistido sem você pedir.',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await openDrawFilters(context);
                                _onCriteriaChanged();
                              },
                              icon: const Icon(Icons.tune),
                              label: Text(
                                draw.filter.isEmpty
                                    ? 'Filtros'
                                    : 'Filtros (${draw.filter.activeCount})',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Text(
                                candidates == 1
                                    ? '1 filme no páreo'
                                    : '$candidates filmes no páreo',
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                        if (!draw.filter.isEmpty) ...[
                          const SizedBox(height: AppSpacing.m),
                          ActiveFiltersBar(
                            filter: draw.filter,
                            onChanged: (f) {
                              draw.filter = f;
                              _onCriteriaChanged();
                            },
                          ),
                        ],
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Incluir filmes já assistidos'),
                          subtitle: const Text(
                            'Sorteia entre toda a biblioteca, até os que você já viu.',
                          ),
                          value: draw.includeWatched,
                          onChanged: (v) {
                            draw.includeWatched = v;
                            _onCriteriaChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: phase == _Phase.rolling ? null : _draw,
                  icon: const Icon(Icons.shuffle),
                  label: Text(
                    phase == _Phase.result ? 'Sortear outro' : 'Bora ver?',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (phase) {
                    _Phase.idle => const _IdleHint(key: ValueKey('idle')),
                    _Phase.rolling => _RollingTicket(
                      key: const ValueKey('rolling'),
                      title:
                          _rollingTitles[_rollingIndex % _rollingTitles.length],
                    ),
                    _Phase.result => _ResultTicket(
                      key: ValueKey('result-${result!.id}'),
                      movie: result,
                      onDrawAgain: _draw,
                    ),
                    _Phase.noCandidates => _NoCandidates(
                      key: const ValueKey('empty'),
                      onChanged: _onCriteriaChanged,
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: 0.5,
          child: SizedBox.square(
            dimension: 72,
            child: const CustomPaint(
              painter: ClapperPainter(
                body: AppColors.warmGray,
                stripes: AppColors.warmGrayText,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'Toque em "Bora ver?" para sortear.',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RollingTicket extends StatelessWidget {
  const _RollingTicket({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Sorteando…',
      excludeSemantics: true,
      child: Material(
        color: AppColors.espresso,
        shape: const TicketBorder(),
        child: SizedBox(
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shuffle, color: AppColors.gold),
              const SizedBox(height: AppSpacing.m),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall!.copyWith(color: AppColors.cream),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTicket extends StatelessWidget {
  const _ResultTicket({
    super.key,
    required this.movie,
    required this.onDrawAgain,
  });

  final Movie movie;
  final VoidCallback onDrawAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOJE É DIA DE…',
          style: theme.textTheme.labelMedium!.copyWith(
            color: AppColors.goldDark,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(movie.title, style: theme.textTheme.headlineMedium),
        if (movie.originalTitle != null)
          Text(
            movie.originalTitle!,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            if (movie.year != null) YearTag(movie.year!),
            for (final c in movie.countries) CountryTag(c),
            for (final g in movie.genres) GenreTag(g),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StarRating(value: movie.rating, size: 18),
            Text(
              movie.watchCount == 0
                  ? 'Ainda não assistido'
                  : movie.watchCount == 1
                  ? 'Assistido 1 vez'
                  : 'Assistido ${movie.watchCount} vezes',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        if (movie.synopsis != null) ...[
          const SizedBox(height: AppSpacing.m),
          Text(
            movie.synopsis!,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );

    return Semantics(
      liveRegion: true,
      label: 'Filme sorteado: ${movie.title}',
      child: Material(
        color: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.l,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 480;
                  final poster = MoviePoster(
                    url: movie.posterUrl,
                    title: movie.title,
                    width: wide ? 160 : 140,
                    radius: AppRadius.m,
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        poster,
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(child: info),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: poster),
                      const SizedBox(height: AppSpacing.l),
                      info,
                    ],
                  );
                },
              ),
            ),
            const TicketDivider(borderColor: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.m,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  FilledButton.icon(
                    onPressed: onDrawAgain,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Sortear outro'),
                  ),
                  if (!movie.watched)
                    OutlinedButton.icon(
                      onPressed: () => MovieActions.markWatched(context, movie),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar como assistido'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => MovieActions.watchAgain(context, movie),
                      icon: const Icon(Icons.replay),
                      label: const Text('Assisti novamente'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        MovieActions.openDetails(context, movie.id),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Ver detalhes'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.read<AppNavigation>().openLibrary(
                      movie.watched
                          ? WatchStatusView.watched
                          : WatchStatusView.toWatch,
                    ),
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Voltar para a biblioteca'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCandidates extends StatelessWidget {
  const _NoCandidates({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final draw = context.watch<DrawController>();

    final addButton = FilledButton.icon(
      onPressed: () => MovieActions.openAdd(context),
      icon: const Icon(Icons.add),
      label: const Text('Adicionar filme'),
    );
    final includeWatchedButton = OutlinedButton.icon(
      onPressed: () {
        draw.includeWatched = true;
        onChanged();
      },
      icon: const Icon(Icons.history),
      label: const Text('Incluir já assistidos'),
    );

    if (library.totalCount == 0) {
      return Card(
        child: EmptyState(
          icon: Icons.movie_filter_outlined,
          title: 'Sua biblioteca está vazia',
          message: 'Adicione filmes para poder sortear.',
          actions: [addButton],
        ),
      );
    }
    if (draw.filter.isEmpty) {
      return Card(
        child: EmptyState(
          icon: Icons.celebration_outlined,
          title: 'Você já assistiu a tudo!',
          message:
              'Não há filmes em "Quero assistir". Inclua os já '
              'assistidos no sorteio ou adicione novos filmes.',
          actions: [includeWatchedButton, addButton],
        ),
      );
    }
    return Card(
      child: EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Nenhum filme combina com esses filtros',
        message: draw.includeWatched
            ? 'Nenhum filme da biblioteca atende a todos os filtros ao mesmo tempo.'
            : 'Nenhum filme ainda não assistido atende a todos os filtros ao mesmo tempo.',
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await openDrawFilters(context);
              onChanged();
            },
            icon: const Icon(Icons.tune),
            label: const Text('Ajustar filtros'),
          ),
          FilledButton.icon(
            onPressed: () {
              draw.clearFilters();
              onChanged();
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar filtros'),
          ),
          if (!draw.includeWatched) includeWatchedButton,
        ],
      ),
    );
  }
}
