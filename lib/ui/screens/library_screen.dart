import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/movie.dart';
import '../../domain/models/movie_filter.dart';
import '../../domain/services/movie_query.dart';
import '../../state/app_navigation.dart';
import '../../state/draw_controller.dart';
import '../../state/library_controller.dart';
import '../movie_actions.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/movie_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  MovieFilter _filter = MovieFilter.empty;
  MovieSort _sort = MovieSort.recentlyAdded;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<Movie> movies, WatchStatusView segment) async {
    final result = await showFilterSheet(
      context,
      initial: _filter,
      libraryCountries: {for (final m in movies) ...m.countries},
      countFor: (f) => queryMovies(
        movies,
        status: segment,
        search: _searchCtrl.text,
        filter: f,
      ).length,
    );
    if (result != null) setState(() => _filter = result);
  }

  /// Leva os filtros atuais para o sorteio e sorteia.
  void _drawFromHere(WatchStatusView segment) {
    final draw = context.read<DrawController>();
    if (!_filter.isEmpty) draw.filter = _filter;
    draw.includeWatched = segment != WatchStatusView.toWatch;
    context.read<AppNavigation>().startDraw();
  }

  void _clearSearchAndFilters() => setState(() {
    _searchCtrl.clear();
    _filter = MovieFilter.empty;
  });

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final nav = context.watch<AppNavigation>();
    final segment = nav.librarySegment;
    final theme = Theme.of(context);
    final padding = pagePadding(context);

    final movies = library.movies;
    final visible = queryMovies(
      movies,
      status: segment,
      search: _searchCtrl.text,
      filter: _filter,
      sort: _sort,
    );
    final counts = {
      WatchStatusView.toWatch: library.toWatchCount,
      WatchStatusView.watched: library.watchedCount,
      WatchStatusView.all: library.totalCount,
    };
    final narrow = MediaQuery.sizeOf(context).width < 480;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha biblioteca')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'library-add',
        onPressed: () => MovieActions.openAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: padding,
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<WatchStatusView>(
                    showSelectedIcon: false,
                    segments: [
                      for (final view in WatchStatusView.values)
                        ButtonSegment(
                          value: view,
                          tooltip: '${view.label}: ${counts[view]}',
                          label: Text(
                            narrow && view == WatchStatusView.toWatch
                                ? 'Quero ver (${counts[view]})'
                                : '${view.label} (${counts[view]})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    selected: {segment},
                    onSelectionChanged: (s) => nav.librarySegment = s.first,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Buscar pelo título',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar busca',
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        setState(_searchCtrl.clear),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      IconButton.outlined(
                        tooltip: 'Filtros',
                        onPressed: () => _openFilters(movies, segment),
                        icon: Badge(
                          isLabelVisible: !_filter.isEmpty,
                          label: Text('${_filter.activeCount}'),
                          child: const Icon(Icons.tune),
                        ),
                      ),
                      PopupMenuButton<MovieSort>(
                        tooltip: 'Ordenar',
                        icon: const Icon(Icons.sort),
                        initialValue: _sort,
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (_) => [
                          for (final s in MovieSort.values)
                            CheckedPopupMenuItem(
                              value: s,
                              checked: s == _sort,
                              child: Text(s.label),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (!_filter.isEmpty) ...[
                    const SizedBox(height: AppSpacing.s),
                    ActiveFiltersBar(
                      filter: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${visible.length} ${visible.length == 1 ? 'filme' : 'filmes'}'
                          ' · ${_sort.label.toLowerCase()}',
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: visible.isEmpty
                            ? null
                            : () => _drawFromHere(segment),
                        icon: const Icon(Icons.shuffle, size: 18),
                        label: const Text('Sortear daqui'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: !library.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? SingleChildScrollView(child: _emptyState(library, segment))
                : _MovieList(movies: visible, padding: padding),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(LibraryController library, WatchStatusView segment) {
    final add = FilledButton.icon(
      onPressed: () => MovieActions.openAdd(context),
      icon: const Icon(Icons.add),
      label: const Text('Adicionar filme'),
    );
    if (library.totalCount == 0) {
      return EmptyState(
        icon: Icons.movie_filter_outlined,
        title: 'Nenhum filme por aqui ainda',
        message: 'Comece adicionando os filmes que você quer assistir.',
        actions: [add],
      );
    }
    if (_searchCtrl.text.isNotEmpty || !_filter.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nenhum filme encontrado',
        message: 'Nada nesta lista corresponde à busca e aos filtros atuais.',
        actions: [
          OutlinedButton(
            onPressed: _clearSearchAndFilters,
            child: const Text('Limpar busca e filtros'),
          ),
        ],
      );
    }
    return switch (segment) {
      WatchStatusView.toWatch => EmptyState(
        icon: Icons.bookmark_add_outlined,
        title: 'Sua lista "Quero assistir" está vazia',
        message: 'Adicione um filme novo ou mova um que você quer rever.',
        actions: [add],
      ),
      WatchStatusView.watched => const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Você ainda não marcou nenhum filme como assistido',
        message:
            'Depois de assistir, marque o filme para registrar a sessão, '
            'avaliar e escrever sua resenha.',
      ),
      WatchStatusView.all => EmptyState(
        icon: Icons.movie_filter_outlined,
        title: 'Biblioteca vazia',
        actions: [add],
      ),
    };
  }
}

/// Lista em uma coluna no celular e duas em telas largas.
class _MovieList extends StatelessWidget {
  const _MovieList({required this.movies, required this.padding});

  final List<Movie> movies;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860 ? 2 : 1;
        final rows = (movies.length / columns).ceil();
        return ListView.separated(
          // Espaço extra no fim para o botão flutuante não cobrir o último item.
          padding: padding.copyWith(top: AppSpacing.s, bottom: 96),
          itemCount: rows,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, row) {
            final start = row * columns;
            return ContentWidth(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: start + c < movies.length
                          ? MovieCard(
                              key: ValueKey(movies[start + c].id),
                              movie: movies[start + c],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
