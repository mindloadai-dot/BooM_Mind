import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/services/ultra_audio_controller.dart';

void main() {
  // Fix binding issues for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Assets Validation', () {
    test('manifest.json exists and is valid', () async {
      // Load manifest
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      expect(manifestContent, isNotEmpty,
          reason: 'Manifest file should not be empty');

      // Parse JSON
      final manifestJson = jsonDecode(manifestContent);
      expect(manifestJson, isA<Map<String, dynamic>>(),
          reason: 'Manifest should be valid JSON object');

      // Validate required fields
      expect(manifestJson['tracks'], isA<List>(),
          reason: 'Manifest should contain tracks array');
      expect(manifestJson['defaultOrder'], isA<List>(),
          reason: 'Manifest should contain defaultOrder array');
      expect(manifestJson['metadata'], isA<Map>(),
          reason: 'Manifest should contain metadata object');

      // Validate metadata
      final metadata = manifestJson['metadata'];
      expect(metadata['version'], isNotNull,
          reason: 'Metadata should include version');
      expect(metadata['created'], isNotNull,
          reason: 'Metadata should include creation date');
      expect(metadata['crossfadeSupported'], isA<bool>(),
          reason: 'Metadata should specify crossfade support');
      expect(metadata['loopingSupported'], isA<bool>(),
          reason: 'Metadata should specify looping support');
    });

    test('all tracks in manifest are valid', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      expect(tracks, isNotEmpty,
          reason: 'Manifest should contain at least one track');

      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final trackName = 'Track $i (${track['key']})';

        // Validate required fields
        expect(track['key'], isA<String>(),
            reason: '$trackName should have key field');
        expect(track['filename'], isA<String>(),
            reason: '$trackName should have filename field');
        expect(track['lengthSec'], isA<num>(),
            reason: '$trackName should have lengthSec field');
        expect(track['sampleRate'], isA<int>(),
            reason: '$trackName should have sampleRate field');
        expect(track['channels'], isA<int>(),
            reason: '$trackName should have channels field');
        expect(track['title'], isA<String>(),
            reason: '$trackName should have title field');
        expect(track['description'], isA<String>(),
            reason: '$trackName should have description field');

        // Validate field values
        expect(track['key'], isNotEmpty,
            reason: '$trackName key should not be empty');
        expect(track['filename'], isNotEmpty,
            reason: '$trackName filename should not be empty');
        expect(track['lengthSec'], greaterThan(0),
            reason: '$trackName length should be positive');
        expect(track['channels'], equals(2),
            reason:
                '$trackName must be stereo (2 channels) for binaural beats');
        expect(track['sampleRate'], anyOf([44100, 48000]),
            reason: '$trackName sample rate must be 44.1kHz or 48kHz');
        expect(track['title'], isNotEmpty,
            reason: '$trackName title should not be empty');
        expect(track['description'], isNotEmpty,
            reason: '$trackName description should not be empty');
      }
    });

    test('all audio files exist in assets', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      for (final track in tracks) {
        final filename = track['filename'] as String;
        final assetPath = 'assets/audio/$filename';

        // Try to load the asset
        try {
          final data = await rootBundle.load(assetPath);
          expect(data.lengthInBytes, greaterThan(0),
              reason: 'Audio file $filename should not be empty');
        } catch (e) {
          fail('Audio file $filename not found at $assetPath');
        }
      }
    });

    test('default order references valid tracks', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;
      final defaultOrder = manifestJson['defaultOrder'] as List;

      final trackKeys = tracks.map((t) => t['key'] as String).toSet();

      expect(defaultOrder, isNotEmpty,
          reason: 'Default order should not be empty');

      for (final key in defaultOrder) {
        expect(key, isA<String>(),
            reason: 'Default order should contain string keys');
        expect(trackKeys.contains(key), isTrue,
            reason: 'Default order key "$key" should reference a valid track');
      }
    });

    test('track keys are unique', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      final keys = tracks.map((t) => t['key'] as String).toList();
      final uniqueKeys = keys.toSet();

      expect(keys.length, equals(uniqueKeys.length),
          reason: 'All track keys should be unique');
    });

    test('filenames are unique', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      final filenames = tracks.map((t) => t['filename'] as String).toList();
      final uniqueFilenames = filenames.toSet();

      expect(filenames.length, equals(uniqueFilenames.length),
          reason: 'All track filenames should be unique');
    });

    test('UltraAudioManifest can parse manifest', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);

      // Test the manifest parsing
      expect(() => UltraAudioManifest.fromJson(manifestJson), returnsNormally,
          reason:
              'UltraAudioManifest should parse valid manifest without errors');

      final manifest = UltraAudioManifest.fromJson(manifestJson);

      // Validate parsed manifest
      expect(manifest.tracks, isNotEmpty,
          reason: 'Parsed manifest should have tracks');
      expect(manifest.defaultOrder, isNotEmpty,
          reason: 'Parsed manifest should have default order');
      expect(manifest.version, isNotEmpty,
          reason: 'Parsed manifest should have version');
      expect(manifest.created, isA<DateTime>(),
          reason: 'Parsed manifest should have valid creation date');

      // Validate track parsing
      for (final track in manifest.tracks) {
        expect(track.key, isNotEmpty);
        expect(track.filename, isNotEmpty);
        expect(track.lengthSec, greaterThan(0));
        expect(track.sampleRate, anyOf([44100, 48000]));
        expect(track.channels, equals(2));
        expect(track.title, isNotEmpty);
        expect(track.description, isNotEmpty);
      }
    });

    test('all required binaural frequencies are present', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      // Map of expected binaural frequency ranges
      final requiredFrequencies = {
        'Alpha': [8, 13], // Alpha waves (8-13 Hz)
        'Beta': [14, 30], // Beta waves (14-30 Hz)
        'Gamma': [30, 100], // Gamma waves (30+ Hz)
        'Theta': [4, 8], // Theta waves (4-8 Hz)
        'Delta': [0.5, 4], // Delta waves (0.5-4 Hz)
      };

      final trackTitles = tracks.map((t) => t['title'] as String).toList();

      // Check that we have tracks covering the main brainwave categories
      for (final frequency in ['Alpha', 'Beta', 'Gamma', 'Theta']) {
        final hasFrequency = trackTitles.any(
            (title) => title.toLowerCase().contains(frequency.toLowerCase()));
        expect(hasFrequency, isTrue,
            reason: 'Should have at least one $frequency frequency track');
      }
    });

    test('audio file extensions are supported', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      final supportedExtensions = {'.mp3', '.aac', '.m4a', '.wav'};

      for (final track in tracks) {
        final filename = track['filename'] as String;
        final extension =
            filename.substring(filename.lastIndexOf('.')).toLowerCase();

        expect(supportedExtensions.contains(extension), isTrue,
            reason: 'File $filename has unsupported extension $extension');
      }
    });

    test('track lengths are reasonable for binaural sessions', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      for (final track in tracks) {
        final lengthSec = track['lengthSec'] as num;
        final trackName = track['title'] as String;

        // Tracks should be between 5 and 20 minutes for optimal looping
        expect(lengthSec, greaterThanOrEqualTo(300), // 5 minutes
            reason:
                '$trackName should be at least 5 minutes long for effective binaural beats');
        expect(lengthSec, lessThanOrEqualTo(1200), // 20 minutes
            reason:
                '$trackName should be at most 20 minutes to avoid large file sizes');
      }
    });
  });

  group('Audio Controller Validation', () {
    test('UltraAudioController initializes without errors', () async {
      final controller = UltraAudioController.instance;

      // Test initialization
      expect(() => controller.initialize(), returnsNormally,
          reason: 'Audio controller should initialize without throwing');
    });

    test('Audio error enum covers all cases', () {
      final allErrors = AudioError.values;

      // Ensure we have reasonable error coverage
      expect(allErrors, contains(AudioError.fileNotFound));
      expect(allErrors, contains(AudioError.decodeError));
      expect(allErrors, contains(AudioError.focusDenied));
      expect(allErrors, contains(AudioError.routeChange));
      expect(allErrors, contains(AudioError.interruption));
      expect(allErrors, contains(AudioError.backendUnavailable));
      expect(allErrors, contains(AudioError.unknownError));

      // Should have at least 6 error types for comprehensive coverage
      expect(allErrors.length, greaterThanOrEqualTo(6),
          reason: 'Should have comprehensive error type coverage');
    });
  });

  group('Performance Requirements', () {
    test('manifest file size is reasonable', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final sizeBytes = manifestContent.length;

      // Manifest should be under 10KB for fast loading
      expect(sizeBytes, lessThan(10240),
          reason: 'Manifest should be under 10KB for fast loading');
    });

    test('track count is reasonable', () async {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      final tracks = manifestJson['tracks'] as List;

      // Should have between 5 and 20 tracks for good variety without bloat
      expect(tracks.length, greaterThanOrEqualTo(5),
          reason: 'Should have at least 5 tracks for variety');
      expect(tracks.length, lessThanOrEqualTo(20),
          reason: 'Should have at most 20 tracks to avoid app bloat');
    });
  });
}
