import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'data/hive_storage.dart';
import 'data/tmdb/tmdb_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  try {
    await Hive.initFlutter('boraver');
    final storage = await HiveStorage.open();
    runApp(
      BoraVerApp(movieRepository: storage.movies, tmdb: TmdbClient.fromBuild()),
    );
  } catch (error) {
    debugPrint('BoraVer: falha ao abrir armazenamento ($error)');
    runApp(const StorageErrorApp());
  }
}
