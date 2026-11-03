// Draws the launcher icons from the Genie mark. Run on demand:
//   flutter test test/tool/render_icon_test.dart
// It writes PNGs into android/app/src/main/res.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:business_genie/core/widgets/genie_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _ink = Color(0xFF18181A);

Future<void> _render(WidgetTester tester, Widget child, double size, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: RepaintBoundary(key: key, child: SizedBox.square(dimension: size, child: child))),
    ),
  );
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  const res = 'android/app/src/main/res';
  const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

  testWidgets('launcher icons', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 600);
    addTearDown(tester.view.reset);

    for (final e in densities.entries) {
      // Legacy icon: an ink squircle with the spark.
      final legacy = 48 * e.value;
      await _render(
        tester,
        DecoratedBox(
          decoration: ShapeDecoration(color: _ink, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(legacy * .26))),
          child: Center(child: GenieMark(size: legacy * .6, mono: Colors.white, dot: const Color(0xFF9B85FF))),
        ),
        legacy,
        '$res/mipmap-${e.key}/ic_launcher.png',
      );
      // Adaptive foreground: 108 dp canvas, the spark inside the 66 dp safe zone.
      final fg = 108 * e.value;
      await _render(tester, Center(child: GenieMark(size: fg * .46, mono: Colors.white, dot: const Color(0xFF9B85FF))), fg, '$res/mipmap-${e.key}/ic_launcher_foreground.png');
    }
  });
}
