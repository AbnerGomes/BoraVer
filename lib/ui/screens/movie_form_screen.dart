import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/country.dart';
import '../../domain/models/genre.dart';
import '../../domain/models/movie.dart';
import '../../state/app_navigation.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/country_picker.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_tags.dart';
import '../widgets/star_rating.dart';
import 'movie_detail_screen.dart';

/// Cadastro (quando [movie] é nulo) ou edição de um filme.
class MovieFormScreen extends StatefulWidget {
  const MovieFormScreen({super.key, this.movie});

  final Movie? movie;

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Movie? _original = widget.movie;
  bool get _isEditing => _original != null;

  late final _title = TextEditingController(text: _original?.title);
  late final _originalTitle = TextEditingController(
    text: _original?.originalTitle,
  );
  late final _year = TextEditingController(text: _original?.year?.toString());
  late final _synopsis = TextEditingController(text: _original?.synopsis);
  late final _poster = TextEditingController(text: _original?.posterUrl);
  late final _review = TextEditingController(text: _original?.review);
  late final List<Genre> _genres = [...?_original?.genres];
  late List<String> _countries = [...?_original?.countries];
  late int? _rating = _original?.rating;
  late final int? _tmdbId = _original?.tmdbId;
  bool _watched = false;
  bool _dirty = false;
  bool _saving = false;

  static final int _maxYear = DateTime.now().year + 10;

  @override
  void dispose() {
    for (final c in [
      _title,
      _originalTitle,
      _year,
      _synopsis,
      _poster,
      _review,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickCountries() async {
    final picked = await pickCountries(context, initial: _countries.toSet());
    if (picked != null) {
      setState(() => _countries = picked.toList());
      _markDirty();
    }
  }

  MovieInput _input() => MovieInput(
    title: _title.text,
    originalTitle: _originalTitle.text,
    year: int.tryParse(_year.text),
    countries: _countries,
    genres: _genres,
    synopsis: _synopsis.text,
    posterUrl: _poster.text,
    rating: _rating,
    review: _review.text,
    tmdbId: _tmdbId,
    watched: _watched,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final library = context.read<LibraryController>();
    final input = _input();

    final duplicate = library.findDuplicate(
      title: input.title,
      originalTitle: input.originalTitle,
      year: input.year,
      tmdbId: input.tmdbId,
      excludeId: _original?.id,
    );
    if (duplicate != null) {
      final choice = await _askAboutDuplicate(duplicate);
      if (!mounted || choice == null) return;
      if (choice == _DuplicateChoice.open) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MovieDetailScreen(movieId: duplicate.id),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final Movie saved;
      if (_isEditing) {
        await library.update(_original!.id, input);
        saved = library.byId(_original.id)!;
      } else {
        saved = await library.add(input);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigation = context.read<AppNavigation>();
      Navigator.of(context).pop(saved);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Alterações salvas.'
                  : '"${saved.title}" adicionado em '
                        '${saved.watched ? 'Já assisti' : 'Quero assistir'}.',
            ),
            action: _isEditing
                ? null
                : SnackBarAction(
                    label: 'Bora sortear',
                    onPressed: navigation.startDraw,
                  ),
          ),
        );
    } catch (error) {
      debugPrint('BoraVer: falha ao salvar filme ($error)');
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'Não foi possível salvar. Tente novamente.');
      }
    }
  }

  Future<_DuplicateChoice?> _askAboutDuplicate(Movie existing) {
    final label = existing.year == null
        ? '"${existing.title}"'
        : '"${existing.title}" (${existing.year})';
    return showDialog<_DuplicateChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esse filme já está na biblioteca?'),
        content: Text(
          'Encontramos $label na lista '
          '${existing.watched ? '"Já assisti"' : '"Quero assistir"'}. '
          'Para evitar duplicatas, você pode abrir o cadastro existente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _DuplicateChoice.saveAnyway),
            child: const Text('Salvar mesmo assim'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DuplicateChoice.open),
            child: const Text('Abrir existente'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await confirmDialog(
      context,
      title: 'Descartar alterações?',
      message: 'O que você preencheu não será salvo.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar filme' : 'Cadastro manual'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.m),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: ListView(
            padding: pagePadding(context).copyWith(bottom: AppSpacing.xxl),
            children: [
              ContentWidth(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _title,
                      autofocus: !_isEditing,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        prefixIcon: Icon(Icons.movie_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o título do filme.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    TextFormField(
                      controller: _originalTitle,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Título original (opcional)',
                        prefixIcon: Icon(Icons.translate),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    TextFormField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Ano de lançamento (opcional)',
                        hintText: 'aaaa',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final year = int.tryParse(v);
                        if (year == null || year < 1870 || year > _maxYear) {
                          return 'Use um ano entre 1870 e $_maxYear.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Label(icon: Icons.sell_outlined, text: 'Gêneros'),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (final g in Genre.sorted)
                          FilterChip(
                            avatar: Icon(genreIcon(g), size: 18),
                            label: Text(g.label),
                            selected: _genres.contains(g),
                            onSelected: (on) {
                              setState(
                                () => on ? _genres.add(g) : _genres.remove(g),
                              );
                              _markDirty();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Label(icon: Icons.flag_outlined, text: 'Países de origem'),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (final code in _countries)
                          InputChip(
                            avatar: Country.flagFor(code).isEmpty
                                ? const Icon(Icons.public, size: 18)
                                : Text(Country.flagFor(code)),
                            label: Text(Country.nameFor(code)),
                            deleteButtonTooltipMessage: 'Remover',
                            onDeleted: () {
                              setState(() => _countries.remove(code));
                              _markDirty();
                            },
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(
                            _countries.isEmpty
                                ? 'Adicionar país'
                                : 'Alterar países',
                          ),
                          onPressed: _pickCountries,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _PosterField(controller: _poster, title: _title.text),
                    const SizedBox(height: AppSpacing.l),
                    TextFormField(
                      controller: _synopsis,
                      minLines: 3,
                      maxLines: 8,
                      maxLength: 3000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Sinopse (opcional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const Divider(height: AppSpacing.xxl),
                    if (!_isEditing)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.check_circle_outline),
                        title: const Text('Já assisti este filme'),
                        subtitle: Text(
                          _watched
                              ? 'Vai para "Já assisti" com uma sessão registrada hoje.'
                              : 'Vai para "Quero assistir".',
                        ),
                        value: _watched,
                        onChanged: (v) {
                          setState(() => _watched = v);
                          _markDirty();
                        },
                      ),
                    const SizedBox(height: AppSpacing.s),
                    _Label(
                      icon: Icons.star_outline_rounded,
                      text: 'Sua avaliação',
                    ),
                    Wrap(
                      spacing: AppSpacing.m,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StarRating(
                          value: _rating,
                          size: 32,
                          onChanged: (v) {
                            setState(() => _rating = v);
                            _markDirty();
                          },
                        ),
                        Text(
                          StarRating.describe(_rating),
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TextFormField(
                      controller: _review,
                      minLines: 3,
                      maxLines: 10,
                      maxLength: 5000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Resenha ou comentário (opcional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check),
                      label: Text(
                        _isEditing ? 'Salvar alterações' : 'Adicionar filme',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DuplicateChoice { open, saveAnyway }

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.m),
    child: SectionTitle(text, icon: icon),
  );
}

class _PosterField extends StatefulWidget {
  const _PosterField({required this.controller, required this.title});

  final TextEditingController controller;
  final String title;

  @override
  State<_PosterField> createState() => _PosterFieldState();
}

class _PosterFieldState extends State<_PosterField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  static bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoviePoster(
          url: text.isNotEmpty && _isValidUrl(text) ? text : null,
          title: widget.title,
          width: 64,
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link do pôster (opcional)',
              hintText: 'https://…',
              prefixIcon: Icon(Icons.image_outlined),
              helperText: 'Endereço de uma imagem na internet.',
            ),
            validator: (v) => v == null || v.trim().isEmpty || _isValidUrl(v)
                ? null
                : 'Informe um link começando com http:// ou https://',
          ),
        ),
      ],
    );
  }
}
