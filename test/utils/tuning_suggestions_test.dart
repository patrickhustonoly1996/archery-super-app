import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/tuning_suggestions.dart';
import 'package:archery_super_app/models/tuning_session.dart';

void main() {
  group('TuningSuggestions', () {
    group('getSuggestionsForPaperTune', () {
      group('clean tear', () {
        test('returns perfect message for clean tear with recurve', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: TearDirection.clean,
            size: TearSize.small,
          );

          expect(suggestions, hasLength(1));
          expect(suggestions.first, contains('Perfect'));
          expect(suggestions.first, contains('No adjustment needed'));
        });

        test('returns perfect message for clean tear with compound', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.compound,
            direction: TearDirection.clean,
            size: TearSize.medium,
          );

          expect(suggestions, hasLength(1));
          expect(suggestions.first, contains('Perfect'));
        });

        test('returns perfect message regardless of size for clean tear', () {
          for (final size in [TearSize.small, TearSize.medium, TearSize.large]) {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.clean,
              size: size,
            );

            expect(suggestions, hasLength(1));
            expect(suggestions.first, contains('Perfect'));
          }
        });
      });

      group('severity prefix', () {
        test('uses Slight prefix for small tears', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: TearDirection.up,
            size: TearSize.small,
          );

          expect(suggestions.first, contains('Slight'));
        });

        test('uses Moderate prefix for medium tears', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: TearDirection.up,
            size: TearSize.medium,
          );

          expect(suggestions.first, contains('Moderate'));
        });

        test('uses Significant prefix for large tears', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: TearDirection.up,
            size: TearSize.large,
          );

          expect(suggestions.first, contains('Significant'));
        });

        test('uses Moderate prefix for unknown tear size', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: TearDirection.up,
            size: 'unknown_size',
          );

          expect(suggestions.first, contains('Moderate'));
        });
      });

      group('recurve suggestions', () {
        group('up tear', () {
          test('returns correct suggestions for up tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.up,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(3));
            expect(suggestions[0], contains('high tear detected'));
            expect(suggestions[1], contains('Lower nocking point'));
            expect(suggestions[1], contains('move down'));
            expect(suggestions[2], contains('tiller'));
            expect(suggestions[2], contains('reduce top limb'));
          });
        });

        group('down tear', () {
          test('returns correct suggestions for down tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.down,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(3));
            expect(suggestions[0], contains('low tear detected'));
            expect(suggestions[1], contains('Raise nocking point'));
            expect(suggestions[1], contains('move up'));
            expect(suggestions[2], contains('tiller'));
            expect(suggestions[2], contains('reduce bottom limb'));
          });
        });

        group('left tear', () {
          test('returns correct suggestions for left tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.left,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('left tear detected'));
            expect(suggestions[1], contains('button/plunger OUT'));
            expect(suggestions[1], contains('away from riser'));
            expect(suggestions[2], contains('Reduce plunger tension'));
            expect(suggestions[3], contains('spine'));
            expect(suggestions[3], contains('too weak'));
          });
        });

        group('right tear', () {
          test('returns correct suggestions for right tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.right,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('right tear detected'));
            expect(suggestions[1], contains('button/plunger IN'));
            expect(suggestions[1], contains('toward riser'));
            expect(suggestions[2], contains('Increase plunger tension'));
            expect(suggestions[3], contains('spine'));
            expect(suggestions[3], contains('too stiff'));
          });
        });

        group('up-left tear', () {
          test('returns correct suggestions for up-left tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.upLeft,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('up-left tear detected'));
            expect(suggestions[1], contains('Lower nocking point'));
            expect(suggestions[2], contains('button/plunger OUT'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });

        group('up-right tear', () {
          test('returns correct suggestions for up-right tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.upRight,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('up-right tear detected'));
            expect(suggestions[1], contains('Lower nocking point'));
            expect(suggestions[2], contains('button/plunger IN'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });

        group('down-left tear', () {
          test('returns correct suggestions for down-left tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.downLeft,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('down-left tear detected'));
            expect(suggestions[1], contains('Raise nocking point'));
            expect(suggestions[2], contains('button/plunger OUT'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });

        group('down-right tear', () {
          test('returns correct suggestions for down-right tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.recurve,
              direction: TearDirection.downRight,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('down-right tear detected'));
            expect(suggestions[1], contains('Raise nocking point'));
            expect(suggestions[2], contains('button/plunger IN'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });
      });

      group('compound suggestions', () {
        group('up tear', () {
          test('returns correct suggestions for up tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.up,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('high tear detected'));
            expect(suggestions[1], contains('Lower nocking point'));
            expect(suggestions[1], contains('D-loop'));
            expect(suggestions[2], contains('cam timing'));
            expect(suggestions[2], contains('bottom cam'));
            expect(suggestions[3], contains('rest down'));
          });
        });

        group('down tear', () {
          test('returns correct suggestions for down tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.down,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('low tear detected'));
            expect(suggestions[1], contains('Raise nocking point'));
            expect(suggestions[1], contains('D-loop'));
            expect(suggestions[2], contains('cam timing'));
            expect(suggestions[2], contains('top cam'));
            expect(suggestions[3], contains('rest up'));
          });
        });

        group('left tear', () {
          test('returns correct suggestions for left tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.left,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('left tear detected'));
            expect(suggestions[1], contains('Move rest OUT'));
            expect(suggestions[1], contains('away from riser'));
            expect(suggestions[2], contains('spine'));
            expect(suggestions[2], contains('too weak'));
            expect(suggestions[3], contains('cam timing'));
          });
        });

        group('right tear', () {
          test('returns correct suggestions for right tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.right,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('right tear detected'));
            expect(suggestions[1], contains('Move rest IN'));
            expect(suggestions[1], contains('toward riser'));
            expect(suggestions[2], contains('spine'));
            expect(suggestions[2], contains('too stiff'));
            expect(suggestions[3], contains('cam timing'));
          });
        });

        group('up-left tear', () {
          test('returns correct suggestions for up-left tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.upLeft,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('up-left tear detected'));
            expect(suggestions[1], contains('Lower nocking point'));
            expect(suggestions[1], contains('D-loop'));
            expect(suggestions[2], contains('Move rest OUT'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });

        group('up-right tear', () {
          test('returns correct suggestions for up-right tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.upRight,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('up-right tear detected'));
            expect(suggestions[1], contains('Lower nocking point'));
            expect(suggestions[1], contains('D-loop'));
            expect(suggestions[2], contains('Move rest IN'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });

        group('down-left tear', () {
          test('returns correct suggestions for down-left tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.downLeft,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('down-left tear detected'));
            expect(suggestions[1], contains('Raise nocking point'));
            expect(suggestions[1], contains('D-loop'));
            expect(suggestions[2], contains('Move rest OUT'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });

        group('down-right tear', () {
          test('returns correct suggestions for down-right tear', () {
            final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
              bowType: BowType.compound,
              direction: TearDirection.downRight,
              size: TearSize.medium,
            );

            expect(suggestions, hasLength(4));
            expect(suggestions[0], contains('down-right tear detected'));
            expect(suggestions[1], contains('Raise nocking point'));
            expect(suggestions[1], contains('D-loop'));
            expect(suggestions[2], contains('Move rest IN'));
            expect(suggestions[3], contains('Address vertical first'));
          });
        });
      });

      group('all directions and sizes combinations', () {
        final directions = [
          TearDirection.up,
          TearDirection.down,
          TearDirection.left,
          TearDirection.right,
          TearDirection.upLeft,
          TearDirection.upRight,
          TearDirection.downLeft,
          TearDirection.downRight,
        ];

        final sizes = [TearSize.small, TearSize.medium, TearSize.large];

        test('recurve returns non-empty suggestions for all non-clean combinations', () {
          for (final direction in directions) {
            for (final size in sizes) {
              final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
                bowType: BowType.recurve,
                direction: direction,
                size: size,
              );

              expect(
                suggestions,
                isNotEmpty,
                reason: 'Expected suggestions for recurve $direction $size',
              );
            }
          }
        });

        test('compound returns non-empty suggestions for all non-clean combinations', () {
          for (final direction in directions) {
            for (final size in sizes) {
              final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
                bowType: BowType.compound,
                direction: direction,
                size: size,
              );

              expect(
                suggestions,
                isNotEmpty,
                reason: 'Expected suggestions for compound $direction $size',
              );
            }
          }
        });
      });

      group('edge cases', () {
        test('handles unknown bow type by treating as compound', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: 'longbow',
            direction: TearDirection.up,
            size: TearSize.medium,
          );

          // Should use compound suggestions (default case)
          expect(suggestions, isNotEmpty);
          expect(suggestions[1], contains('D-loop'));
        });

        test('handles unknown direction gracefully', () {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: 'diagonal',
            size: TearSize.medium,
          );

          // Unknown direction returns empty list (no switch case matches)
          expect(suggestions, isEmpty);
        });
      });
    });

    group('getGeneralTips', () {
      group('paper tune tips', () {
        test('returns paper tune tips for recurve', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.paperTune,
            BowType.recurve,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('6-8 feet'));
          expect(tips[1], contains('same arrow'));
          expect(tips[2], contains('multiple shots'));
          expect(tips[3], contains('small adjustments'));
          expect(tips[3], contains('1-2mm'));
        });

        test('returns paper tune tips for compound', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.paperTune,
            BowType.compound,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('6-8 feet'));
        });
      });

      group('bare shaft tips', () {
        test('returns bare shaft tips for recurve', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.bareShaft,
            BowType.recurve,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('18m'));
          expect(tips[1], contains('group'));
          expect(tips[2], contains('left/right'));
          expect(tips[2], contains('button/rest'));
          expect(tips[3], contains('high/low'));
          expect(tips[3], contains('nocking point'));
        });

        test('returns bare shaft tips for compound', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.bareShaft,
            BowType.compound,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('18m'));
        });
      });

      group('walk-back tips', () {
        test('returns walk-back tips for recurve', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.walkBack,
            BowType.recurve,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('10m'));
          expect(tips[0], contains('30m'));
          expect(tips[0], contains('50m'));
          expect(tips[0], contains('70m'));
          expect(tips[1], contains('group vertically'));
          expect(tips[2], contains('drift left'));
          expect(tips[2], contains('button OUT'));
          expect(tips[3], contains('drift right'));
          expect(tips[3], contains('button IN'));
        });

        test('returns empty tips for walk-back with compound', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.walkBack,
            BowType.compound,
          );

          // Walk-back is recurve-specific
          expect(tips, isEmpty);
        });
      });

      group('french tune tips', () {
        test('returns french tune tips for compound', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.frenchTune,
            BowType.compound,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('fletched arrow'));
          expect(tips[0], contains('bare shaft'));
          expect(tips[1], contains('same location'));
          expect(tips[2], contains('rest left/right'));
          expect(tips[3], contains('nocking point'));
        });

        test('returns empty tips for french tune with recurve', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.frenchTune,
            BowType.recurve,
          );

          // French tune is compound-specific
          expect(tips, isEmpty);
        });
      });

      group('brace height tips', () {
        test('returns brace height tips for recurve', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.braceHeight,
            BowType.recurve,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('215-230mm'));
          expect(tips[1], contains('quieter'));
          expect(tips[1], contains('faster'));
          expect(tips[2], contains('pivot point'));
          expect(tips[3], contains('manufacturer'));
        });

        test('returns brace height tips for compound', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.braceHeight,
            BowType.compound,
          );

          // Brace height tips apply to both bow types
          expect(tips, hasLength(4));
        });
      });

      group('tiller tips', () {
        test('returns tiller tips for recurve', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.tiller,
            BowType.recurve,
          );

          expect(tips, hasLength(4));
          expect(tips[0], contains('limb pocket'));
          expect(tips[1], contains('Positive tiller'));
          expect(tips[2], contains('+2 to +6mm'));
          expect(tips[3], contains('limb bolts'));
        });

        test('returns tiller tips for compound', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.tiller,
            BowType.compound,
          );

          // Tiller tips apply to both bow types
          expect(tips, hasLength(4));
        });
      });

      group('edge cases', () {
        test('returns empty tips for unknown tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            'unknown_tuning_type',
            BowType.recurve,
          );

          expect(tips, isEmpty);
        });

        test('handles nock point tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.nockPoint,
            BowType.recurve,
          );

          // nockPoint is not in the switch cases
          expect(tips, isEmpty);
        });

        test('handles centershot tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.centershot,
            BowType.recurve,
          );

          // centershot is not in the switch cases
          expect(tips, isEmpty);
        });

        test('handles plunger tension tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.plungerTension,
            BowType.recurve,
          );

          // plungerTension is not in the switch cases
          expect(tips, isEmpty);
        });

        test('handles cam timing tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.camTiming,
            BowType.compound,
          );

          // camTiming is not in the switch cases
          expect(tips, isEmpty);
        });

        test('handles yoke tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.yokeTuning,
            BowType.compound,
          );

          // yokeTuning is not in the switch cases
          expect(tips, isEmpty);
        });

        test('handles rest position tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.restPosition,
            BowType.compound,
          );

          // restPosition is not in the switch cases
          expect(tips, isEmpty);
        });

        test('handles peep height tuning type', () {
          final tips = TuningSuggestions.getGeneralTips(
            TuningType.peepHeight,
            BowType.compound,
          );

          // peepHeight is not in the switch cases
          expect(tips, isEmpty);
        });
      });
    });

    group('archery knowledge accuracy', () {
      test('recurve left tear correctly identifies weak spine', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.recurve,
          direction: TearDirection.left,
          size: TearSize.medium,
        );

        // For right-handed recurve archer, left tear indicates weak spine
        expect(suggestions.any((s) => s.contains('too weak')), isTrue);
      });

      test('recurve right tear correctly identifies stiff spine', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.recurve,
          direction: TearDirection.right,
          size: TearSize.medium,
        );

        // For right-handed recurve archer, right tear indicates stiff spine
        expect(suggestions.any((s) => s.contains('too stiff')), isTrue);
      });

      test('compound left tear correctly identifies weak spine', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.compound,
          direction: TearDirection.left,
          size: TearSize.medium,
        );

        // For compound, left tear indicates weak spine
        expect(suggestions.any((s) => s.contains('too weak')), isTrue);
      });

      test('compound right tear correctly identifies stiff spine', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.compound,
          direction: TearDirection.right,
          size: TearSize.medium,
        );

        // For compound, right tear indicates stiff spine
        expect(suggestions.any((s) => s.contains('too stiff')), isTrue);
      });

      test('diagonal tears recommend fixing vertical first', () {
        final diagonalDirections = [
          TearDirection.upLeft,
          TearDirection.upRight,
          TearDirection.downLeft,
          TearDirection.downRight,
        ];

        for (final direction in diagonalDirections) {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: direction,
            size: TearSize.medium,
          );

          expect(
            suggestions.any((s) => s.contains('Address vertical first')),
            isTrue,
            reason: 'Diagonal tear $direction should recommend vertical first',
          );
        }
      });

      test('recurve uses button/plunger terminology', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.recurve,
          direction: TearDirection.left,
          size: TearSize.medium,
        );

        expect(suggestions.any((s) => s.contains('button/plunger')), isTrue);
      });

      test('compound uses rest terminology', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.compound,
          direction: TearDirection.left,
          size: TearSize.medium,
        );

        expect(suggestions.any((s) => s.contains('rest')), isTrue);
      });

      test('compound mentions D-loop for vertical adjustments', () {
        final verticalDirections = [
          TearDirection.up,
          TearDirection.down,
          TearDirection.upLeft,
          TearDirection.upRight,
          TearDirection.downLeft,
          TearDirection.downRight,
        ];

        for (final direction in verticalDirections) {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.compound,
            direction: direction,
            size: TearSize.medium,
          );

          expect(
            suggestions.any((s) => s.contains('D-loop')),
            isTrue,
            reason: 'Compound vertical tear $direction should mention D-loop',
          );
        }
      });

      test('compound mentions cam timing', () {
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.compound,
          direction: TearDirection.up,
          size: TearSize.medium,
        );

        expect(suggestions.any((s) => s.contains('cam timing')), isTrue);
      });

      test('recurve mentions tiller for vertical tears', () {
        final verticalDirections = [TearDirection.up, TearDirection.down];

        for (final direction in verticalDirections) {
          final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
            bowType: BowType.recurve,
            direction: direction,
            size: TearSize.medium,
          );

          expect(
            suggestions.any((s) => s.contains('tiller')),
            isTrue,
            reason: 'Recurve vertical tear $direction should mention tiller',
          );
        }
      });

      test('paper tune distance is correct', () {
        final tips = TuningSuggestions.getGeneralTips(
          TuningType.paperTune,
          BowType.recurve,
        );

        // Standard paper tune distance is 6-8 feet
        expect(tips.any((t) => t.contains('6-8 feet')), isTrue);
      });

      test('bare shaft distance is correct', () {
        final tips = TuningSuggestions.getGeneralTips(
          TuningType.bareShaft,
          BowType.recurve,
        );

        // Standard bare shaft tuning is done at 18m
        expect(tips.any((t) => t.contains('18m')), isTrue);
      });

      test('recurve brace height range is correct', () {
        final tips = TuningSuggestions.getGeneralTips(
          TuningType.braceHeight,
          BowType.recurve,
        );

        // Typical recurve brace height is 215-230mm
        expect(tips.any((t) => t.contains('215-230mm')), isTrue);
      });

      test('recurve tiller range is correct', () {
        final tips = TuningSuggestions.getGeneralTips(
          TuningType.tiller,
          BowType.recurve,
        );

        // Typical recurve positive tiller is +2 to +6mm
        expect(tips.any((t) => t.contains('+2 to +6mm')), isTrue);
      });
    });

    group('Olympic archer scenarios', () {
      test('provides correct advice for typical recurve paper tune issue', () {
        // Scenario: Olympic recurve archer has slight right tear at 70m
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.recurve,
          direction: TearDirection.right,
          size: TearSize.small,
        );

        expect(suggestions[0], contains('Slight'));
        expect(suggestions.any((s) => s.contains('plunger IN')), isTrue);
        expect(suggestions.any((s) => s.contains('Increase plunger tension')), isTrue);
      });

      test('provides correct advice for significant compound tear', () {
        // Scenario: Compound archer has significant down-left tear
        final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
          bowType: BowType.compound,
          direction: TearDirection.downLeft,
          size: TearSize.large,
        );

        expect(suggestions[0], contains('Significant'));
        expect(suggestions.any((s) => s.contains('Raise nocking point')), isTrue);
        expect(suggestions.any((s) => s.contains('rest OUT')), isTrue);
        expect(suggestions.any((s) => s.contains('vertical first')), isTrue);
      });

      test('provides walk-back tuning guidance for recurve', () {
        final tips = TuningSuggestions.getGeneralTips(
          TuningType.walkBack,
          BowType.recurve,
        );

        // Walk-back should test at multiple distances for Olympic rounds
        expect(tips.any((t) => t.contains('70m')), isTrue);
        expect(tips.any((t) => t.contains('group vertically')), isTrue);
      });

      test('provides correct bare shaft guidance', () {
        final tips = TuningSuggestions.getGeneralTips(
          TuningType.bareShaft,
          BowType.recurve,
        );

        expect(tips.any((t) => t.contains('fletched and bare shafts')), isTrue);
        expect(tips.any((t) => t.contains('group')), isTrue);
      });
    });
  });
}
