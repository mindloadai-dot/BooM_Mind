import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/unified_design_system.dart';

/// Demo screen to showcase the MP4 video logo
class AppIconDemoScreen extends StatefulWidget {
  const AppIconDemoScreen({super.key});

  @override
  State<AppIconDemoScreen> createState() => _AppIconDemoScreenState();
}

class _AppIconDemoScreenState extends State<AppIconDemoScreen>
    with TickerProviderStateMixin {
  bool _showGlow = true;
  bool _autoPlay = true;
  double _iconSize = 150;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.asset('assets/images/logo.mp4.mp4');
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0);

      if (_autoPlay) {
        await _videoController!.play();
      }

      if (mounted) {
        setState(() {
          _videoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MP4 Video Logo Demo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: UnifiedSpacing.screenPadding,
        child: Column(
          children: [
            // Main MP4 video logo
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_glowAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: _iconSize,
                      height: _iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _showGlow
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(_glowAnimation.value * 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6)
                                      .withOpacity(_glowAnimation.value * 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: _buildVideoContent(),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: UnifiedSpacing.xl),

            // Controls
            _buildControls(tokens),

            SizedBox(height: UnifiedSpacing.xl),

            // Different sizes showcase
            _buildSizeShowcase(tokens),

            SizedBox(height: UnifiedSpacing.xl),

            // Features showcase
            _buildFeaturesShowcase(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_videoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      // Fallback to gradient loading
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1), // Electric blue
              const Color(0xFF8B5CF6), // Purple
              const Color(0xFFEC4899), // Pink
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }
  }

  Widget _buildControls(SemanticTokens tokens) {
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Size slider
          Row(
            children: [
              Text(
                'Size: ${_iconSize.round()}',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _iconSize,
                  min: 50,
                  max: 300,
                  divisions: 25,
                  onChanged: (value) {
                    setState(() => _iconSize = value);
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Glow toggle
          Row(
            children: [
              Text(
                'Show Glow',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _showGlow,
                onChanged: (value) {
                  setState(() => _showGlow = value);
                },
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Autoplay toggle
          Row(
            children: [
              Text(
                'Auto Play',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _autoPlay,
                onChanged: (value) async {
                  setState(() => _autoPlay = value);
                  if (_videoController != null) {
                    if (value) {
                      await _videoController!.play();
                    } else {
                      await _videoController!.pause();
                    }
                  }
                },
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeShowcase(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size Showcase',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [50.0, 100.0, 150.0].map((size) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _showGlow
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: _buildVideoContent(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesShowcase(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(tokens, '🎬 MP4 Video Asset',
              'Direct video playback with proper aspect ratio'),
          _buildFeatureItem(tokens, '✨ Neon Glow Effects',
              'Dynamic glow animations with multiple color layers'),
          _buildFeatureItem(tokens, '🔄 Smooth Animations',
              'Pulse and glow animations for enhanced visual appeal'),
          _buildFeatureItem(tokens, '📱 Responsive Design',
              'Adapts to different screen sizes and orientations'),
          _buildFeatureItem(tokens, '⚡ Performance Optimized',
              'Efficient video playback with fallback support'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      SemanticTokens tokens, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
