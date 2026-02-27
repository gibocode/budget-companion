// Run from project root: dart run tool/restore_app_icon.dart
// Inverts the current app icon to restore original colors (undo invert).

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

  if (src.numChannels < 4) {
    src = src.convert(numChannels: 4);
  }

  img.invert(src);

  final outBytes = img.encodePng(src);
  if (outBytes == null) {
    print('Error: Could not encode PNG.');
    exit(1);
  }
  file.writeAsBytesSync(outBytes);
  print('Done: $assetPath restored (invert undone).');
}
