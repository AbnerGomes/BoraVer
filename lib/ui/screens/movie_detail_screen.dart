import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/movie.dart';
import '../../state/library_controller.dart';
import '../movie_actions.dart';
import '../widgets/common.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_tags.dart';
import '../widgets/star_rating.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  Widget build(BuildContext context) {
    final movie = context.select<LibraryController, Movie?>(
      (c) => c.byId(movieId),
    );

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.movie_filter_outlined,
          title: 'Filme não encontrado',
          message: 'Ele pode ter sido excluído.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => MovieActions.openForm(context, movie: movie),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final deleted = await MovieActions.delete(context, movie);
              if (deleted && context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: ListView(
        padding: pagePadding(context).copyWith(bottom: AppSpacing.xxl),
        children: [
          ContentWidth(
            maxWidth: 820,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(movie: movie),
                const SizedBox(height: AppSpacing.xl),
                _StatusActions(movie: movie),
                const SizedBox(height: AppSpacing.xl),
                _RatingSection(movie: movie),
                const SizedBox(height: AppSpacing.l),
                _ReviewSection(movie: movie),
                if (movie.synopsis != null) ...[
                  const SizedBox(height: AppSpacing.l),
                  _Section(
                    title: 'Sinopse',
                    icon: Icons.subject,
                    child: Text(
                      movie.synopsis!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.l),
                _HistorySection(movie: movie),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Adicionado em ${formatDate(movie.createdAt)} · '
                  'Atualizado em ${formatDate(movie.updatedAt)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusChip(watched: movie.watched),
        const SizedBox(height: AppSpacing.s),
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
        if (movie.year == null &&
            movie.countries.isEmpty &&
            movie.genres.isEmpty)
          Text(
            'Sem ano, país ou gênero cadastrados.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final poster = MoviePoster(
          url: movie.posterUrl,
          title: movie.title,
          width: wide ? 180 : 150,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: poster),
            const SizedBox(height: AppSpacing.l),
            info,
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.watched});

  final bool watched;

  @override
  Widget build(BuildContext context) {
    final color = watched ? AppColors.sageDark : AppColors.terracottaDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            watched ? Icons.check_circle : Icons.bookmark,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            watched ? 'Já assisti' : 'Quero assistir',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        if (!movie.watched)
          FilledButton.icon(
            onPressed: () => MovieActions.markWatched(context, movie),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar como assistido'),
          )
        else ...[
          FilledButton.icon(
            onPressed: () => MovieActions.watchAgain(context, movie),
            icon: const Icon(Icons.replay),
            label: const Text('Assisti novamente'),
          ),
          OutlinedButton.icon(
            onPressed: () => MovieActions.markUnwatched(context, movie),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Mover para Quero assistir'),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title, icon: icon, trailing: trailing),
            const SizedBox(height: AppSpacing.m),
            child,
          ],
        ),
      ),
    );
  }
}

Future<void> _save(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (success != null && context.mounted) showMessage(context, success);
  } catch (error) {
    debugPrint('BoraVer: falha ao salvar ($error)');
    if (context.mounted) {
      showMessage(context, 'Não foi possível salvar. Tente novamente.');
    }
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<LibraryController>();
    return _Section(
      title: 'Sua avaliação',
      icon: Icons.star_outline_rounded,
      trailing: movie.isRated
          ? TextButton(
              onPressed: () =>
                  _save(context, () => controller.setRating(movie.id, null)),
              child: const Text('Remover'),
            )
          : null,
      child: Wrap(
        spacing: AppSpacing.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StarRating(
            value: movie.rating,
            size: 34,
            onChanged: (v) =>
                _save(context, () => controller.setRating(movie.id, v)),
          ),
          Text(
            movie.isRated
                ? StarRating.describe(movie.rating)
                : 'Toque para avaliar',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.movie});

  final Movie movie;

  Future<void> _edit(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDialog(initial: movie.review ?? ''),
    );
    if (text == null || !context.mounted) return;
    await _save(
      context,
      () => context.read<LibraryController>().setReview(movie.id, text),
      success: text.trim().isEmpty ? 'Resenha removida.' : 'Resenha salva.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      title: 'Sua resenha',
      icon: Icons.edit_note,
      trailing: TextButton.icon(
        onPressed: () => _edit(context),
        icon: Icon(movie.hasReview ? Icons.edit_outlined : Icons.add, size: 18),
        label: Text(movie.hasReview ? 'Editar' : 'Escrever'),
      ),
      child: movie.hasReview
          ? SelectableText(movie.review!, style: theme.textTheme.bodyMedium)
          : Text(
              'O que você achou? Escreva uma opinião, lembrete ou comentário.',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.initial});

  final String initial;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sua resenha'),
      content: SizedBox(
        width: 560,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          minLines: 6,
          maxLines: 14,
          maxLength: 5000,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Escreva aqui o que achou do filme…',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.movie});

  final Movie movie;

  Future<void> _addPastSession(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Quando você assistiu?',
    );
    if (date == null || !context.mounted) return;
    // Meio-dia evita que o fuso horário mude o dia exibido.
    final at = DateTime(date.year, date.month, date.day, 12);
    await _save(
      context,
      () => context.read<LibraryController>().watchAgain(movie.id, at: at),
      success: 'Sessão de ${formatDate(at)} registrada.',
    );
  }

  Future<void> _remove(BuildContext context, DateTime session) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover sessão?',
      message:
          'A sessão de ${formatDateLong(session)} será removida do histórico.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await _save(
      context,
      () => context.read<LibraryController>().removeSession(movie.id, session),
      success: 'Sessão removida.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = movie.watchCount;
    final sessions = movie.watchSessions.reversed.toList();

    return _Section(
      title: count == 0
          ? 'Histórico de sessões'
          : 'Assistido $count ${count == 1 ? 'vez' : 'vezes'}',
      icon: Icons.history,
      trailing: TextButton.icon(
        onPressed: () => _addPastSession(context),
        icon: const Icon(Icons.event_available_outlined, size: 18),
        label: const Text('Adicionar data'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!movie.watched && count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text(
                'Este filme está em "Quero assistir", mas o histórico foi mantido.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (sessions.isEmpty)
            Text(
              'Nenhuma sessão registrada ainda.',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final (i, session) in sessions.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.local_activity_outlined,
                  color: AppColors.goldDark,
                ),
                title: Text(formatDateLong(session)),
                subtitle: Text('${sessions.length - i}ª sessão'),
                trailing: IconButton(
                  tooltip: 'Remover sessão',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _remove(context, session),
                ),
              ),
        ],
      ),
    );
  }
}
