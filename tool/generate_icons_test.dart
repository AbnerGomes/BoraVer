// Gera os ícones do app (Android e Web) a partir da claquete do logotipo.
//
// Uso (no container):
//   docker compose run --rm flutter flutter test tool/generate_icons_test.dart
//
// Fica fora de test/ para não rodar junto com a suíte normal.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:boraver/core/theme/app_colors.dart';
import 'package:boraver/ui/widgets/cinema_decor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _render(int size, {required bool maskable}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  final full = Rect.fromLTWH(0, 0, s, s);
  final background = Paint()..color = AppColors.beige;

  if (maskable) {
    // Ícone "maskable": fundo até a borda e desenho dentro da zona segura.
    canvas.drawRect(full, background);
  } else {
    canvas.drawRRect(
      RRect.fromRectAndRadius(full, Radius.circular(s * 0.22)),
      background,
    );
  }

  final content = s * (maskable ? 0.5 : 0.6);
  canvas.translate((s - content) / 2, (s - content) / 2 + s * 0.02);
  const ClapperPainter().paint(canvas, Size(content, content));

  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<void> _write(String path, int size, {bool maskable = false}) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(await _render(size, maskable: maskable));
}

void main() {
  testWidgets('gera ícones', (tester) async {
    await tester.runAsync(() async {
      const android = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final entry in android.entries) {
        await _write(
          'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
          entry.value,
        );
      }
      await _write('web/favicon.png', 64);
      await _write('web/icons/Icon-192.png', 192);
      await _write('web/icons/Icon-512.png', 512);
      await _write('web/icons/Icon-maskable-192.png', 192, maskable: true);
      await _write('web/icons/Icon-maskable-512.png', 512, maskable: true);
      // Imagem central da tela de abertura do Android.
      await _write(
        'android/app/src/main/res/drawable/splash_logo.png',
        288,
        maskable: true,
      );
    });
  });
}
