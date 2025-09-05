import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
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
  final String title;
  final String description;

  const UltraAudioTrack({
    required this.key,
    required this.filename,
    required this.lengthSec,
    required this.sampleRate,
    required this.channels,
    required this.title,
    required this.description,
  });

  factory UltraAudioTrack.fromJson(Map<String, dynamic> json) {
    return UltraAudioTrack(
      key: json['key'] as String,
      filename: json['filename'] as String,
      lengthSec: (json['lengthSec'] as num).toDouble(),
      sampleRate: json['sampleRate'] as int? ?? 44100,
      channels: json['channels'] as int? ?? 2,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'filename': filename,
        'lengthSec': lengthSec,
        'sampleRate': sampleRate,
        'channels': channels,
        'title': title,
        'description': description,
      };
}

/// Audio manifest metadata
class UltraAudioManifest {
  final List<UltraAudioTrack> tracks;
  final List<String> defaultOrder;
  final String version;
  final DateTime created;
  final bool crossfadeSupported;

  const UltraAudioManifest({
    required this.tracks,
    required this.defaultOrder,
    required this.version,
    required this.created,
    required this.crossfadeSupported,
  });

  factory UltraAudioManifest.fromJson(Map<String, dynamic> json) {
    final tracksJson = json['tracks'] as List;
    final tracks = tracksJson.map((t) => UltraAudioTrack.fromJson(t)).toList();

    final metadata = json['metadata'] as Map<String, dynamic>;

    return UltraAudioManifest(
      tracks: tracks,
      defaultOrder: List<String>.from(json['defaultOrder'] ?? []),
      version: metadata['version'] as String,
      created: DateTime.parse(metadata['created'] as String),
      crossfadeSupported: metadata['crossfadeSupported'] as bool? ?? true,
    );
  }
}

/// Playback state information
class UltraPlaybackState {
  final bool isPlaying;
  final bool isPaused;
  final Duration position;
  final Duration sessionLength;
  final Duration remaining;
  final UltraAudioTrack? currentTrack;
  final int playlistIndex;
  final bool isLooping;
  final double volume;

  const UltraPlaybackState({
    required this.isPlaying,
    required this.isPaused,
    required this.position,
    required this.sessionLength,
    required this.remaining,
    this.currentTrack,
    required this.playlistIndex,
    required this.isLooping,
    required this.volume,
  });

  UltraPlaybackState copyWith({
    bool? isPlaying,
    bool? isPaused,
    Duration? position,
    Duration? sessionLength,
    Duration? remaining,
    UltraAudioTrack? currentTrack,
    int? playlistIndex,
    bool? isLooping,
    double? volume,
  }) {
    return UltraPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      position: position ?? this.position,
      sessionLength: sessionLength ?? this.sessionLength,
      remaining: remaining ?? this.remaining,
      currentTrack: currentTrack ?? this.currentTrack,
      playlistIndex: playlistIndex ?? this.playlistIndex,
      isLooping: isLooping ?? this.isLooping,
      volume: volume ?? this.volume,
    );
  }
}

/// Preset configuration for Ultra Mode audio
class UltraPreset {
  final String key;
  final String name;
  final List<String> trackKeys;
  final String description;
  final double defaultVolume;
  final Duration defaultCrossfade;

  const UltraPreset({
    required this.key,
    required this.name,
    required this.trackKeys,
    required this.description,
    this.defaultVolume = 0.8,
    this.defaultCrossfade = const Duration(milliseconds: 800),
  });

  static const List<UltraPreset> defaultPresets = [
    UltraPreset(
      key: 'focus_flow',
      name: 'Focus Flow',
      trackKeys: ['focus_alpha', 'gamma_concentration'],
      description: 'Deep concentration blend for extended focus sessions',
    ),
    UltraPreset(
      key: 'creative_spark',
      name: 'Creative Spark',
      trackKeys: ['theta_creativity', 'alpha_calm'],
      description: 'Enhanced creativity and inspiration mode',
    ),
    UltraPreset(
      key: 'memory_boost',
      name: 'Memory Boost',
      trackKeys: ['alpha_theta_memory', 'focus_alpha'],
      description: 'Memory retention and learning enhancement',
    ),
    UltraPreset(
      key: 'power_focus',
      name: 'Power Focus',
      trackKeys: ['beta_productivity', 'gamma_concentration'],
      description: 'Maximum productivity and intense focus',
    ),
    UltraPreset(
      key: 'calm_study',
      name: 'Calm Study',
      trackKeys: ['alpha_calm', 'theta_creativity'],
      description: 'Relaxed learning and stress-free studying',
    ),
  ];
}

/// Ultra Mode audio playback state compatibility
enum UltraPlaybackStateEnum {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error
}

/// Audio error types for Ultra Mode system compatibility
enum UltraAudioErrorType {
  startupFail,
  fileMissing,
  focusLoss,
  routeChange,
  sessionConfig,
  playbackFail,
  assetLoad,
  permission
}

/// Ultra Mode audio error for compatibility
class UltraAudioError {
  final UltraAudioErrorType type;
  final String message;
  final String platform;
  final String? file;
  final DateTime timestamp;

  UltraAudioError({
    required this.type,
    required this.message,
    required this.platform,
    this.file,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        'platform': platform,
        'file': file,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Centralized Ultra Mode Audio Controller
///
/// This controller handles all Ultra Mode audio playbook across all platforms
/// with feature parity, proper error handling, and bulletproof reliability.
/// Implements both BaseAudioHandler for system integration and ChangeNotifier for UI updates.
class UltraAudioController extends BaseAudioHandler with ChangeNotifier {
  static UltraAudioController? _instance;

  /// Singleton instance
  static UltraAudioController get instance {
    _instance ??= UltraAudioController._internal();
    return _instance!;
  }

  UltraAudioController._internal();

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
  final StreamController<UltraAudioError> _ultraErrorController =
      StreamController<UltraAudioError>.broadcast();

  // Audio configuration
  UltraAudioManifest? _manifest;
  List<UltraAudioTrack> _currentPlaylist = [];
  Duration _sessionLength = Duration.zero;
  double _volume = 0.8;
  bool _crossfadeEnabled = true;
  Timer? _sessionTimer;
  Timer? _crossfadeTimer;
  // Removed unused _lastPausedTime to satisfy analyzer

  // Playback state
  UltraPlaybackState _currentState = const UltraPlaybackState(
    isPlaying: false,
    isPaused: false,
    position: Duration.zero,
    sessionLength: Duration.zero,
    remaining: Duration.zero,
    playlistIndex: 0,
    isLooping: false,
    volume: 0.8,
  );

  // Public streams
  Stream<UltraPlaybackState> get stateStream => _stateController.stream;
  Stream<AudioError> get audioErrorStream => _errorController.stream;

  // UI compatibility - main error stream used by UI components
  Stream<UltraAudioError> get errorStream => ultraErrorStream;

  // Additional compatibility streams for UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration> get durationStream =>
      _player.durationStream.map((d) => d ?? Duration.zero);
  Stream<bool> get playingStream => _player.playingStream;
  Stream<UltraPlaybackState> get processingStateStream => stateStream;
  Stream<UltraAudioError> get ultraErrorStream => _ultraErrorController.stream;

  // Current state getters
  UltraPlaybackState get currentState => _currentState;
  bool get isInitialized => _manifest != null;
  Duration get sessionLength => _sessionLength;
  double get volume => _volume;
  bool get crossfadeEnabled => _crossfadeEnabled;

  // Additional compatibility getters for UI
  bool get isPlaying => _currentState.isPlaying;
  bool get isPaused => _currentState.isPaused;
  Duration get position => _currentState.position;
  Duration get remaining => _currentState.remaining;
  UltraAudioTrack? get currentTrack => _currentState.currentTrack;
  bool get isLooping => _currentState.isLooping;
  bool get hasSession => _sessionLength > Duration.zero && _manifest != null;
  UltraPreset? get currentPreset => _currentPlaylist.isNotEmpty
      ? UltraPreset(
          key: 'current',
          name: 'Current Session',
          trackKeys: _currentPlaylist.map((t) => t.key).toList(),
          description: 'Currently loaded session',
        )
      : null;
  Duration get duration => _currentPlaylist.isNotEmpty
      ? Duration(seconds: _currentPlaylist.first.lengthSec.round())
      : Duration.zero;
  Duration get bufferedPosition => position; // Simplified for now

  // Session management
  Duration get sessionRemaining => _currentState.remaining;
  double get sessionProgress => _sessionLength.inMilliseconds > 0
      ? (position.inMilliseconds / _sessionLength.inMilliseconds)
          .clamp(0.0, 1.0)
      : 0.0;

  // State conversion for UI compatibility
  UltraPlaybackStateEnum get state {
    if (_currentState.isPlaying) return UltraPlaybackStateEnum.playing;
    if (_currentState.isPaused) return UltraPlaybackStateEnum.paused;
    if (_currentState.position >= _sessionLength &&
        _sessionLength > Duration.zero) {
      return UltraPlaybackStateEnum.completed;
    }
    return UltraPlaybackStateEnum.idle;
  }

  // Track management getters
  List<UltraAudioTrack> get availableTracks => _manifest?.tracks ?? [];
  UltraAudioTrack? get selectedTrack =>
      _currentPlaylist.isNotEmpty ? _currentPlaylist.first : null;

  /// Initialize the audio controller
  Future<void> initialize() async {
    try {
      debugPrint('[UltraAudio] Initializing audio controller...');

      // Initialize audio session
      _audioSession = await AudioSession.instance;
      await _configureAudioSession();

      // Initialize audio player
      _player = AudioPlayer();
      await _player.setVolume(_volume);

      // Setup audio sources container
      _playlist = <AudioSource>[];

      // Load manifest and validate assets
      await _loadManifest();
      await _validateAudioAssets();

      // Setup listeners
      _setupAudioListeners();
      _setupSessionListeners();

      // Load preferences
      await _loadPreferences();

      debugPrint('[UltraAudio] Controller initialized successfully');
    } catch (e) {
      debugPrint('[UltraAudio] Initialization failed: $e');
      _reportError(AudioError.backendUnavailable, 'Initialization failed: $e');
      rethrow;
    }
  }

  /// Configure audio session for cross-platform compatibility
  Future<void> _configureAudioSession() async {
    try {
      // Configure for media playback with background support
      final config = const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      );
      await _audioSession.configure(config);
    } catch (e) {
      debugPrint('[UltraAudio] Audio session configuration failed: $e');
      _reportError(AudioError.backendUnavailable, 'Audio session setup failed');
    }
  }

  /// Load and validate the audio manifest
  Future<void> _loadManifest() async {
    try {
      final manifestContent =
          await rootBundle.loadString('assets/audio/manifest.json');
      final manifestJson = jsonDecode(manifestContent);
      _manifest = UltraAudioManifest.fromJson(manifestJson);

      debugPrint(
          '[UltraAudio] Loaded manifest with ${_manifest!.tracks.length} tracks');
    } catch (e) {
      debugPrint('[UltraAudio] Failed to load manifest: $e - using fallback');
      _reportError(
          AudioError.fileNotFound, 'Manifest load failed, using fallback');

      // Create a fallback manifest with basic binaural beat tracks
      _manifest = UltraAudioManifest(
        tracks: _createFallbackTracks(),
        defaultOrder: [
          'focus_alpha',
          'gamma_concentration',
          'theta_creativity'
        ],
        version: '1.0.0+23',
        created: DateTime.now(),
        crossfadeSupported: true,
      );

      debugPrint(
          '[UltraAudio] Initialized with ${_manifest!.tracks.length} fallback tracks');
    }
  }

  /// Validate all audio assets exist and have correct properties
  Future<void> _validateAudioAssets() async {
    if (_manifest == null) return;

    final List<String> missingFiles = [];
    final List<String> invalidFiles = [];
    final List<UltraAudioTrack> validTracks = [];

    for (final track in _manifest!.tracks) {
      try {
        // Check if asset exists by attempting to load it
        await rootBundle.load('assets/audio/${track.filename}');

        // Validate audio properties (channels must be 2 for stereo)
        if (track.channels != 2) {
          invalidFiles.add(
              '${track.filename}: Not stereo (${track.channels} channels)');
          continue;
        }

        // Validate sample rate
        if (track.sampleRate != 44100 && track.sampleRate != 48000) {
          invalidFiles.add(
              '${track.filename}: Invalid sample rate (${track.sampleRate}Hz)');
          continue;
        }

        validTracks.add(track);
      } catch (e) {
        missingFiles.add(track.filename);
      }
    }

    // If we have some valid tracks, filter the manifest to only include them
    if (validTracks.isNotEmpty) {
      _manifest = UltraAudioManifest(
        tracks: validTracks,
        defaultOrder: validTracks.map((t) => t.key).toList(),
        version: _manifest!.version,
        created: _manifest!.created,
        crossfadeSupported: _manifest!.crossfadeSupported,
      );
      debugPrint(
          '[UltraAudio] Using ${validTracks.length} valid tracks out of ${_manifest!.tracks.length + missingFiles.length + invalidFiles.length} total');
    }

    if (missingFiles.isNotEmpty) {
      debugPrint(
          '[UltraAudio] Warning: Missing audio files: ${missingFiles.join(', ')}');
      _reportError(AudioError.fileNotFound,
          'Some audio files missing, using available tracks');
    }

    if (invalidFiles.isNotEmpty) {
      debugPrint(
          '[UltraAudio] Warning: Invalid audio files: ${invalidFiles.join(', ')}');
      _reportError(AudioError.decodeError,
          'Some audio files invalid, using valid tracks');
    }

    // Only throw if NO tracks are valid
    if (validTracks.isEmpty) {
      final error = 'No valid audio files found';
      debugPrint('[UltraAudio] $error');
      _reportError(AudioError.fileNotFound, error);
      throw Exception('Audio controller not initialized');
    }

    debugPrint(
        '[UltraAudio] ${validTracks.length} audio assets validated and ready');
  }

  /// Load a preset with session duration for UI compatibility
  Future<void> load(UltraPreset preset, Duration sessionDuration) async {
    try {
      await startSession(
        sessionLength: sessionDuration,
        preset: preset.trackKeys,
      );

      // Update state for UI
      notifyListeners();
    } catch (e) {
      debugPrint('[UltraAudio] Failed to load preset: $e');
      _reportError(AudioError.backendUnavailable, 'Preset load failed: $e');
      rethrow;
    }
  }

  /// Setup audio player listeners
  void _setupAudioListeners() {
    // Position updates
    _player.positionStream.listen((position) {
      _updateState(_currentState.copyWith(
        position: position,
        remaining: _sessionLength - position,
      ));
      notifyListeners();
    });

    // Player state changes
    _player.playerStateStream.listen((state) {
      _updateState(_currentState.copyWith(
        isPlaying: state.playing,
        isPaused: !state.playing && _currentState.position > Duration.zero,
      ));
      notifyListeners();
    });

    // Playback completion
    _player.playerStateStream
        .where((state) => state.processingState == ProcessingState.completed)
        .listen((_) => _handlePlaybackCompleted());
    // Simplified: no artificial loading timeouts or retries
  }

  /// Setup system audio session listeners
  void _setupSessionListeners() {
    // Handle audio interruptions
    _audioSession.interruptionEventStream.listen((event) {
      debugPrint('[UltraAudio] Audio interruption: ${event.type}');

      switch (event.type) {
        case AudioInterruptionType.pause:
          if (_currentState.isPlaying) {
            pause();
            _reportError(AudioError.interruption, 'Audio interrupted');
          }
          break;
        case AudioInterruptionType.duck:
          // No volume ducking; ignore to keep original audio
          break;
        case AudioInterruptionType.unknown:
          break;
      }
    });

    // Handle route changes (headphone plug/unplug, etc.)
    _audioSession.devicesChangedEventStream.listen((event) {
      debugPrint(
          '[UltraAudio] Audio route changed: ${event.devicesAdded} added, ${event.devicesRemoved} removed');

      // Check if headphones were unplugged
      final headphonesRemoved = event.devicesRemoved.any((device) =>
          device.type == AudioDeviceType.bluetoothA2dp ||
          device.type == AudioDeviceType.wiredHeadphones ||
          device.type == AudioDeviceType.wiredHeadset);

      if (headphonesRemoved && _currentState.isPlaying) {
        pause();
        _reportError(AudioError.routeChange, 'Headphones disconnected');
      }
    });
  }

  /// Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble('ultra_audio_volume') ?? 0.8;
      _crossfadeEnabled = prefs.getBool('ultra_audio_crossfade') ?? true;
      await _player.setVolume(_volume);

      // Check for saved position (within 10 minutes)
      final savedPosition = prefs.getInt('ultra_audio_last_position') ?? 0;
      final savedTime = prefs.getInt('ultra_audio_last_pause_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime - savedTime < 10 * 60 * 1000) {
        // 10 minutes
        final resumePosition = Duration(milliseconds: savedPosition);
        if (resumePosition > Duration.zero) {
          await _player.seek(resumePosition);
          debugPrint(
              '[UltraAudio] Restored position: ${resumePosition.inSeconds}s');
        }
      }
    } catch (e) {
      debugPrint('[UltraAudio] Failed to load preferences: $e');
    }
  }

  /// Save user preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ultra_audio_volume', _volume);
      await prefs.setBool('ultra_audio_crossfade', _crossfadeEnabled);
      await prefs.setInt(
          'ultra_audio_last_position', _currentState.position.inMilliseconds);
      await prefs.setInt(
          'ultra_audio_last_pause_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[UltraAudio] Failed to save preferences: $e');
    }
  }

  /// Build playlist from preset or default order
  Future<void> _buildPlaylist(List<String> trackKeys) async {
    if (_manifest == null) {
      throw Exception('Audio controller not initialized');
    }

    _currentPlaylist = [];
    final List<AudioSource> audioSources = [];

    for (final key in trackKeys) {
      final track = _manifest!.tracks.firstWhere(
        (t) => t.key == key,
        orElse: () {
          // If track not found, create a fallback track
          return UltraAudioTrack(
            key: key,
            filename: 'silence.wav',
            lengthSec: 300.0,
            sampleRate: 44100,
            channels: 2,
            title: key.replaceAll('_', ' ').toUpperCase(),
            description: 'Fallback silent track for focus',
          );
        },
      );

      _currentPlaylist.add(track);

      try {
        // Check if asset exists first
        await rootBundle.load('assets/audio/${track.filename}');

        // Create audio source from asset
        final audioSource = AudioSource.asset(
          'assets/audio/${track.filename}',
          tag: MediaItem(
            id: track.key,
            title: track.title,
            artist: 'Ultra Mode',
            duration: Duration(milliseconds: (track.lengthSec * 1000).round()),
          ),
        );

        audioSources.add(audioSource);
        debugPrint('[UltraAudio] ✅ Successfully loaded ${track.filename}');
      } catch (e) {
        // If asset loading fails, report error and skip this track
        debugPrint(
            '[UltraAudio] ❌ Asset not accessible: ${track.filename}, skipping track. Error: $e');
        _reportError(AudioError.fileNotFound,
            'Audio file not accessible: ${track.filename}');
        continue; // Skip this track instead of creating silent audio
      }
    }

    // Set multiple audio sources directly (replacement for ConcatenatingAudioSource)
    _playlist = audioSources;

    // On web, set audio sources one by one to avoid conflicts
    if (kIsWeb) {
      try {
        await _player.setAudioSources(_playlist);
        debugPrint(
            '[UltraAudio] ✅ Web playlist set successfully with ${_currentPlaylist.length} tracks');
      } catch (webError) {
        debugPrint('[UltraAudio] ❌ Web playlist setting failed: $webError');
        // Fallback: try setting just the first track
        if (audioSources.isNotEmpty) {
          try {
            await _player.setAudioSource(audioSources.first);
            debugPrint(
                '[UltraAudio] ✅ Web fallback: single track set successfully');
          } catch (fallbackError) {
            debugPrint(
                '[UltraAudio] ❌ Web fallback also failed: $fallbackError');
            rethrow;
          }
        }
      }
    } else {
      // Native platforms can handle multiple sources normally
      await _player.setAudioSources(_playlist);
    }

    debugPrint(
        '[UltraAudio] Built playlist with ${_currentPlaylist.length} tracks');
  }

  /// Start Ultra Mode session
  Future<void> startSession({
    required Duration sessionLength,
    List<String>? preset,
  }) async {
    try {
      debugPrint(
          '[UltraAudio] Starting session: ${sessionLength.inMinutes}min');

      if (_manifest == null) {
        throw Exception('Audio controller not initialized');
      }

      // Stop any current session
      await stop();

      // Setup session parameters
      _sessionLength = sessionLength;
      final trackKeys = preset ?? _manifest!.defaultOrder;

      if (trackKeys.isEmpty) {
        throw Exception('No tracks available for playback');
      }

      // Build playlist
      await _buildPlaylist(trackKeys);

      // Explicitly load the first source before playing (improves reliability on web)
      // Load explicitly and continue
      await _player.load();

      // Calculate total playlist duration
      final totalPlaylistDuration = Duration(
        milliseconds: _currentPlaylist
            .map((t) => (t.lengthSec * 1000).round())
            .reduce((a, b) => a + b),
      );

      // Determine if looping is needed
      final needsLooping = _sessionLength > totalPlaylistDuration;

      // Configure player for session
      await _player.setLoopMode(needsLooping ? LoopMode.all : LoopMode.off);

      // Activate audio session
      await _audioSession.setActive(true);

      // Start playback with fade-in
      await _fadeInAndPlay();

      // Setup session timer for precise timing
      _startSessionTimer();

      _updateState(_currentState.copyWith(
        isPlaying: true,
        isPaused: false,
        sessionLength: _sessionLength,
        remaining: _sessionLength,
        currentTrack: _currentPlaylist.first,
        playlistIndex: 0,
        isLooping: needsLooping,
      ));

      debugPrint('[UltraAudio] Session started successfully');
    } catch (e) {
      debugPrint('[UltraAudio] Failed to start session: $e');
      _reportError(AudioError.backendUnavailable, 'Session start failed: $e');
      rethrow;
    }
  }

  /// Pause playback
  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      await _savePreferences();

      _updateState(_currentState.copyWith(
        isPlaying: false,
        isPaused: true,
      ));

      debugPrint('[UltraAudio] Playback paused');
    } catch (e) {
      debugPrint('[UltraAudio] Failed to pause: $e');
      _reportError(AudioError.unknownError, 'Pause failed');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _audioSession.setActive(true);
      await _player.play();

      _updateState(_currentState.copyWith(
        isPlaying: true,
        isPaused: false,
      ));

      debugPrint('[UltraAudio] Playback resumed');
    } catch (e) {
      debugPrint('[UltraAudio] Failed to resume: $e');
      _reportError(AudioError.unknownError, 'Resume failed');
    }
  }

  /// Stop playback and end session
  @override
  Future<void> stop() async {
    try {
      _sessionTimer?.cancel();
      _crossfadeTimer?.cancel();

      if (_currentState.isPlaying) {
        await _fadeOutAndStop();
      } else {
        await _player.stop();
      }

      await _audioSession.setActive(false);
      await _player.dispose();
      _player = AudioPlayer();
      await _player.setVolume(_volume);
      _setupAudioListeners();

      _updateState(_currentState.copyWith(
        isPlaying: false,
        isPaused: false,
        position: Duration.zero,
        remaining: Duration.zero,
      ));

      debugPrint('[UltraAudio] Session stopped');
    } catch (e) {
      debugPrint('[UltraAudio] Failed to stop: $e');
      _reportError(AudioError.unknownError, 'Stop failed');
    }
  }

  /// Set playback volume
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _player.setVolume(_volume);
      await _savePreferences();

      _updateState(_currentState.copyWith(volume: _volume));
    } catch (e) {
      debugPrint('[UltraAudio] Failed to set volume: $e');
    }
  }

  /// Enable/disable crossfade
  Future<void> setCrossfadeEnabled(bool enabled) async {
    _crossfadeEnabled = enabled;
    await _savePreferences();
  }

  /// Select a specific track for playback
  Future<void> selectTrack(String trackKey) async {
    try {
      if (_manifest == null) {
        throw Exception('Audio controller not initialized');
      }

      final track = _manifest!.tracks.firstWhere(
        (t) => t.key == trackKey,
        orElse: () => throw Exception('Track not found: $trackKey'),
      );

      // Remember play state
      final bool wasPlaying = _currentState.isPlaying;

      // Stop current playback to ensure a clean switch
      await _player.stop();

      // Create a single-track playlist and set it as the source
      await _buildPlaylist([trackKey]);

      // Ensure we start from the beginning of the new track
      await _player.seek(Duration.zero);

      // Activate session and resume if needed
      await _audioSession.setActive(true);
      // Explicitly load new source before play (helps on web)
      try {
        await _player.load();
      } catch (e) {
        debugPrint('[UltraAudio] Load after selectTrack failed: $e');
      }
      if (wasPlaying) {
        await _player.play();
      }

      // Update state so UI reflects the new selection
      _updateState(_currentState.copyWith(
        currentTrack: track,
        playlistIndex: 0,
        isPlaying: wasPlaying,
        isPaused: !wasPlaying,
        position: Duration.zero,
      ));

      debugPrint('[UltraAudio] Selected track: ${track.title}');
    } catch (e) {
      debugPrint('[UltraAudio] Failed to select track: $e');
      _reportError(AudioError.unknownError, 'Track selection failed');
    }
  }

  /// Set crossfade duration for UI compatibility
  void setCrossfade(Duration duration) {
    // For now, just enable/disable based on duration
    _crossfadeEnabled = duration.inMilliseconds > 0;
    // Could store duration for future crossfade implementation
    debugPrint(
        '[UltraAudio] Crossfade duration set to: ${duration.inMilliseconds}ms');
  }

  /// Get crossfade duration for UI compatibility
  Duration get crossfadeDuration => const Duration(milliseconds: 800);

  /// Seek to position (with session bounds checking)
  @override
  Future<void> seek(Duration position) async {
    try {
      final clampedPosition = Duration(
        milliseconds: math.min(
          position.inMilliseconds,
          _sessionLength.inMilliseconds,
        ),
      );

      await _player.seek(clampedPosition);

      _updateState(_currentState.copyWith(
        position: clampedPosition,
        remaining: _sessionLength - clampedPosition,
      ));
    } catch (e) {
      debugPrint('[UltraAudio] Failed to seek: $e');
      _reportError(AudioError.unknownError, 'Seek failed');
    }
  }

  /// Fade in and start playback
  Future<void> _fadeInAndPlay() async {
    // Simplified: no fade-in, play immediately at current volume
    await _player.play();
  }

  /// Fade out and stop playback
  Future<void> _fadeOutAndStop() async {
    // Simplified: no fade-out
    await _player.stop();
  }

  /// Start session timer for precise duration control
  void _startSessionTimer() {
    _sessionTimer?.cancel();

    _sessionTimer = Timer(_sessionLength, () async {
      debugPrint('[UltraAudio] Session completed by timer');
      await stop();
      // Could add callback here for session completion
    });
  }

  /// Handle natural playback completion
  void _handlePlaybackCompleted() async {
    if (_currentState.position >= _sessionLength) {
      debugPrint('[UltraAudio] Session completed naturally');
      await stop();
    }
  }

  /// Update current state and notify listeners
  void _updateState(UltraPlaybackState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  /// Report audio error with telemetry
  void _reportError(AudioError error, String message) {
    debugPrint('[UltraAudio] Error: $error - $message');
    _errorController.add(error);

    // Convert to UltraAudioError for UI compatibility
    final ultraError = _convertToUltraAudioError(error, message);
    _ultraErrorController.add(ultraError);

    // In production, this would send telemetry data
    if (kReleaseMode) {
      // TODO: Send error telemetry without PII
    }
  }

  /// Convert AudioError to UltraAudioError for UI compatibility
  UltraAudioError _convertToUltraAudioError(AudioError error, String message) {
    UltraAudioErrorType type;
    switch (error) {
      case AudioError.fileNotFound:
        type = UltraAudioErrorType.fileMissing;
        break;
      case AudioError.focusDenied:
        type = UltraAudioErrorType.focusLoss;
        break;
      case AudioError.routeChange:
        type = UltraAudioErrorType.routeChange;
        break;
      case AudioError.backendUnavailable:
        type = UltraAudioErrorType.startupFail;
        break;
      case AudioError.decodeError:
        type = UltraAudioErrorType.assetLoad;
        break;
      default:
        type = UltraAudioErrorType.playbackFail;
    }

    return UltraAudioError(
      type: type,
      message: message,
      platform: _getPlatformName(),
    );
  }

  String _getPlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Create fallback audio tracks for when manifest is missing
  List<UltraAudioTrack> _createFallbackTracks() {
    return [
      const UltraAudioTrack(
        key: 'focus_alpha',
        filename: 'Alpha.mp3',
        lengthSec: 600.0, // 10 minutes
        sampleRate: 44100,
        channels: 2,
        title: 'Alpha Focus',
        description:
            'Alpha wave binaural beats for enhanced focus and concentration',
      ),
      const UltraAudioTrack(
        key: 'gamma_concentration',
        filename: 'Gamma.mp3',
        lengthSec: 720.0, // 12 minutes
        sampleRate: 44100,
        channels: 2,
        title: 'Gamma Concentration',
        description:
            'Gamma waves for peak concentration and cognitive performance',
      ),
      const UltraAudioTrack(
        key: 'theta_creativity',
        filename: 'Theta.mp3',
        lengthSec: 660.0, // 11 minutes
        sampleRate: 44100,
        channels: 2,
        title: 'Theta Creativity',
        description: 'Theta waves for creative thinking and inspiration',
      ),
    ];
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    await stop();

    _sessionTimer?.cancel();
    _crossfadeTimer?.cancel();

    await _player.dispose();
    await _stateController.close();
    await _errorController.close();
    await _ultraErrorController.close();

    _instance = null;
    // Call super to satisfy must_call_super
    super.dispose();
  }

  // AudioService BaseAudioHandler implementation
  @override
  Future<void> play() async => await resume();

  Future<void> setVolumeAudioService(double volume) async =>
      await setVolume(volume);

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setCrossfade':
        await setCrossfadeEnabled(extras?['enabled'] as bool? ?? true);
        break;
    }
  }

  /// Creates silent audio data in WAV format
  Uint8List _createSilentAudio(Duration duration) {
    final sampleRate = 44100;
    final channels = 2;
    final bitsPerSample = 16;
    final durationSamples =
        (duration.inMicroseconds * sampleRate / 1000000).floor();
    final dataSize = durationSamples * channels * (bitsPerSample ~/ 8);

    // WAV header (44 bytes) + silent data
    final totalSize = 44 + dataSize;
    final bytes = Uint8List(totalSize);

    // WAV header
    bytes.setRange(0, 4, 'RIFF'.codeUnits); // ChunkID
    _writeInt32LE(bytes, 4, totalSize - 8); // ChunkSize
    bytes.setRange(8, 12, 'WAVE'.codeUnits); // Format
    bytes.setRange(12, 16, 'fmt '.codeUnits); // Subchunk1ID
    _writeInt32LE(bytes, 16, 16); // Subchunk1Size
    _writeInt16LE(bytes, 20, 1); // AudioFormat (PCM)
    _writeInt16LE(bytes, 22, channels); // NumChannels
    _writeInt32LE(bytes, 24, sampleRate); // SampleRate
    _writeInt32LE(
        bytes, 28, sampleRate * channels * (bitsPerSample ~/ 8)); // ByteRate
    _writeInt16LE(bytes, 32, channels * (bitsPerSample ~/ 8)); // BlockAlign
    _writeInt16LE(bytes, 34, bitsPerSample); // BitsPerSample
    bytes.setRange(36, 40, 'data'.codeUnits); // Subchunk2ID
    _writeInt32LE(bytes, 40, dataSize); // Subchunk2Size

    // Silent data (already zeros from Uint8List constructor)
    return bytes;
  }

  void _writeInt32LE(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = (value >> 16) & 0xFF;
    bytes[offset + 3] = (value >> 24) & 0xFF;
  }

  void _writeInt16LE(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
  }

  /// Load audio track from assets
  Future<AudioSource?> _loadAudioTrack(UltraAudioTrack track) async {
    try {
      // Use AudioSource.asset directly instead of trying to get URI from ByteData
      return AudioSource.asset('assets/audio/${track.filename}');
    } catch (e) {
      debugPrint('❌ Failed to load audio track ${track.filename}: $e');
      return null;
    }
  }

  /// Get audio source for a specific track
  AudioSource? _getAudioSource(String trackKey) {
    final track = _manifest?.tracks.firstWhere(
      (t) => t.key == trackKey,
      orElse: () => throw Exception('Track not found: $trackKey'),
    );

    if (track == null) return null;

    // Use AudioSource.asset directly
    return AudioSource.asset('assets/audio/${track.filename}');
  }
}

// Duration formatting extension removed to avoid conflicts with other extensions
