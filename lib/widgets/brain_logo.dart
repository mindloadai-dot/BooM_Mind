import 'package:flutter/material.dart';
import 'dart:math' as math;

class GeometricLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final bool animate;
  final double glowIntensity;

  const GeometricLogo({
    super.key,
    this.size = 60,
    this.color,
    this.animate = true,
    this.glowIntensity = 1.0,
  });

  @override
  State<GeometricLogo> createState() => _GeometricLogoState();
}

class _GeometricLogoState extends State<GeometricLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Initialize particles
    _particles = List.generate(12, (index) {
      return Particle(
        angle: (index * 30) * (math.pi / 180),
        distance: widget.size * 0.6,
        size: 2 + (index % 3),
        speed: 0.5 + (index % 3) * 0.3,
      );
    });

    if (widget.animate) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      _particleController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoColor = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationController,
        _pulseController,
        _particleController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: GeometricElementPainter(
              color: logoColor,
              rotationValue: _rotationController.value,
              pulseValue: _pulseController.value,
              particleValue: _particleController.value,
              particles: _particles,
              animate: widget.animate,
              glowIntensity: widget.glowIntensity,
            ),
          ),
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final double distance;
  final double size;
  final double speed;

  Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
  });
}

class GeometricElementPainter extends CustomPainter {
  final Color color;
  final double rotationValue;
  final double pulseValue;
  final double particleValue;
  final List<Particle> particles;
  final bool animate;
  final double glowIntensity;

  GeometricElementPainter({
    required this.color,
    required this.rotationValue,
    required this.pulseValue,
    required this.particleValue,
    required this.particles,
    required this.animate,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    // Base glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * glowIntensity
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowIntensity);
    
    // Main element paint
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Animated rotation
    final rotation = animate ? rotationValue * 2 * math.pi : 0.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Draw outer triangle with glow
    _drawTriangle(canvas, radius * (1.0 + pulseValue * 0.2), glowPaint);
    _drawTriangle(canvas, radius, mainPaint);
    
    // Draw inner geometric patterns
    _drawInnerGeometry(canvas, radius * 0.6, mainPaint);
    
    // Draw center element
    final centerRadius = radius * 0.15 * (1.0 + pulseValue * 0.3);
    canvas.drawCircle(Offset.zero, centerRadius, mainPaint..style = PaintingStyle.fill);
    
    canvas.restore();

    // Draw animated particles
    if (animate) {
      _drawParticles(canvas, center, size);
    }
  }

  void _drawTriangle(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    
    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 - 90) * (math.pi / 180);
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawInnerGeometry(Canvas canvas, double radius, Paint paint) {
    // Draw smaller triangles
    for (int i = 0; i < 3; i++) {
      final angle = (i * 120) * (math.pi / 180);
      final x = math.cos(angle) * radius * 0.5;
      final y = math.sin(angle) * radius * 0.5;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi);
      
      final smallTrianglePath = Path();
      final smallRadius = radius * 0.2;
      
      for (int j = 0; j < 3; j++) {
        final triAngle = (j * 120 - 90) * (math.pi / 180);
        final triX = math.cos(triAngle) * smallRadius;
        final triY = math.sin(triAngle) * smallRadius;
        
        if (j == 0) {
          smallTrianglePath.moveTo(triX, triY);
        } else {
          smallTrianglePath.lineTo(triX, triY);
        }
      }
      smallTrianglePath.close();
      
      canvas.drawPath(smallTrianglePath, paint);
      canvas.restore();
    }
  }

  void _drawParticles(Canvas canvas, Offset center, Size size) {
    final particlePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final animatedAngle = particle.angle + (particleValue * particle.speed * 2 * math.pi);
      final animatedDistance = particle.distance * (0.8 + 0.4 * math.sin(particleValue * 4 * math.pi));
      
      final x = center.dx + math.cos(animatedAngle) * animatedDistance;
      final y = center.dy + math.sin(animatedAngle) * animatedDistance;
      
      final opacity = 0.3 + 0.7 * math.sin(particleValue * 2 * math.pi + particle.angle);
      particlePaint.color = color.withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (0.5 + 0.5 * math.sin(particleValue * 3 * math.pi)),
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Backwards compatibility alias
typedef BrainLogo = GeometricLogo;