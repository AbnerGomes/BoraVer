import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/movie_repository.dart';
import 'data/tmdb/tmdb_client.dart';
import 'state/app_navigation.dart';
import 'state/draw_controller.dart';
import 'state/library_controller.dart';
import 'ui/shell/app_shell.dart';

class BoraVerApp extends StatelessWidget {
  const BoraVerApp({super.key, required this.movieRepository, this.tmdb});

  final MovieRepository movieRepository;

  /// Busca de filmes; `null` quando o app foi compilado sem chave do TMDB
  /// (aí o cadastro cai no formulário manual).
  final TmdbClient? tmdb;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LibraryController(movieRepository)..load(),
        ),
        ChangeNotifierProvider(create: (_) => DrawController()),
        Provider<TmdbClient?>.value(value: tmdb),
        ChangeNotifierProvider(create: (_) => AppNavigation()),
      ],
      child: MaterialApp(
        title: 'BoraVer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AppShell(),
      ),
    );
  }
}

/// Exibida se o armazenamento local não puder ser aberto (ex.: navegador
/// em modo privado bloqueando o IndexedDB).
class StorageErrorApp extends StatelessWidget {
  const StorageErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoraVer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  'Não foi possível abrir o armazenamento local.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Se estiver no navegador, verifique se o modo anônimo ou o '
                  'bloqueio de dados de sites está ativo e recarregue a página.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Registra as licenças OFL das fontes empacotadas na tela de licenças.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Poppins', 'assets/fonts/OFL-Poppins.txt'),
      ('DM Serif Display', 'assets/fonts/OFL-DMSerifDisplay.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(file));
    }
  });
}
