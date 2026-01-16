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

  // Fill with dark background
  img.fill(image, color: img.ColorRgba8(bgR, bgG, bgB, 255));

  final pixelSize = size / 16;

  // Gold colors at different opacities
  final gold100 = img.ColorRgba8(goldR, goldG, goldB, 255);
  final gold70 = img.ColorRgba8(goldR, goldG, goldB, 178);
  final gold60 = img.ColorRgba8(goldR, goldG, goldB, 153);
  final gold40 = img.ColorRgba8(goldR, goldG, goldB, 102);

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

  // Target in top-right corner - outer ring + center square
  const targetCenterX = 12;
  const targetCenterY = 3;

  // Outer ring
  drawPixel(targetCenterX - 1, targetCenterY - 2, gold40);
  drawPixel(targetCenterX, targetCenterY - 2, gold40);
  drawPixel(targetCenterX + 1, targetCenterY - 1, gold40);
  drawPixel(targetCenterX + 2, targetCenterY, gold40);
  drawPixel(targetCenterX + 1, targetCenterY + 1, gold40);
  drawPixel(targetCenterX, targetCenterY + 2, gold40);
  drawPixel(targetCenterX - 1, targetCenterY + 2, gold40);
  drawPixel(targetCenterX - 2, targetCenterY + 1, gold40);
  drawPixel(targetCenterX - 2, targetCenterY, gold40);
  drawPixel(targetCenterX - 2, targetCenterY - 1, gold40);

  // Center square (2x2)
  drawPixel(targetCenterX - 1, targetCenterY, gold70);
  drawPixel(targetCenterX, targetCenterY, gold70);
  drawPixel(targetCenterX - 1, targetCenterY + 1, gold70);
  drawPixel(targetCenterX, targetCenterY + 1, gold70);

  // Arrow shaft
  for (int x = 2; x <= 12; x++) {
    drawPixel(x, 7, gold100);
    drawPixel(x, 8, gold100);
  }

  // Arrow head - top part
  drawPixel(10, 4, gold100);
  drawPixel(11, 5, gold100);
  drawPixel(12, 6, gold100);
  drawPixel(13, 7, gold100);
  drawPixel(13, 8, gold100);

  // Arrow head - bottom part
  drawPixel(12, 9, gold100);
  drawPixel(11, 10, gold100);
  drawPixel(10, 11, gold100);

  // Fletching at back
  drawPixel(2, 5, gold60);
  drawPixel(3, 6, gold60);
  drawPixel(2, 10, gold60);
  drawPixel(3, 9, gold60);

  return image;
}
