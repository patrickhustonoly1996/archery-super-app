// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generate favicon and PWA icons from the pixelated arrow logo.png
/// Converts to gold color and adds gold glow effect
void main() async {
  print('Loading logo.png (pixelated arrow)...');

  final logoFile = File('assets/images/logo.png');
  if (!logoFile.existsSync()) {
    print('Error: assets/images/logo.png not found');
    exit(1);
  }

  final logoBytes = logoFile.readAsBytesSync();
  final logo = img.decodeImage(logoBytes);
  if (logo == null) {
    print('Error: Could not decode logo image');
    exit(1);
  }

  print('Logo loaded: ${logo.width}x${logo.height}');

  // Generate different sizes
  final sizes = [16, 32, 48, 64, 128, 192, 512];

  for (final size in sizes) {
    print('Generating ${size}x${size} icon...');
    final icon = generateIcon(logo, size);

    String filename;
    String path;

    if (size == 32) {
      filename = 'favicon.png';
      path = 'web/$filename';
    } else if (size == 192 || size == 512) {
      filename = 'Icon-$size.png';
      path = 'web/icons/$filename';
    } else {
      filename = 'icon-$size.png';
      path = 'web/icons/$filename';
    }

    // Ensure directory exists
    final dir = Directory(path.substring(0, path.lastIndexOf('/')));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    File(path).writeAsBytesSync(img.encodePng(icon));
    print('  -> $path');
  }

  // Generate maskable icons (with padding for safe zone)
  for (final size in [192, 512]) {
    print('Generating ${size}x${size} maskable icon...');
    final icon = generateMaskableIcon(logo, size);
    final path = 'web/icons/Icon-maskable-$size.png';
    File(path).writeAsBytesSync(img.encodePng(icon));
    print('  -> $path');
  }

  // Also save to assets for consistency
  final favicon32 = generateIcon(logo, 32);
  File('assets/favicon.png').writeAsBytesSync(img.encodePng(favicon32));
  print('  -> assets/favicon.png');

  print('\nDone! All icons generated with gold arrow and glow effect.');
}

/// Generate an icon with gold recolor and glow effect
img.Image generateIcon(img.Image source, int size) {
  // Dark background color
  const bgR = 26;
  const bgG = 26;
  const bgB = 26;

  // Create output image
  final output = img.Image(width: size, height: size);
  img.fill(output, color: img.ColorRgba8(bgR, bgG, bgB, 255));

  // Add padding for the glow
  final padding = (size * 0.15).round();
  final iconSize = size - (padding * 2);

  // Resize the logo to fit
  final resized = img.copyResize(
    source,
    width: iconSize,
    height: iconSize,
    interpolation: img.Interpolation.nearest, // Keep pixelated look
  );

  // Convert to gold and create alpha mask
  final goldArrow = convertToGold(resized);

  // Add gold glow effect first (behind the arrow)
  final glowRadius = (size * 0.12).round().clamp(2, 30);
  addGoldGlow(output, goldArrow, padding, padding, glowRadius: glowRadius);

  // Composite the gold arrow on top
  img.compositeImage(output, goldArrow, dstX: padding, dstY: padding);

  return output;
}

/// Generate maskable icon with extra padding for safe zone
img.Image generateMaskableIcon(img.Image source, int size) {
  const bgR = 26;
  const bgG = 26;
  const bgB = 26;

  final output = img.Image(width: size, height: size);
  img.fill(output, color: img.ColorRgba8(bgR, bgG, bgB, 255));

  // Maskable icons need larger safe zone
  final iconSize = (size * 0.6).round();
  final padding = ((size - iconSize) / 2).round();

  final resized = img.copyResize(
    source,
    width: iconSize,
    height: iconSize,
    interpolation: img.Interpolation.nearest,
  );

  final goldArrow = convertToGold(resized);
  final glowRadius = (size * 0.08).round().clamp(2, 20);
  addGoldGlow(output, goldArrow, padding, padding, glowRadius: glowRadius);
  img.compositeImage(output, goldArrow, dstX: padding, dstY: padding);

  return output;
}

/// Convert image to gold color
/// The source logo is cyan/blue on WHITE background
/// Cyan pixels: low R, high G+B. White pixels: R=G=B=255
img.Image convertToGold(img.Image source) {
  final output = img.Image(width: source.width, height: source.height);

  // Gold color
  const goldR = 255;
  const goldG = 215;
  const goldB = 0;

  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Detect cyan/blue arrow pixels: R is significantly lower than G and B
      // White background has R=G=B≈255
      // Cyan arrow has R<100, G>150, B>200
      final isArrow = r < 200 && (g > 100 || b > 100) && (g + b > r * 2);

      if (isArrow) {
        // This is part of the arrow - make it gold
        // Use the cyan intensity for brightness variation
        final intensity = (g + b) / 500.0; // 0.0 to ~1.0
        final newR = (goldR * intensity).round().clamp(180, 255);
        final newG = (goldG * intensity).round().clamp(150, 215);
        final newB = 0;
        output.setPixel(x, y, img.ColorRgba8(newR, newG, newB, 255));
      } else {
        // Background - make transparent
        output.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      }
    }
  }

  return output;
}

/// Add a subtle gold glow effect around the image
void addGoldGlow(img.Image output, img.Image source, int offsetX, int offsetY, {int glowRadius = 8}) {
  // Gold glow color
  const glowR = 255;
  const glowG = 215;
  const glowB = 0;

  // Build a mask of content pixels first
  final contentMask = <String>{};
  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      if (pixel.a.toInt() > 50) {
        contentMask.add('$x,$y');
      }
    }
  }

  // Only add glow to pixels that are NOT content (edge glow only)
  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final a = pixel.a.toInt();

      if (a > 50) {
        // This pixel has content - add glow only to surrounding empty pixels
        for (int gy = -glowRadius; gy <= glowRadius; gy++) {
          for (int gx = -glowRadius; gx <= glowRadius; gx++) {
            final distance = sqrt(gx * gx + gy * gy);
            if (distance > 0 && distance <= glowRadius) {
              final srcX = x + gx;
              final srcY = y + gy;

              // Skip if this position is part of the content
              if (contentMask.contains('$srcX,$srcY')) continue;

              final outX = offsetX + srcX;
              final outY = offsetY + srcY;

              if (outX >= 0 && outX < output.width && outY >= 0 && outY < output.height) {
                // Glow intensity - subtle falloff
                final intensity = pow(1 - distance / glowRadius, 2.0) * 0.25;

                if (intensity > 0.02) {
                  final existing = output.getPixel(outX, outY);
                  final existingR = existing.r.toInt();
                  final existingG = existing.g.toInt();
                  final existingB = existing.b.toInt();

                  // Blend glow - keep it subtle
                  final newR = (existingR + (glowR - existingR) * intensity).round().clamp(0, 255);
                  final newG = (existingG + (glowG - existingG) * intensity).round().clamp(0, 255);
                  final newB = existingB; // No blue in glow

                  output.setPixel(outX, outY, img.ColorRgba8(newR, newG, newB, 255));
                }
              }
            }
          }
        }
      }
    }
  }
}
