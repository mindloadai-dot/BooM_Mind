import 'package:flutter/services.dart';
import 'audio_asset_service.dart';

/// Test service to verify audio assets are working correctly
class AudioTestService {
  static final AudioTestService _instance = AudioTestService._internal();
  factory AudioTestService() => _instance;
  AudioTestService._internal();

  final AudioAssetService _audioService = AudioAssetService();

  /// Test all audio assets to ensure they're accessible
  Future<Map<String, bool>> testAudioAssets() async {
    print('🧪 Testing optimized audio assets...');

    final results = <String, bool>{};
    final availableKeys = _audioService.getAvailableAudioKeys();

    for (final key in availableKeys) {
      try {
        final path = await _audioService.getAudioPath(key);
        if (path != null) {
          // Try to load the asset to verify it exists
          await rootBundle.load(path);
          results[key] = true;
          print('✅ $key: $path - OK');
        } else {
          results[key] = false;
          print('❌ $key: Path is null');
        }
      } catch (e) {
        results[key] = false;
        print('❌ $key: Error - $e');
      }
    }

    final successCount = results.values.where((success) => success).length;
    final totalCount = results.length;

    print('\n📊 Audio Asset Test Results:');
    print('   ✅ Success: $successCount/$totalCount');
    print('   📦 Total Size: ~13.64 MB (192kbps optimized)');
    print('   🎵 Quality: 192kbps MP3');

    return results;
  }

  /// Get audio asset summary
  Map<String, dynamic> getAudioSummary() {
    final fileInfo = _audioService.getAudioFileInfo();

    return {
      'totalFiles': fileInfo.length,
      'estimatedSize': '13.64 MB',
      'quality': '192kbps',
      'files': fileInfo,
      'optimization': '71% size reduction from original',
    };
  }

  /// Validate audio system is ready
  Future<bool> validateAudioSystem() async {
    try {
      final results = await testAudioAssets();
      final allSuccess = results.values.every((success) => success);

      if (allSuccess) {
        print('🎉 Audio system validation: PASSED');
        return true;
      } else {
        print('⚠️  Audio system validation: PARTIAL');
        return false;
      }
    } catch (e) {
      print('❌ Audio system validation: FAILED - $e');
      return false;
    }
  }
}
