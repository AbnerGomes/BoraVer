import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/country.dart';

/// Seleção de um ou mais países com busca. Retorna `null` se cancelado.
Future<Set<String>?> pickCountries(
  BuildContext context, {
  required Set<String> initial,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (_) => _CountryPickerDialog(initial: initial),
  );
}

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({required this.initial});

  final Set<String> initial;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  late final Set<String> _selected = {...widget.initial};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = Country.search(_query);
    // Códigos desconhecidos (ex.: vindos do TMDB) continuam selecionáveis.
    final unknown = _selected.where((c) => !countriesByCode.containsKey(c));
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.l),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Países de origem',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${_selected.length} selecionado(s)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar país',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: results.isEmpty && unknown.isEmpty
                  ? const Center(child: Text('Nenhum país encontrado.'))
                  : ListView(
                      children: [
                        for (final code in unknown)
                          _tile(Country(code, Country.nameFor(code))),
                        for (final c in results) _tile(c),
                      ],
                    ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Country country) {
    return CheckboxListTile(
      value: _selected.contains(country.code),
      onChanged: (checked) => setState(() {
        checked == true
            ? _selected.add(country.code)
            : _selected.remove(country.code);
      }),
      secondary: Text(
        country.flag.isEmpty ? '🌐' : country.flag,
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(country.name),
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
    );
  }
}
