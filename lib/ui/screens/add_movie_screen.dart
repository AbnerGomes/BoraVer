import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/tmdb/tmdb_client.dart';
import '../../domain/models/movie.dart';
import '../../state/app_navigation.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_tags.dart';
import 'movie_form_screen.dart';

/// Adicionar filme = pesquisar pelo nome e escolher. Pôster, sinopse,
/// gêneros, países e ano vêm automaticamente do TMDB.
class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key, required this.tmdb});

  final TmdbClient tmdb;

  /// Espera entre a digitação e a busca, para não chamar a API a cada tecla.
  static const debounce = Duration(milliseconds: 400);

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  List<TmdbMovieSummary> _results = const [];
  bool _showingTrending = true;
  bool _loading = false;
  String? _error;

  /// Ids do TMDB sendo adicionados agora (mostra o indicador no item).
  final Set<int> _adding = {};

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(AddMovieScreen.debounce, () => _load(text));
    setState(() {});
  }

  Future<void> _load(String text) async {
    final query = text.trim();
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = query.length < 2
          ? await widget.tmdb.trending()
          : await widget.tmdb.search(query);
      // Ignora respostas antigas que chegaram depois de uma busca mais nova.
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _showingTrending = query.length < 2;
      });
    } on TmdbException catch (e) {
      if (mounted && id == _requestId) setState(() => _error = e.message);
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  Future<void> _add(TmdbMovieSummary summary, {bool watched = false}) async {
    final library = context.read<LibraryController>();
    setState(() => _adding.add(summary.id));
    try {
      final details = await widget.tmdb.details(summary.id);
      final movie = await library.addFromTmdb(details, watched: watched);
      if (mounted) _confirmAdded(movie);
    } on TmdbException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (error) {
      debugPrint('BoraVer: falha ao adicionar ($error)');
      if (mounted) {
        showMessage(context, 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _adding.remove(summary.id));
    }
  }

  void _confirmAdded(Movie movie) {
    final navigation = context.read<AppNavigation>();
    showMessage(
      context,
      '"${movie.title}" adicionado em '
      '${movie.watched ? 'Já assisti' : 'Quero assistir'}.',
      actionLabel: 'Bora sortear',
      onAction: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        navigation.startDraw();
      },
    );
  }

  Future<void> _preview(TmdbMovieSummary summary) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _PreviewSheet(tmdb: widget.tmdb, summary: summary),
    );
    if (choice != null && mounted) await _add(summary, watched: choice);
  }

  void _openManualForm() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<Movie>(
        builder: (_) => const MovieFormScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar filme')),
      body: Column(
        children: [
          Padding(
            padding: pagePadding(context).copyWith(bottom: AppSpacing.s),
            child: ContentWidth(
              maxWidth: 720,
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (text) {
                  _debounce?.cancel();
                  _load(text);
                },
                decoration: InputDecoration(
                  hintText: 'Digite o nome do filme',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _ctrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _ctrl.clear();
                            _onChanged('');
                          },
                        ),
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final manualButton = TextButton.icon(
      onPressed: _openManualForm,
      icon: const Icon(Icons.edit_note),
      label: const Text('Não achou? Cadastrar manualmente'),
    );

    if (_error != null) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: 'Não deu para buscar agora',
          message: _error,
          actions: [
            FilledButton.icon(
              onPressed: () => _load(_ctrl.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
            manualButton,
          ],
        ),
      );
    }
    if (!_loading && _results.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.search_off,
          title: _showingTrending
              ? 'Digite o nome de um filme'
              : 'Nenhum filme encontrado',
          message: _showingTrending
              ? null
              : 'Confira a grafia ou tente o título original.',
          actions: [manualButton],
        ),
      );
    }

    final library = context.watch<LibraryController>();
    final padding = pagePadding(context);
    return ListView(
      padding: padding.copyWith(bottom: AppSpacing.xxl),
      children: [
        ContentWidth(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showingTrending && _results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: SectionTitle(
                    'Em alta nesta semana',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
              for (final r in _results)
                _ResultTile(
                  summary: r,
                  inLibrary: library.findByTmdb(
                    r.id,
                    title: r.title,
                    year: r.year,
                  ),
                  adding: _adding.contains(r.id),
                  onAdd: () => _add(r),
                  onTap: () => _preview(r),
                ),
              const SizedBox(height: AppSpacing.l),
              Center(child: manualButton),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Dados e imagens: TMDB. Este produto usa a API do TMDB, '
                'mas não é endossado nem certificado pelo TMDB.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.summary,
    required this.inLibrary,
    required this.adding,
    required this.onAdd,
    required this.onTap,
  });

  final TmdbMovieSummary summary;
  final Movie? inLibrary;
  final bool adding;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (summary.year != null) '${summary.year}',
      if (summary.originalTitle != null &&
          summary.originalTitle != summary.title)
        summary.originalTitle!,
    ].join(' · ');

    final Widget trailing;
    if (inLibrary != null) {
      trailing = Tooltip(
        message: 'Já está na sua biblioteca',
        child: Chip(
          avatar: const Icon(Icons.check, size: 16, color: AppColors.sageDark),
          label: Text(inLibrary!.watched ? 'Já assisti' : 'Na lista'),
          visualDensity: VisualDensity.compact,
        ),
      );
    } else if (adding) {
      trailing = const Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      trailing = IconButton.filled(
        tooltip: 'Adicionar ${summary.title}',
        onPressed: onAdd,
        icon: const Icon(Icons.add),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Row(
              children: [
                MoviePoster(
                  url: summary.thumbnailUrl,
                  title: summary.title,
                  width: 52,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (summary.overview != null)
                        Text(
                          summary.overview!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prévia com os dados completos. Retorna `false` para "Quero assistir",
/// `true` para "Já assisti" e `null` se fechar sem escolher.
class _PreviewSheet extends StatefulWidget {
  const _PreviewSheet({required this.tmdb, required this.summary});

  final TmdbClient tmdb;
  final TmdbMovieSummary summary;

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  late final Future<TmdbMovieDetails> _details = widget.tmdb.details(
    widget.summary.id,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.summary;
    final inLibrary = context.watch<LibraryController>().findByTmdb(
      s.id,
      title: s.title,
      year: s.year,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<TmdbMovieDetails>(
        future: _details,
        builder: (context, snap) {
          final d = snap.data;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoviePoster(
                    url: d?.posterUrl ?? s.thumbnailUrl,
                    title: s.title,
                    width: 110,
                    radius: AppRadius.m,
                  ),
                  const SizedBox(width: AppSpacing.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: theme.textTheme.headlineSmall),
                        if (s.originalTitle != null &&
                            s.originalTitle != s.title)
                          Text(
                            s.originalTitle!,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.s),
                        if (d != null)
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (d.year != null) YearTag(d.year!),
                              for (final c in d.countries) CountryTag(c),
                              for (final g in d.genres) GenreTag(g),
                            ],
                          )
                        else if (s.year != null)
                          YearTag(s.year!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              if (snap.hasError)
                Text(
                  snap.error is TmdbException
                      ? (snap.error! as TmdbException).message
                      : 'Não foi possível carregar os detalhes.',
                  style: TextStyle(color: theme.colorScheme.error),
                )
              else if (d == null)
                const Center(child: CircularProgressIndicator())
              else
                Text(
                  d.overview ?? 'Sem sinopse disponível no TMDB.',
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.xl),
              if (inLibrary != null)
                Text(
                  'Este filme já está na sua biblioteca '
                  '(${inLibrary.watched ? 'Já assisti' : 'Quero assistir'}).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Quero assistir'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Já assisti'),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
