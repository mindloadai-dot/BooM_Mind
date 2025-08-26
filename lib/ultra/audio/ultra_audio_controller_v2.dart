import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio error codes for telemetry
enum AudioError {
  fileNotFound,
  decodeError,
  focusDenied,
  routeChange,
  interruption,
  backendUnavailable,
  unknownError
}

/// Audio track metadata
class UltraAudioTrack {
  final String key;
  final String filename;
  final double lengthSec;
  final int sampleRate;
  final int channels;

  const UltraAudioTrack({
    required this.key,
    required this.filename,
    required this.lengthSec,
    required this.sampleRate,
    required this.channels,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UltraAudioTrack &&
        other.key == key &&
        other.filename == filename &&
        other.lengthSec == lengthSec &&
        other.sampleRate == sampleRate &&
        other.channels == channels;
  }

  @override
  int get hashCode => Object.hash(key, filename, lengthSec, sampleRate, channels);
}

/// Playback state for Ultra Mode
enum UltraPlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error
}

/// Ultra Mode focus preset configuration
class UltraPreset {
  final String name;
  final String category;
  final List<UltraAudioTrack> tracks;
  final double defaultVolume;
  final bool supportsFading;
  final String? description;

  const UltraPreset({
    required this.name,
    required this.category,
    required this.tracks,
    this.defaultVolume = 0.7,
    this.supportsFading = true,
    this.description,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UltraPreset &&
        other.name == name &&
        other.category == category &&
        listEquals(other.tracks, tracks) &&
        other.defaultVolume == defaultVolume &&
        other.supportsFading == supportsFading &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(
    name, category, Object.hashAll(tracks), 
    defaultVolume, supportsFading, description
  );
}

/// Settings for Ultra Mode audio playback
class UltraAudioSettings {
  final double volume;
  final bool enableFadeIn;
  final bool enableFadeOut;
  final int fadeInDurationMs;
  final int fadeOutDurationMs;
  final bool enableCrossfade;
  final bool enableGaplessPlayback;
  final int bufferSizeMs;
  final String audioFormat;

  const UltraAudioSettings({
    this.volume = 0.7,
    this.enableFadeIn = true,
    this.enableFadeOut = true,
    this.fadeInDurationMs = 3000,
    this.fadeOutDurationMs = 3000,
    this.enableCrossfade = true,
    this.enableGaplessPlayback = true,
    this.bufferSizeMs = 2000,
    this.audioFormat = 'AAC',
  });

  Map<String, dynamic> toJson() => {
    'volume': volume,
    'enableFadeIn': enableFadeIn,
    'enableFadeOut': enableFadeOut,
    'fadeInDurationMs': fadeInDurationMs,
    'fadeOutDurationMs': fadeOutDurationMs,
    'enableCrossfade': enableCrossfade,
    'enableGaplessPlayback': enableGaplessPlayback,
    'bufferSizeMs': bufferSizeMs,
    'audioFormat': audioFormat,
  };

  factory UltraAudioSettings.fromJson(Map<String, dynamic> json) => UltraAudioSettings(
    volume: (json['volume'] as num?)?.toDouble() ?? 0.7,
    enableFadeIn: json['enableFadeIn'] as bool? ?? true,
    enableFadeOut: json['enableFadeOut'] as bool? ?? true,
    fadeInDurationMs: json['fadeInDurationMs'] as int? ?? 3000,
    fadeOutDurationMs: json['fadeOutDurationMs'] as int? ?? 3000,
    enableCrossfade: json['enableCrossfade'] as bool? ?? true,
    enableGaplessPlayback: json['enableGaplessPlayback'] as bool? ?? true,
    bufferSizeMs: json['bufferSizeMs'] as int? ?? 2000,
    audioFormat: json['audioFormat'] as String? ?? 'AAC',
  );

  UltraAudioSettings copyWith({
    double? volume,
    bool? enableFadeIn,
    bool? enableFadeOut,
    int? fadeInDurationMs,
    int? fadeOutDurationMs,
    bool? enableCrossfade,
    bool? enableGaplessPlayback,
    int? bufferSizeMs,
    String? audioFormat,
  }) => UltraAudioSettings(
    volume: volume ?? this.volume,
    enableFadeIn: enableFadeIn ?? this.enableFadeIn,
    enableFadeOut: enableFadeOut ?? this.enableFadeOut,
    fadeInDurationMs: fadeInDurationMs ?? this.fadeInDurationMs,
    fadeOutDurationMs: fadeOutDurationMs ?? this.fadeOutDurationMs,
    enableCrossfade: enableCrossfade ?? this.enableCrossfade,
    enableGaplessPlayback: enableGaplessPlayback ?? this.enableGaplessPlayback,
    bufferSizeMs: bufferSizeMs ?? this.bufferSizeMs,
    audioFormat: audioFormat ?? this.audioFormat,
  );
}

/// Ultra Mode Audio Controller V2 - Enhanced version with advanced features
/// Provides high-quality audio playback for focus sessions with advanced controls
class UltraAudioControllerV2 with ChangeNotifier {
  static UltraAudioControllerV2? _instance;
  
  /// Singleton instance
  static UltraAudioControllerV2 get instance {
    _instance ??= UltraAudioControllerV2._internal();
    return _instance!;
  }
  
  UltraAudioControllerV2._internal();

  // Core audio components
  late AudioPlayer _player;
  late AudioSession _audioSession;
  // Deprecated ConcatenatingAudioSource replaced by setAudioSources flow
  late List<AudioSource> _playlist;
  
  // State management
  final StreamController<UltraPlaybackState> _stateController = 
      StreamController<UltraPlaybackState>.broadcast();
  final StreamController<AudioError> _errorController = 
      StreamController<AudioError>.broadcast();
  
  // Settings and configuration
  UltraAudioSettings _settings = const UltraAudioSettings();
  UltraPreset? _currentPreset;
  UltraPlaybackState _state = UltraPlaybackState.stopped;
  
  // Audio state
  bool _isInitialized = false;
  Timer? _fadeTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Streams
  Stream<UltraPlaybackState> get stateStream => _stateController.stream;
  Stream<AudioError> get errorStream => _errorController.stream;
  
  // Getters
  UltraPlaybackState get state => _state;
  UltraAudioSettings get settings => _settings;
  UltraPreset? get currentPreset => _currentPreset;
  bool get isInitialized => _isInitialized;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _state == UltraPlaybackState.playing;
  bool get isPaused => _state == UltraPlaybackState.paused;
  bool get isStopped => _state == UltraPlaybackState.stopped;

  /// Initialize the controller
  Future<void> initialize() async {
    try {
      await _loadSettings();
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ UltraAudioControllerV2 initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize UltraAudioControllerV2: $e');
      }
      rethrow;
    }
  }

  /// Set up player event listeners
  void _setupPlayerListeners() {
    // Position updates
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Duration updates  
    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Playback events
    _player.playbackEventStream.listen((event) {
      final isPlaying = _player.playing;
      final processingState = event.processingState;
      
      _updatePlaybackState(isPlaying, processingState);
    });

    // Handle errors
    _player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.idle && 
          event.updatePosition == Duration.zero) {
        // Potential error condition
        _handleError(AudioError.unknownError);
      }
    });
  }

  /// Update playback state based on player status
  void _updatePlaybackState(bool isPlaying, ProcessingState processingState) {
    UltraPlaybackState newState;
    
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      newState = UltraPlaybackState.loading;
    } else if (isPlaying) {
      newState = UltraPlaybackState.playing;
    } else if (processingState == ProcessingState.ready) {
      newState = UltraPlaybackState.paused;
    } else {
      newState = UltraPlaybackState.stopped;
    }
    
    if (newState != _state) {
      _state = newState;
      _stateController.add(_state);
      notifyListeners();
    }
  }

  /// Load a preset and prepare for playback
  Future<bool> loadPreset(UltraPreset preset) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      _setState(UltraPlaybackState.loading);
      
      // Stop current playback
      await stop();
      
      // Clear existing playlist
      _playlist = <AudioSource>[];
      
      // Load tracks for the preset
      final audioSources = <AudioSource>[];
      
      for (final track in preset.tracks) {
        try {
          final audioSource = AudioSource.uri(
            Uri.parse('asset://assets/audio/${track.filename}'),
          );
          audioSources.add(audioSource);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Failed to load track ${track.filename}: $e');
          }
          _handleError(AudioError.fileNotFound);
          continue;
        }
      }
      
      if (audioSources.isEmpty) {
        throw Exception('No valid audio tracks found in preset');
      }
      
      // Set multiple audio sources directly (replacement for ConcatenatingAudioSource)
      _playlist = audioSources;
      await _player.setAudioSources(_playlist);
      
      _currentPreset = preset;
      _setState(UltraPlaybackState.stopped);
      
      if (kDebugMode) {
        debugPrint('✅ Preset loaded: ${preset.name}');
      }
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load preset: $e');
      }
      _handleError(AudioError.decodeError);
      _setState(UltraPlaybackState.error);
      return false;
    }
  }

  /// Start playback
  Future<void> play() async {
    if (!_isInitialized || _currentPreset == null) {
      throw StateError('Audio controller not initialized or no preset loaded');
    }
    
    try {
      if (_settings.enableFadeIn) {
        await _player.setVolume(0.0);
        await _player.play();
        await _fadeIn();
      } else {
        await _player.setVolume(_settings.volume);
        await _player.play();
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Playback failed: $e');
      }
      _handleError(AudioError.backendUnavailable);
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (!_isInitialized) return;
    
    try {
      if (_settings.enableFadeOut && _player.playing) {
        await _fadeOut(pauseAfter: true);
      } else {
        await _player.pause();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Pause failed: $e');
      }
      _handleError(AudioError.unknownError);
    }
  }

  /// Stop playback
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    try {
      _fadeTimer?.cancel();
      
      if (_player.playing) {
        if (_settings.enableFadeOut) {
          await _fadeOut(stopAfter: true);
        } else {
          await _player.stop();
        }
      } else {
        await _player.stop();
      }
      // Fully release audio to avoid lingering playback
      await _player.dispose();
      _player = AudioPlayer();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Stop failed: $e');
      }
      _handleError(AudioError.unknownError);
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (!_isInitialized) return;
    
    try {
      await _player.seek(position);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Seek failed: $e');
      }
      _handleError(AudioError.unknownError);
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    
    volume = volume.clamp(0.0, 1.0);
    _settings = _settings.copyWith(volume: volume);
    
    try {
      await _player.setVolume(volume);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Volume change failed: $e');
      }
    }
  }

  /// Update audio settings
  Future<void> updateSettings(UltraAudioSettings newSettings) async {
    _settings = newSettings;
    
    if (_isInitialized) {
      await _player.setVolume(_settings.volume);
    }
    
    await _saveSettings();
    notifyListeners();
  }

  /// Fade in audio
  Future<void> _fadeIn() async {
    _fadeTimer?.cancel();
    
    final startVolume = 0.0;
    final endVolume = _settings.volume;
    final duration = Duration(milliseconds: _settings.fadeInDurationMs);
    const steps = 50;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = (endVolume - startVolume) / steps;
    
    var currentVolume = startVolume;
    
    for (int i = 0; i < steps; i++) {
      if (!_player.playing) break;
      
      currentVolume += volumeStep;
      await _player.setVolume(currentVolume.clamp(0.0, 1.0));
      await Future.delayed(stepDuration);
    }
    
    await _player.setVolume(endVolume);
  }

  /// Fade out audio
  Future<void> _fadeOut({bool pauseAfter = false, bool stopAfter = false}) async {
    _fadeTimer?.cancel();
    
    final startVolume = _player.volume;
    const endVolume = 0.0;
    final duration = Duration(milliseconds: _settings.fadeOutDurationMs);
    const steps = 50;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = (startVolume - endVolume) / steps;
    
    var currentVolume = startVolume;
    
    for (int i = 0; i < steps; i++) {
      if (!_player.playing) break;
      
      currentVolume -= volumeStep;
      await _player.setVolume(currentVolume.clamp(0.0, 1.0));
      await Future.delayed(stepDuration);
    }
    
    await _player.setVolume(endVolume);
    
    if (pauseAfter) {
      await _player.pause();
    } else if (stopAfter) {
      await _player.stop();
    }
    
    // Restore original volume for next playback
    await _player.setVolume(_settings.volume);
  }

  /// Set playback state and notify listeners
  void _setState(UltraPlaybackState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
      notifyListeners();
    }
  }

  /// Handle audio errors
  void _handleError(AudioError error) {
    _errorController.add(error);
    if (kDebugMode) {
      debugPrint('🚨 Audio error: $error');
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('ultra_audio_settings_v2');
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = UltraAudioSettings.fromJson(settingsMap);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load audio settings: $e');
      }
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString('ultra_audio_settings_v2', settingsJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save audio settings: $e');
      }
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _fadeTimer?.cancel();
    _player.dispose();
    _stateController.close();
    _errorController.close();
    _isInitialized = false;
    super.dispose();
  }
}