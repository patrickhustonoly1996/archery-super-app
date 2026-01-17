// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Gold color (#FFD700)
const int goldR = 255;
const int goldG = 215;
const int goldB = 0;

/// Dark background (#1A1A1A)
const int bgR = 26;
const int bgG = 26;
const int bgB = 26;

void main() {
  // Generate different sizes
  final sizes = [16, 32, 48, 64, 128, 192, 512];

  for (final size in sizes) {
    final image = generateFavicon(size);
    final filename = size == 32 ? 'favicon.png' : 'icon-$size.png';
    final path = size == 32 ? 'web/$filename' : 'web/icons/$filename';

    // Ensure directory exists
    final dir = Directory(path.substring(0, path.lastIndexOf('/')));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    File(path).writeAsBytesSync(img.encodePng(image));
    print('Generated $path');
  }

  print('Done! Favicon files generated.');
}

img.Image generateFavicon(int size) {
  final image = img.Image(width: size, height: size);

  // Start with transparent background
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final pixelSize = size / 16;

  final gold = img.ColorRgba8(goldR, goldG, goldB, 255);
  final goldFaint = img.ColorRgba8(goldR, goldG, goldB, 128);
  final goldVeryFaint = img.ColorRgba8(goldR, goldG, goldB, 77);

  void drawPixel(int x, int y, img.Color color) {
    final x1 = (x * pixelSize).round();
    final y1 = (y * pixelSize).round();
    final x2 = ((x + 1) * pixelSize).round();
    final y2 = ((y + 1) * pixelSize).round();

    for (int px = x1; px < x2 && px < size; px++) {
      for (int py = y1; py < y2 && py < size; py++) {
        image.setPixel(px, py, color);
      }
    }
  }

  // Pixel arrow pointing right - matches PixelBowIcon exactly
  // Arrow shaft (thick, 2 pixels high)
  for (int x = 1; x <= 11; x++) {
    drawPixel(x, 7, gold);
    drawPixel(x, 8, gold);
  }

  // Arrow head - top diagonal
  drawPixel(9, 4, gold);
  drawPixel(10, 5, gold);
  drawPixel(11, 6, gold);
  drawPixel(12, 7, gold);
  drawPixel(12, 8, gold);

  // Arrow head - bottom diagonal
  drawPixel(11, 9, gold);
  drawPixel(10, 10, gold);
  drawPixel(9, 11, gold);

  // Fletching at back (subtle)
  drawPixel(1, 5, goldFaint);
  drawPixel(2, 6, goldFaint);
  drawPixel(1, 10, goldFaint);
  drawPixel(2, 9, goldFaint);

  // Nock detail
  drawPixel(0, 7, goldVeryFaint);
  drawPixel(0, 8, goldVeryFaint);

  return image;
}
