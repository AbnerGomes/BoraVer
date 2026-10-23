import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backup_codec.dart';
import '../../state/library_controller.dart';
import '../widgets/cinema_decor.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: pagePadding(context).copyWith(bottom: AppSpacing.xxl),
        children: const [
          ContentWidth(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackupSection(),
                SizedBox(height: AppSpacing.l),
                _AboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title, icon: icon),
            const SizedBox(height: AppSpacing.m),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BackupSection extends StatefulWidget {
  const _BackupSection();

  @override
  State<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<_BackupSection> {
  bool _busy = false;

  Future<void> _export() async {
    final library = context.read<LibraryController>();
    if (library.totalCount == 0) {
      showMessage(context, 'A biblioteca está vazia: não há o que exportar.');
      return;
    }
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final json = BackupCodec.encode(library.movies, exportedAt: now);
      final name =
          'boraver-backup-${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}.json';
      final saved = await FilePicker.saveFile(
        fileName: name,
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        dialogTitle: 'Salvar backup do BoraVer',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (!mounted) return;
      if (saved == null && !kIsWeb) {
        showMessage(context, 'Exportação cancelada.');
      } else {
        showMessage(
          context,
          'Backup com ${library.totalCount} filme(s) salvo como $name.',
        );
      }
    } catch (error) {
      debugPrint('BoraVer: falha ao exportar ($error)');
      if (mounted) showMessage(context, 'Não foi possível exportar o backup.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final library = context.read<LibraryController>();
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Escolha um backup do BoraVer',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null || !mounted) return;
      final BackupContents contents;
      try {
        contents = BackupCodec.decode(utf8.decode(await file.readAsBytes()));
      } on FormatException catch (e) {
        if (mounted) showMessage(context, e.message);
        return;
      }
      if (!mounted) return;
      final confirmed = await confirmDialog(
        context,
        title: 'Importar backup?',
        message:
            'O arquivo tem ${contents.movies.length} filme(s). Eles serão '
            'mesclados à sua biblioteca: nada será apagado, filmes repetidos '
            'são ignorados e registros existentes só são atualizados se a '
            'versão do backup for mais recente.',
        confirmLabel: 'Importar',
      );
      if (!confirmed || !mounted) return;
      final r = await library.importMovies(
        contents.movies,
        invalid: contents.skipped,
      );
      if (!mounted) return;
      final parts = [
        '${r.added} adicionado(s)',
        if (r.updated > 0) '${r.updated} atualizado(s)',
        if (r.unchanged > 0) '${r.unchanged} sem mudança',
        if (r.duplicates > 0) '${r.duplicates} duplicado(s) ignorado(s)',
        if (r.invalid > 0) '${r.invalid} inválido(s)',
      ];
      showMessage(context, 'Importação concluída: ${parts.join(', ')}.');
    } catch (error) {
      debugPrint('BoraVer: falha ao importar ($error)');
      if (mounted) showMessage(context, 'Não foi possível importar o arquivo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SettingsCard(
      title: 'Backup da biblioteca',
      icon: Icons.save_alt,
      children: [
        Text(
          'Exporte um arquivo JSON para guardar uma cópia ou levar sua '
          'biblioteca do navegador para o celular (e vice-versa).',
          style: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_file),
              label: const Text('Exportar backup'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download),
              label: const Text('Importar backup'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return _SettingsCard(
      title: 'Sobre',
      icon: Icons.info_outline,
      children: [
        const BoraVerLogo(size: 28),
        const SizedBox(height: AppSpacing.m),
        Text('Versão 1.0.0', style: muted),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Seus filmes ficam salvos somente neste dispositivo (no navegador, '
          'dentro dos dados do site). Limpar os dados do navegador ou '
          'desinstalar o app apaga a biblioteca — faça backups de vez em quando.',
          style: muted,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Dados e pôsteres dos filmes: TMDB (themoviedb.org). Este produto '
          'usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.',
          style: muted,
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'BoraVer',
            applicationVersion: '1.0.0',
          ),
          child: const Text('Licenças de código aberto'),
        ),
      ],
    );
  }
}
