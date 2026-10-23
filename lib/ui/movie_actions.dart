import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/tmdb/tmdb_client.dart';
import '../domain/models/movie.dart';
import '../state/library_controller.dart';
import 'screens/add_movie_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movie_form_screen.dart';
import 'widgets/common.dart';

/// Ações sobre filmes compartilhadas por cartões, detalhes e sorteio, com
/// tratamento de erro e mensagens consistentes.
abstract final class MovieActions {
  static void openDetails(BuildContext context, String movieId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovieDetailScreen(movieId: movieId),
      ),
    );
  }

  /// Adicionar filme: busca pelo nome no TMDB. Sem TMDB disponível no build,
  /// abre o cadastro manual.
  static void openAdd(BuildContext context) {
    final tmdb = context.read<TmdbClient?>();
    if (tmdb == null) {
      openForm(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddMovieScreen(tmdb: tmdb),
        fullscreenDialog: true,
      ),
    );
  }

  /// Abre o formulário manual (novo filme se [movie] for nulo) — usado para
  /// editar e como alternativa quando o filme não está no TMDB.
  static Future<Movie?> openForm(BuildContext context, {Movie? movie}) {
    return Navigator.of(context).push(
      MaterialPageRoute<Movie>(
        builder: (_) => MovieFormScreen(movie: movie),
        fullscreenDialog: true,
      ),
    );
  }

  static Future<void> markWatched(BuildContext context, Movie movie) => _run(
    context,
    (c) => c.markWatched(movie.id),
    success: '"${movie.title}" foi para Já assisti.',
    undo: movie,
  );

  static Future<void> watchAgain(BuildContext context, Movie movie) => _run(
    context,
    (c) => c.watchAgain(movie.id),
    success: 'Sessão registrada: ${movie.watchCount + 1}ª vez.',
    undo: movie,
  );

  static Future<void> markUnwatched(BuildContext context, Movie movie) => _run(
    context,
    (c) => c.markUnwatched(movie.id),
    success: '"${movie.title}" voltou para Quero assistir.',
    undo: movie,
  );

  /// Pede confirmação e exclui. Retorna `true` se excluiu.
  static Future<bool> delete(BuildContext context, Movie movie) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir filme?',
      message:
          '"${movie.title}" será removido da biblioteca, junto com a '
          'avaliação, a resenha e o histórico. Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;
    var ok = false;
    await _run(context, (c) async {
      await c.delete(movie.id);
      ok = true;
    }, success: 'Filme excluído.');
    return ok;
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function(LibraryController) action, {
    required String success,
    Movie? undo,
  }) async {
    final controller = context.read<LibraryController>();
    try {
      await action(controller);
      if (!context.mounted) return;
      showMessage(
        context,
        success,
        actionLabel: undo == null ? null : 'Desfazer',
        onAction: undo == null ? null : () => controller.restore(undo),
      );
    } catch (error) {
      debugPrint('BoraVer: falha em ação de filme ($error)');
      if (!context.mounted) return;
      showMessage(context, 'Não foi possível salvar. Tente novamente.');
    }
  }
}
