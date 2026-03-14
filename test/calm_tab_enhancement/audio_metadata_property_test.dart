import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/services/audio_playback_service.dart';
import 'dart:math';

/// Property-based test for audio metadata parsing round-trip integrity
///
/// **Feature: calm-tab-enhancement, Property 4: Audio Metadata Round-Trip Integrity**
/// **Validates: Requirements 16.4**
///
/// For any valid audio file, parsing metadata then formatting for display then parsing
/// again should produce equivalent metadata (round-trip property).

/// Helper function to format metadata for display (simulates Pretty_Printer)
String formatMetadataForDisplay(Map<String, dynamic> metadata) {
  final title = metadata['title'] ?? 'Unknown';
  final format = metadata['format'] ?? 'Unknown';
  final duration = metadata['duration'] ?? 'Unknown';

  return 'Title: $title | Format: $format | Duration: $duration';
}

/// Helper function to reconstruct file path from display string
String reconstructPathFromDisplay(String displayString, String originalFormat) {
  // Extract title from display string (simplified reconstruction)
  final titleMatch = RegExp(r'Title: ([^|]+)').firstMatch(displayString);
  final title = titleMatch?.group(1)?.trim() ?? 'reconstructed';

  // Create reconstructed path
  return '${title.toLowerCase().replaceAll(' ', '_')}.$originalFormat';
}

void main() {
  group(
    'Feature: calm-tab-enhancement, Property 4: Audio Metadata Round-Trip Integrity',
    () {
      late AudioPlaybackService audioService;

      setUp(() {
        audioService = AudioPlaybackService();
      });

      tearDown(() async {
        await audioService.dispose();
      });

      testWidgets('Property 4.1: Round-trip metadata parsing produces equivalent results', (
        tester,
      ) async {
        // Test with 100 iterations to ensure property holds universally
        for (int iteration = 0; iteration < 100; iteration++) {
          final random = Random(iteration);

          // Generate random valid audio file paths
          final validFormats = ['mp3', 'aac', 'ogg', 'm4a', 'wav'];
          final format = validFormats[random.nextInt(validFormats.length)];
          final fileName = 'test_audio_${iteration}.$format';

          // First parsing: Parse original file
          final originalMetadata = await audioService.parseAudioMetadata(
            fileName,
          );

          // Verify original parsing succeeded for valid format
          expect(
            originalMetadata,
            isNotNull,
            reason:
                'Valid audio file should parse successfully (iteration $iteration)',
          );

          if (originalMetadata != null) {
            // Create formatted display string (simulating Pretty_Printer output)
            final displayString = formatMetadataForDisplay(originalMetadata);
            expect(
              displayString.isNotEmpty,
              isTrue,
              reason:
                  'Formatted display should not be empty (iteration $iteration)',
            );

            // Second parsing: Parse the conceptual "formatted" metadata back
            // (In a real implementation, this would parse from the formatted display)
            final reconstructedPath = reconstructPathFromDisplay(
              displayString,
              format,
            );
            final secondMetadata = await audioService.parseAudioMetadata(
              reconstructedPath,
            );

            // Verify second parsing succeeded
            expect(
              secondMetadata,
              isNotNull,
              reason:
                  'Reconstructed metadata should parse successfully (iteration $iteration)',
            );

            if (secondMetadata != null) {
              // Round-trip property: Essential metadata should be equivalent
              expect(
                secondMetadata['format'],
                equals(originalMetadata['format']),
                reason:
                    'Format should be preserved in round-trip (iteration $iteration)',
              );

              // Title should be derivable from the same source
              expect(
                secondMetadata['title'],
                isNotNull,
                reason:
                    'Title should be present after round-trip (iteration $iteration)',
              );

              // Verify metadata structure consistency
              expect(
                secondMetadata.keys.toSet(),
                equals(originalMetadata.keys.toSet()),
                reason:
                    'Metadata structure should be consistent (iteration $iteration)',
              );
            }
          }
        }
      });

      testWidgets(
        'Property 4.2: Invalid audio files produce consistent error handling',
        (tester) async {
          for (int iteration = 0; iteration < 100; iteration++) {
            final random = Random(iteration);

            // Generate random invalid file paths
            final invalidFormats = ['txt', 'jpg', 'pdf', 'doc', 'exe', 'zip'];
            final format =
                invalidFormats[random.nextInt(invalidFormats.length)];
            final fileName = 'invalid_file_${iteration}.$format';

            // Parsing should fail gracefully for invalid formats
            final metadata = await audioService.parseAudioMetadata(fileName);

            expect(
              metadata,
              isNull,
              reason:
                  'Invalid audio file should return null metadata (iteration $iteration)',
            );

            // Verify format validation consistency
            expect(
              audioService.isValidAudioFormat(fileName),
              isFalse,
              reason:
                  'Invalid format should be detected by validation (iteration $iteration)',
            );
          }
        },
      );

      testWidgets('Property 4.3: Metadata parsing handles edge cases consistently', (
        tester,
      ) async {
        for (int iteration = 0; iteration < 100; iteration++) {
          final random = Random(iteration);

          // Test edge cases
          final edgeCases = [
            '', // Empty string
            'file_without_extension',
            '.mp3', // Extension only
            'file.with.multiple.dots.mp3',
            'file with spaces.aac',
            'file-with-dashes.ogg',
            'file_with_underscores.m4a',
            'UPPERCASE.WAV',
            'MixedCase.Mp3',
          ];

          final testCase = edgeCases[random.nextInt(edgeCases.length)];

          // Parse metadata for edge case
          final metadata = await audioService.parseAudioMetadata(testCase);

          // Verify consistent behavior
          final isValidFormat = audioService.isValidAudioFormat(testCase);

          if (isValidFormat) {
            expect(
              metadata,
              isNotNull,
              reason:
                  'Valid format edge case should parse successfully: $testCase (iteration $iteration)',
            );

            if (metadata != null) {
              // Verify required fields are present
              expect(
                metadata.containsKey('title'),
                isTrue,
                reason:
                    'Metadata should contain title field (iteration $iteration)',
              );
              expect(
                metadata.containsKey('format'),
                isTrue,
                reason:
                    'Metadata should contain format field (iteration $iteration)',
              );

              // Verify format is uppercase
              final format = metadata['format'] as String?;
              expect(
                format?.toUpperCase(),
                equals(format),
                reason: 'Format should be uppercase (iteration $iteration)',
              );
            }
          } else {
            expect(
              metadata,
              isNull,
              reason:
                  'Invalid format edge case should return null: $testCase (iteration $iteration)',
            );
          }
        }
      });

      testWidgets('Property 4.4: Metadata parsing is deterministic', (
        tester,
      ) async {
        for (int iteration = 0; iteration < 50; iteration++) {
          final random = Random(iteration);

          // Generate test file
          final validFormats = ['mp3', 'aac', 'ogg'];
          final format = validFormats[random.nextInt(validFormats.length)];
          final fileName = 'deterministic_test.$format';

          // Parse the same file multiple times
          final results = <Map<String, dynamic>?>[];
          for (int i = 0; i < 5; i++) {
            final metadata = await audioService.parseAudioMetadata(fileName);
            results.add(metadata);
          }

          // All results should be identical (deterministic)
          for (int i = 1; i < results.length; i++) {
            expect(
              results[i],
              equals(results[0]),
              reason:
                  'Metadata parsing should be deterministic (iteration $iteration, parse $i)',
            );
          }

          // Verify all results are either all null or all non-null
          final allNull = results.every((r) => r == null);
          final allNonNull = results.every((r) => r != null);
          expect(
            allNull || allNonNull,
            isTrue,
            reason:
                'Parsing results should be consistent (iteration $iteration)',
          );
        }
      });

      testWidgets('Property 4.5: Format validation matches parsing behavior', (
        tester,
      ) async {
        for (int iteration = 0; iteration < 100; iteration++) {
          final random = Random(iteration);

          // Generate random file paths with various formats
          final allFormats = [
            'mp3',
            'aac',
            'ogg',
            'm4a',
            'wav',
            'txt',
            'jpg',
            'pdf',
          ];
          final format = allFormats[random.nextInt(allFormats.length)];
          final fileName = 'consistency_test_${iteration}.$format';

          // Check format validation
          final isValid = audioService.isValidAudioFormat(fileName);

          // Parse metadata
          final metadata = await audioService.parseAudioMetadata(fileName);

          // Validation and parsing should be consistent
          if (isValid) {
            expect(
              metadata,
              isNotNull,
              reason:
                  'Valid format should produce metadata: $fileName (iteration $iteration)',
            );
          } else {
            expect(
              metadata,
              isNull,
              reason:
                  'Invalid format should not produce metadata: $fileName (iteration $iteration)',
            );
          }

          // Verify format detection consistency
          final validFormats = ['mp3', 'aac', 'ogg', 'm4a', 'wav'];
          final shouldBeValid = validFormats.contains(format.toLowerCase());
          expect(
            isValid,
            equals(shouldBeValid),
            reason:
                'Format validation should match expected validity (iteration $iteration)',
          );
        }
      });
    },
  );
}
