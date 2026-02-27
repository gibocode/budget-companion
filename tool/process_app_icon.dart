// Run from project root: dart run tool/process_app_icon.dart
// Inverts the app icon colors and adds a drop shadow, then overwrites assets/app_icon_square.png

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const assetPath = 'assets/app_icon_square.png';
  final file = File(assetPath);
  if (!file.existsSync()) {
    print('Error: $assetPath not found.');
    exit(1);
  }

  final bytes = file.readAsBytesSync();
  img.Image? src = img.decodeImage(bytes);
  if (src == null) {
    print('Error: Could not decode image.');
    exit(1);
  }

  // Ensure 4 channels for alpha (needed for shadow and compositing)
  if (src.numChannels < 4) {
    src = src.convert(numChannels: 4);
  }

  // 1) Invert the icon colors (modifies in place)
  img.invert(src);

  // 2) Add drop shadow: shadow offset (6, 6), blur radius 10, semi-transparent black
  final result = img.dropShadow(
    src,
    6, // hShadow
    6, // vShadow
    10, // blur
    shadowColor: img.ColorRgba8(0, 0, 0, 140),
  );

  final outBytes = img.encodePng(result);
  if (outBytes == null) {
    print('Error: Could not encode PNG.');
    exit(1);
  }
  file.writeAsBytesSync(outBytes);
  print('Done: $assetPath updated (inverted colors + icon shadow).');
}
