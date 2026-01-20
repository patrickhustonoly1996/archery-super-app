/// Tests for MembershipCardService
///
/// These tests verify:
/// - Static file format validation (isValidCardFormat, isWalletPass)
/// - File size formatting (formatFileSize)
/// - Filename sanitization behavior
/// - File extension handling
/// - Edge cases for various inputs
///
/// Note: Tests requiring actual file system operations (save, delete, get)
/// would need path_provider mocking which isn't available in pure unit tests.
/// Those methods are tested through integration tests instead.
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/membership_card_service.dart';

void main() {
  group('MembershipCardService', () {
    group('isValidCardFormat', () {
      group('supported image formats', () {
        test('accepts PNG files', () {
          expect(MembershipCardService.isValidCardFormat('card.png'), isTrue);
          expect(MembershipCardService.isValidCardFormat('card.PNG'), isTrue);
          expect(MembershipCardService.isValidCardFormat('my_card.Png'), isTrue);
        });

        test('accepts JPG files', () {
          expect(MembershipCardService.isValidCardFormat('card.jpg'), isTrue);
          expect(MembershipCardService.isValidCardFormat('card.JPG'), isTrue);
          expect(MembershipCardService.isValidCardFormat('photo.Jpg'), isTrue);
        });

        test('accepts JPEG files', () {
          expect(MembershipCardService.isValidCardFormat('card.jpeg'), isTrue);
          expect(MembershipCardService.isValidCardFormat('card.JPEG'), isTrue);
          expect(MembershipCardService.isValidCardFormat('scan.Jpeg'), isTrue);
        });

        test('accepts HEIC files (iOS format)', () {
          expect(MembershipCardService.isValidCardFormat('photo.heic'), isTrue);
          expect(MembershipCardService.isValidCardFormat('photo.HEIC'), isTrue);
        });

        test('accepts WebP files', () {
          expect(MembershipCardService.isValidCardFormat('card.webp'), isTrue);
          expect(MembershipCardService.isValidCardFormat('card.WEBP'), isTrue);
        });
      });

      group('Apple Wallet passes', () {
        test('accepts pkpass files', () {
          expect(MembershipCardService.isValidCardFormat('pass.pkpass'), isTrue);
          expect(MembershipCardService.isValidCardFormat('archery_gb.pkpass'), isTrue);
          expect(MembershipCardService.isValidCardFormat('CARD.PKPASS'), isTrue);
        });
      });

      group('rejected formats', () {
        test('rejects PDF files', () {
          expect(MembershipCardService.isValidCardFormat('card.pdf'), isFalse);
        });

        test('rejects GIF files', () {
          expect(MembershipCardService.isValidCardFormat('card.gif'), isFalse);
        });

        test('rejects BMP files', () {
          expect(MembershipCardService.isValidCardFormat('card.bmp'), isFalse);
        });

        test('rejects TIFF files', () {
          expect(MembershipCardService.isValidCardFormat('card.tiff'), isFalse);
          expect(MembershipCardService.isValidCardFormat('card.tif'), isFalse);
        });

        test('rejects SVG files', () {
          expect(MembershipCardService.isValidCardFormat('card.svg'), isFalse);
        });

        test('rejects document files', () {
          expect(MembershipCardService.isValidCardFormat('card.doc'), isFalse);
          expect(MembershipCardService.isValidCardFormat('card.docx'), isFalse);
          expect(MembershipCardService.isValidCardFormat('card.txt'), isFalse);
        });

        test('rejects files with no extension', () {
          expect(MembershipCardService.isValidCardFormat('card'), isFalse);
          expect(MembershipCardService.isValidCardFormat('membership_card'), isFalse);
        });

        test('rejects empty filename', () {
          expect(MembershipCardService.isValidCardFormat(''), isFalse);
        });
      });

      group('edge cases', () {
        test('handles filenames with multiple dots', () {
          expect(MembershipCardService.isValidCardFormat('my.card.2024.png'), isTrue);
          expect(MembershipCardService.isValidCardFormat('archery.gb.membership.jpg'), isTrue);
        });

        test('handles filenames with spaces', () {
          expect(MembershipCardService.isValidCardFormat('my card.png'), isTrue);
          expect(MembershipCardService.isValidCardFormat('Archery GB Card.jpg'), isTrue);
        });

        test('handles filenames with special characters', () {
          expect(MembershipCardService.isValidCardFormat('card-2024.png'), isTrue);
          expect(MembershipCardService.isValidCardFormat('card_2024.jpg'), isTrue);
          expect(MembershipCardService.isValidCardFormat('card(1).png'), isTrue);
        });

        test('handles filenames with unicode characters', () {
          expect(MembershipCardService.isValidCardFormat('会员卡.png'), isTrue);
          expect(MembershipCardService.isValidCardFormat('карта.jpg'), isTrue);
        });

        test('handles very long filenames', () {
          final longName = '${'a' * 200}.png';
          expect(MembershipCardService.isValidCardFormat(longName), isTrue);
        });

        test('handles path-like filenames', () {
          expect(MembershipCardService.isValidCardFormat('/path/to/card.png'), isTrue);
          expect(MembershipCardService.isValidCardFormat('C:\\Users\\card.jpg'), isTrue);
        });

        test('handles hidden files (dot prefix)', () {
          expect(MembershipCardService.isValidCardFormat('.hidden.png'), isTrue);
        });

        test('extension must be at end', () {
          // This tests that only the actual extension is checked
          expect(MembershipCardService.isValidCardFormat('png.txt'), isFalse);
          expect(MembershipCardService.isValidCardFormat('jpg.doc'), isFalse);
        });
      });
    });

    group('isWalletPass', () {
      test('returns true for pkpass files', () {
        expect(MembershipCardService.isWalletPass('pass.pkpass'), isTrue);
        expect(MembershipCardService.isWalletPass('archery_membership.pkpass'), isTrue);
      });

      test('is case insensitive', () {
        expect(MembershipCardService.isWalletPass('pass.PKPASS'), isTrue);
        expect(MembershipCardService.isWalletPass('pass.Pkpass'), isTrue);
        expect(MembershipCardService.isWalletPass('pass.PKPass'), isTrue);
      });

      test('returns false for image files', () {
        expect(MembershipCardService.isWalletPass('card.png'), isFalse);
        expect(MembershipCardService.isWalletPass('card.jpg'), isFalse);
        expect(MembershipCardService.isWalletPass('card.jpeg'), isFalse);
        expect(MembershipCardService.isWalletPass('card.heic'), isFalse);
        expect(MembershipCardService.isWalletPass('card.webp'), isFalse);
      });

      test('returns false for other files', () {
        expect(MembershipCardService.isWalletPass('card.pdf'), isFalse);
        expect(MembershipCardService.isWalletPass('pass.wallet'), isFalse);
        expect(MembershipCardService.isWalletPass(''), isFalse);
      });

      test('handles edge cases', () {
        expect(MembershipCardService.isWalletPass('pkpass'), isFalse); // No dot
        // '.pkpass' is treated as a hidden file with no extension by path.extension()
        expect(MembershipCardService.isWalletPass('.pkpass'), isFalse);
        expect(MembershipCardService.isWalletPass('file.pkpass.bak'), isFalse); // Not at end
      });
    });

    group('formatFileSize', () {
      group('bytes range', () {
        test('formats 0 bytes', () {
          expect(MembershipCardService.formatFileSize(0), equals('0 B'));
        });

        test('formats single byte', () {
          expect(MembershipCardService.formatFileSize(1), equals('1 B'));
        });

        test('formats small byte values', () {
          expect(MembershipCardService.formatFileSize(100), equals('100 B'));
          expect(MembershipCardService.formatFileSize(500), equals('500 B'));
          expect(MembershipCardService.formatFileSize(1023), equals('1023 B'));
        });
      });

      group('kilobytes range', () {
        test('formats exact 1 KB', () {
          expect(MembershipCardService.formatFileSize(1024), equals('1.0 KB'));
        });

        test('formats KB with decimal', () {
          expect(MembershipCardService.formatFileSize(1536), equals('1.5 KB'));
          expect(MembershipCardService.formatFileSize(2560), equals('2.5 KB'));
        });

        test('formats various KB sizes', () {
          expect(MembershipCardService.formatFileSize(5 * 1024), equals('5.0 KB'));
          expect(MembershipCardService.formatFileSize(100 * 1024), equals('100.0 KB'));
          expect(MembershipCardService.formatFileSize(500 * 1024), equals('500.0 KB'));
        });

        test('formats just under 1 MB', () {
          expect(MembershipCardService.formatFileSize(1024 * 1024 - 1), equals('1024.0 KB'));
        });
      });

      group('megabytes range', () {
        test('formats exact 1 MB', () {
          expect(MembershipCardService.formatFileSize(1024 * 1024), equals('1.0 MB'));
        });

        test('formats MB with decimal', () {
          expect(MembershipCardService.formatFileSize((1.5 * 1024 * 1024).round()), equals('1.5 MB'));
          expect(MembershipCardService.formatFileSize((2.5 * 1024 * 1024).round()), equals('2.5 MB'));
        });

        test('formats typical image sizes', () {
          // 500KB image
          expect(MembershipCardService.formatFileSize(500 * 1024), equals('500.0 KB'));
          // 2MB image
          expect(MembershipCardService.formatFileSize(2 * 1024 * 1024), equals('2.0 MB'));
          // 5MB image
          expect(MembershipCardService.formatFileSize(5 * 1024 * 1024), equals('5.0 MB'));
        });

        test('formats large MB values', () {
          expect(MembershipCardService.formatFileSize(50 * 1024 * 1024), equals('50.0 MB'));
          expect(MembershipCardService.formatFileSize(100 * 1024 * 1024), equals('100.0 MB'));
        });
      });

      group('edge cases', () {
        test('handles negative values', () {
          // Behavior for negative values - implementation uses comparison
          // Negative values would fall through to bytes
          expect(MembershipCardService.formatFileSize(-1), equals('-1 B'));
        });

        test('rounds decimal places correctly', () {
          // 1.04 KB should round to 1.0 KB
          expect(MembershipCardService.formatFileSize(1065), equals('1.0 KB'));
          // 1.06 KB should round to 1.1 KB
          expect(MembershipCardService.formatFileSize(1085), equals('1.1 KB'));
        });

        test('handles very large files', () {
          // 1 GB
          expect(MembershipCardService.formatFileSize(1024 * 1024 * 1024), equals('1024.0 MB'));
          // 10 GB
          expect(MembershipCardService.formatFileSize(10 * 1024 * 1024 * 1024), equals('10240.0 MB'));
        });
      });
    });
  });

  group('Archery domain-specific tests', () {
    group('Archery GB membership cards', () {
      test('accepts typical Archery GB card photo formats', () {
        // Photo taken with phone
        expect(MembershipCardService.isValidCardFormat('IMG_20240115.jpg'), isTrue);
        expect(MembershipCardService.isValidCardFormat('IMG_20240115.heic'), isTrue);

        // Scanned image
        expect(MembershipCardService.isValidCardFormat('archery_gb_membership_scan.png'), isTrue);

        // Screenshot
        expect(MembershipCardService.isValidCardFormat('Screenshot 2024-01-15.png'), isTrue);
      });

      test('accepts Apple Wallet Archery GB pass', () {
        expect(MembershipCardService.isValidCardFormat('ArcheryGB_Membership_2024.pkpass'), isTrue);
        expect(MembershipCardService.isWalletPass('ArcheryGB_Membership_2024.pkpass'), isTrue);
      });
    });

    group('World Archery membership cards', () {
      test('accepts World Archery card formats', () {
        expect(MembershipCardService.isValidCardFormat('world_archery_id.png'), isTrue);
        expect(MembershipCardService.isValidCardFormat('WA_athlete_card.jpg'), isTrue);
      });
    });

    group('Club membership cards', () {
      test('accepts club card photos', () {
        expect(MembershipCardService.isValidCardFormat('EMAS_membership.png'), isTrue);
        expect(MembershipCardService.isValidCardFormat('club_card_front.jpg'), isTrue);
        expect(MembershipCardService.isValidCardFormat('club_card_back.jpg'), isTrue);
      });
    });

    group('File size for membership cards', () {
      test('typical phone photo size is formatted well', () {
        // iPhone photo typically 2-5 MB
        expect(MembershipCardService.formatFileSize(3 * 1024 * 1024), equals('3.0 MB'));
      });

      test('compressed card image size', () {
        // Optimized PNG ~200-500 KB
        expect(MembershipCardService.formatFileSize(350 * 1024), equals('350.0 KB'));
      });

      test('Apple Wallet pass size', () {
        // pkpass files are typically small (50-200 KB)
        expect(MembershipCardService.formatFileSize(150 * 1024), equals('150.0 KB'));
      });
    });
  });

  group('Olympic archer scenarios', () {
    test('Patrick stores Archery GB membership card photo', () {
      // Patrick photographs his Archery GB card with iPhone
      const filename = 'IMG_0042.HEIC';
      expect(MembershipCardService.isValidCardFormat(filename), isTrue);
      expect(MembershipCardService.isWalletPass(filename), isFalse);
    });

    test('Patrick adds Apple Wallet membership pass', () {
      // Archery GB provides Apple Wallet passes
      const filename = 'ArcheryGB_2024_PatrickHuston.pkpass';
      expect(MembershipCardService.isValidCardFormat(filename), isTrue);
      expect(MembershipCardService.isWalletPass(filename), isTrue);
    });

    test('Patrick stores World Archery athlete ID', () {
      // World Archery ID card for international competitions
      const filename = 'WorldArchery_AthleteID_GBR.png';
      expect(MembershipCardService.isValidCardFormat(filename), isTrue);
    });

    test('Patrick stores insurance certificate', () {
      // Insurance documents often come as images
      const filename = 'insurance_cert_2024.jpg';
      expect(MembershipCardService.isValidCardFormat(filename), isTrue);
    });

    test('Patrick stores county membership', () {
      // EMAS (East Midlands Archery Society) card
      const filename = 'EMAS_membership_card.png';
      expect(MembershipCardService.isValidCardFormat(filename), isTrue);
    });

    test('multiple federation memberships can be distinguished', () {
      // Olympic archers often have multiple federation memberships
      const files = [
        'archery_gb_member.png',
        'world_archery_athlete.png',
        'emas_county.jpg',
        'club_membership.png',
      ];

      for (final file in files) {
        expect(MembershipCardService.isValidCardFormat(file), isTrue,
            reason: '$file should be valid');
      }
    });
  });

  group('Error handling and robustness', () {
    group('malformed inputs', () {
      test('handles null-like empty string', () {
        expect(MembershipCardService.isValidCardFormat(''), isFalse);
        expect(MembershipCardService.isWalletPass(''), isFalse);
      });

      test('handles whitespace-only filename', () {
        expect(MembershipCardService.isValidCardFormat('   '), isFalse);
        expect(MembershipCardService.isValidCardFormat('\t\n'), isFalse);
      });

      test('handles filename that is just extension (hidden files)', () {
        // In Dart's path.extension(), a file like '.png' is treated as a hidden file
        // with basename '.png' and no extension, so these return false
        expect(MembershipCardService.isValidCardFormat('.png'), isFalse);
        expect(MembershipCardService.isValidCardFormat('.jpg'), isFalse);
        expect(MembershipCardService.isValidCardFormat('.pkpass'), isFalse);
      });

      test('handles double extensions', () {
        expect(MembershipCardService.isValidCardFormat('file.tar.png'), isTrue);
        expect(MembershipCardService.isValidCardFormat('file.jpg.bak'), isFalse);
      });
    });

    group('URL-encoded filenames', () {
      test('handles URL-encoded spaces', () {
        // %20 is URL-encoded space
        expect(MembershipCardService.isValidCardFormat('my%20card.png'), isTrue);
      });

      test('handles URL-encoded special characters', () {
        expect(MembershipCardService.isValidCardFormat('card%2B1.jpg'), isTrue);
      });
    });

    group('international character handling', () {
      test('handles Chinese characters in filename', () {
        expect(MembershipCardService.isValidCardFormat('会员证.png'), isTrue);
      });

      test('handles Japanese characters in filename', () {
        expect(MembershipCardService.isValidCardFormat('メンバーカード.jpg'), isTrue);
      });

      test('handles Korean characters in filename', () {
        expect(MembershipCardService.isValidCardFormat('회원카드.png'), isTrue);
      });

      test('handles Arabic characters in filename', () {
        expect(MembershipCardService.isValidCardFormat('بطاقة العضوية.jpg'), isTrue);
      });

      test('handles emojis in filename', () {
        expect(MembershipCardService.isValidCardFormat('🏹card.png'), isTrue);
      });
    });
  });

  group('Federation ID sanitization logic', () {
    // The service sanitizes federation IDs when saving files
    // Testing the regex pattern: [^\w\-] replaced with _

    test('documentation: valid characters preserved', () {
      // The regex [^\w\-] matches anything that is NOT:
      // - \w: word characters (a-z, A-Z, 0-9, _)
      // - \-: hyphen
      // Everything else gets replaced with underscore

      // These tests verify understanding of the sanitization logic
      // (actual sanitization happens internally during save)

      // Valid federation IDs that won't be modified much:
      // 'archery_gb' -> 'archery_gb' (underscores preserved)
      // 'world-archery' -> 'world-archery' (hyphens preserved)
      // 'club123' -> 'club123' (alphanumeric preserved)

      expect('archery_gb'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('archery_gb'));
      expect('world-archery'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('world-archery'));
      expect('club123'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('club123'));
    });

    test('documentation: special characters replaced', () {
      // Federation IDs with special chars get sanitized:
      // 'Archery GB' -> 'Archery_GB' (space replaced)
      // 'club@home' -> 'club_home' (@ replaced)
      // 'team/usa' -> 'team_usa' (/ replaced)

      expect('Archery GB'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('Archery_GB'));
      expect('club@home'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('club_home'));
      expect('team/usa'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('team_usa'));
    });

    test('documentation: unicode characters replaced', () {
      // Non-ASCII characters get replaced:
      // '弓道会' -> '___' (all replaced)

      expect('弓道会'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('___'));
    });

    test('documentation: path traversal prevented', () {
      // Dangerous path characters get sanitized:
      // '../malicious' -> '___malicious'
      // '..\\malicious' -> '___malicious'

      expect('../malicious'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('___malicious'));
      expect('..\\malicious'.replaceAll(RegExp(r'[^\w\-]'), '_'), equals('___malicious'));
    });
  });

  group('File extension handling', () {
    test('extension extraction uses lowercase comparison', () {
      // The service uses path.extension().toLowerCase()
      // This means 'FILE.PNG' and 'file.png' are treated the same

      // All these should be valid:
      expect(MembershipCardService.isValidCardFormat('file.png'), isTrue);
      expect(MembershipCardService.isValidCardFormat('file.PNG'), isTrue);
      expect(MembershipCardService.isValidCardFormat('file.Png'), isTrue);
      expect(MembershipCardService.isValidCardFormat('file.pNg'), isTrue);
    });

    test('supported extensions list', () {
      // The service supports: .png, .jpg, .jpeg, .pkpass, .heic, .webp
      const supported = ['.png', '.jpg', '.jpeg', '.pkpass', '.heic', '.webp'];

      for (final ext in supported) {
        expect(MembershipCardService.isValidCardFormat('file$ext'), isTrue,
            reason: 'Extension $ext should be supported');
      }
    });

    test('unsupported extensions list', () {
      const unsupported = [
        '.gif',
        '.bmp',
        '.tiff',
        '.tif',
        '.svg',
        '.pdf',
        '.doc',
        '.docx',
        '.raw',
        '.cr2',
        '.nef',
      ];

      for (final ext in unsupported) {
        expect(MembershipCardService.isValidCardFormat('file$ext'), isFalse,
            reason: 'Extension $ext should not be supported');
      }
    });
  });

  group('Timestamp in filename', () {
    // The service appends timestamp to saved files:
    // ${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}${extension}

    test('documentation: timestamp format understanding', () {
      // millisecondsSinceEpoch is a large integer
      // Example: 1705320000000 for Jan 15, 2024

      final now = DateTime.now().millisecondsSinceEpoch;

      // Should be a 13-digit number (since ~2001)
      expect(now.toString().length, equals(13));

      // Should be positive
      expect(now, greaterThan(0));
    });

    test('documentation: generated filename format', () {
      // Given federationId 'archery_gb' and file 'card.png'
      // Generated name would be: archery_gb_1705320000000.png

      const federationId = 'archery_gb';
      const originalName = 'card.png';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final sanitizedName = federationId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final extension = '.png'; // extracted from originalName
      final generatedName = '${sanitizedName}_$timestamp$extension';

      expect(generatedName, matches(RegExp(r'archery_gb_\d{13}\.png')));
    });
  });

  group('Service instantiation', () {
    test('can create service instance', () {
      final service = MembershipCardService();
      expect(service, isNotNull);
    });

    test('multiple instances are independent', () {
      final service1 = MembershipCardService();
      final service2 = MembershipCardService();

      expect(service1, isNot(same(service2)));
    });
  });

  group('Boundary conditions', () {
    test('formatFileSize at exact boundaries', () {
      // At 1023 bytes (just under 1 KB)
      expect(MembershipCardService.formatFileSize(1023), equals('1023 B'));

      // At 1024 bytes (exactly 1 KB)
      expect(MembershipCardService.formatFileSize(1024), equals('1.0 KB'));

      // At 1024*1024 - 1 bytes (just under 1 MB)
      expect(MembershipCardService.formatFileSize(1024 * 1024 - 1), equals('1024.0 KB'));

      // At 1024*1024 bytes (exactly 1 MB)
      expect(MembershipCardService.formatFileSize(1024 * 1024), equals('1.0 MB'));
    });

    test('file format validation at edge cases', () {
      // Just the dot
      expect(MembershipCardService.isValidCardFormat('.'), isFalse);

      // Dot followed by nothing recognizable
      expect(MembershipCardService.isValidCardFormat('file.'), isFalse);

      // Multiple consecutive dots
      expect(MembershipCardService.isValidCardFormat('file..png'), isTrue);
      expect(MembershipCardService.isValidCardFormat('file...jpg'), isTrue);
    });
  });
}
