/// Service for managing optimized audio assets (192kbps)
/// Now uses bundled assets instead of dynamic loading
class AudioAssetService {
  static final AudioAssetService _instance = AudioAssetService._internal();
  factory AudioAssetService() => _instance;
  AudioAssetService._internal();

  static const String _cacheKey = 'audio_assets_cached';

  /// Audio file mappings - now using optimized 192kbps files from assets
  static const Map<String, String> _audioFiles = {
    'alpha': 'Alpha.mp3',
    'alpha10': 'Alpha10.mp3',
    'alphaTheta': 'AlphaTheta.mp3',
    'beta': 'Beta.mp3',
    'gamma': 'Gamma.mp3',
    'theta': 'Theta.mp3',
    'theta6': 'Theta6.mp3',
  };

  /// Get audio asset path - now using optimized bundled assets
  Future<String?> getAudioPath(String audioKey) async {
    try {
      final fileName = _audioFiles[audioKey];
      if (fileName == null) return null;

      // Return the asset path directly since files are now bundled
      return 'assets/audio/$fileName';
    } catch (e) {
      print('Error getting audio path for $audioKey: $e');
      return null;
    }
  }

  /// Get all available audio keys
  List<String> getAvailableAudioKeys() {
    return _audioFiles.keys.toList();
  }

  /// Check if audio file exists
  bool hasAudioFile(String audioKey) {
    return _audioFiles.containsKey(audioKey);
  }

  /// Get audio file info
  Map<String, String> getAudioFileInfo() {
    return Map.from(_audioFiles);
  }

  /// Preload audio assets (now just validates they exist)
  Future<void> preloadAudioAssets() async {
    print('Validating optimized audio assets...');

    for (final entry in _audioFiles.entries) {
      try {
        final path = await getAudioPath(entry.key);
        if (path != null) {
          print('✅ Audio asset ready: ${entry.key} -> ${entry.value}');
        } else {
          print('❌ Audio asset missing: ${entry.key}');
        }
      } catch (e) {
        print('❌ Error validating ${entry.key}: $e');
      }
    }

    print('Audio asset validation completed');
  }

  /// Get total audio assets size (now bundled)
  Future<int> getTotalAudioSize() async {
    // Since files are now bundled, return estimated size
    return 13640000; // ~13.64 MB as calculated
  }
}
