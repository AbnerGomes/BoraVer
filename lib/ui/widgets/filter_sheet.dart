import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/text_normalize.dart';
import '../../domain/models/country.dart';
import '../../domain/models/genre.dart';
import '../../domain/models/movie_filter.dart';
import 'country_picker.dart';
import 'movie_tags.dart';

/// Abre o painel de filtros (gênero, país e ano). Retorna o novo filtro ou
/// `null` se o usuário fechar sem aplicar.
///
/// [libraryCountries] sugere os países que já existem na biblioteca e
/// [countFor] mostra quantos filmes o filtro em edição encontra.
Future<MovieFilter?> showFilterSheet(
  BuildContext context, {
  required MovieFilter initial,
  required Set<String> libraryCountries,
  required int Function(MovieFilter) countFor,
}) {
  return showModalBottomSheet<MovieFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _FilterSheet(
      initial: initial,
      libraryCountries: libraryCountries,
      countFor: countFor,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.libraryCountries,
    required this.countFor,
  });

  final MovieFilter initial;
  final Set<String> libraryCountries;
  final int Function(MovieFilter) countFor;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late MovieFilter _filter = widget.initial;
  late final _fromCtrl = TextEditingController(
    text: widget.initial.yearFrom?.toString() ?? '',
  );
  late final _toCtrl = TextEditingController(
    text: widget.initial.yearTo?.toString() ?? '',
  );

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  int? get _from => int.tryParse(_fromCtrl.text);
  int? get _to => int.tryParse(_toCtrl.text);

  String? get _yearError {
    final from = _from, to = _to;
    if (_fromCtrl.text.isNotEmpty && (from == null || from < 1870)) {
      return 'Ano inicial inválido.';
    }
    if (_toCtrl.text.isNotEmpty && (to == null || to < 1870)) {
      return 'Ano final inválido.';
    }
    if (from != null && to != null && from > to) {
      return 'O ano inicial deve ser menor ou igual ao final.';
    }
    return null;
  }

  void _updateYears() => setState(() {
    if (_yearError == null) _filter = _filter.withYears(_from, _to);
  });

  void _clear() => setState(() {
    _filter = MovieFilter.empty;
    _fromCtrl.clear();
    _toCtrl.clear();
  });

  Future<void> _pickOtherCountries() async {
    final picked = await pickCountries(context, initial: _filter.countries);
    if (picked != null) {
      setState(() => _filter = _filter.copyWith(countries: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.countFor(_filter);
    final countryOptions =
        {...widget.libraryCountries, ..._filter.countries}.toList()
          ..sort((a, b) => compareText(Country.nameFor(a), Country.nameFor(b)));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtros',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _filter.isEmpty && _yearError == null
                        ? null
                        : _clear,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpar tudo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  _Heading(icon: Icons.sell_outlined, text: 'Gêneros'),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      for (final g in Genre.sorted)
                        FilterChip(
                          avatar: Icon(genreIcon(g), size: 18),
                          label: Text(g.label),
                          selected: _filter.genres.contains(g),
                          onSelected: (on) => setState(() {
                            final set = {..._filter.genres};
                            on ? set.add(g) : set.remove(g);
                            _filter = _filter.copyWith(genres: set);
                          }),
                        ),
                    ],
                  ),
                  if (_filter.genres.length > 1)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Exigir todos os gêneros marcados'),
                      subtitle: Text(
                        _filter.matchAllGenres
                            ? 'Ex.: só filmes que sejam comédia E romance.'
                            : 'Basta ter um dos gêneros marcados.',
                      ),
                      value: _filter.matchAllGenres,
                      onChanged: (v) => setState(
                        () => _filter = _filter.copyWith(matchAllGenres: v),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  _Heading(icon: Icons.flag_outlined, text: 'Países de origem'),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      for (final code in countryOptions)
                        FilterChip(
                          avatar: Country.flagFor(code).isEmpty
                              ? const Icon(Icons.public, size: 18)
                              : Text(Country.flagFor(code)),
                          label: Text(Country.nameFor(code)),
                          selected: _filter.countries.contains(code),
                          onSelected: (on) => setState(() {
                            final set = {..._filter.countries};
                            on ? set.add(code) : set.remove(code);
                            _filter = _filter.copyWith(countries: set);
                          }),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Outro país'),
                        onPressed: _pickOtherCountries,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Heading(
                    icon: Icons.calendar_month_outlined,
                    text: 'Ano de lançamento',
                  ),
                  Text(
                    'Para um ano específico, use o mesmo valor nos dois campos.',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: [
                      Expanded(child: _yearField(_fromCtrl, 'De')),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(child: _yearField(_toCtrl, 'Até')),
                    ],
                  ),
                  if (_yearError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s),
                      child: Text(
                        _yearError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _yearError != null
                      ? null
                      : () => Navigator.pop(context, _filter),
                  icon: const Icon(Icons.check),
                  label: Text(
                    'Aplicar · $count ${count == 1 ? 'filme' : 'filmes'}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: 'aaaa'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (_) => _updateYears(),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.terracottaDark),
          const SizedBox(width: AppSpacing.s),
          Text(text, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Chips dos filtros ativos, cada um removível individualmente.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final MovieFilter filter;
  final ValueChanged<MovieFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) return const SizedBox.shrink();
    Widget chip(Widget avatar, String label, MovieFilter without) => InputChip(
      avatar: avatar,
      label: Text(label),
      onDeleted: () => onChanged(without),
      deleteButtonTooltipMessage: 'Remover filtro $label',
    );

    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final g in filter.genres)
          chip(Icon(genreIcon(g), size: 18), g.label, filter.withoutGenre(g)),
        for (final c in filter.countries)
          chip(
            Country.flagFor(c).isEmpty
                ? const Icon(Icons.public, size: 18)
                : Text(Country.flagFor(c)),
            Country.nameFor(c),
            filter.withoutCountry(c),
          ),
        if (filter.hasYear)
          chip(
            const Icon(Icons.calendar_today_outlined, size: 16),
            filter.yearLabel!,
            filter.withoutYears(),
          ),
        if (filter.genres.length > 1 && filter.matchAllGenres)
          Text(
            '(todos os gêneros)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        TextButton(
          onPressed: () => onChanged(MovieFilter.empty),
          child: const Text('Limpar filtros'),
        ),
      ],
    );
  }
}
