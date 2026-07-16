import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Logo: fades + scales in first
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Footer branding: fades in last
    _footerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Navigate once animation settles + a brief hold
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, _) => const DashboardScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Logo scales with screen width instead of a fixed px value,
    // so it looks right on small phones and tablets alike.
    final logoSize = (size.width * 0.32).clamp(96.0, 160.0);

    return Scaffold(
      body: Stack(
        children: [
          // Organic mesh-style background — blurred colour blobs
          // instead of a flat linear gradient, matching the wavy
          // blue → yellow → orange → red look of the reference image.
          Positioned.fill(child: CustomPaint(painter: _MeshGradientPainter())),

          SafeArea(
            child: Stack(
              children: [
                // Centered logo
                Center(
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: SizedBox(
                        height: logoSize,
                        width: logoSize,
                        child: SvgPicture.asset(
                          'assets/icons/mdpi.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom BR7 branding — centered, proper margins
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: FadeTransition(
                    opacity: _footerFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/br7.png',
                                height: 26,
                                width: 26,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Powered by BR7 Technologies & Co.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FMSons.bgLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'www.br7tech.dev',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: FMSons.bgLight.withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Paints an organic, mesh-style background: a base vertical gradient
/// (deep blue → red) with several soft, blurred colour blobs layered
/// on top to create the irregular, wavy boundaries seen in the
/// reference image — rather than clean straight gradient bands.
class _MeshGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base vertical gradient: deep blue at the top fading to red at
    // the bottom. This sits underneath the blobs and shows through
    // wherever they don't cover.
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A167A), Color(0xFFB01515)],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Soft blurred blobs, positioned to mimic the uneven "flame-like"
    // rise of yellow/orange through the blue at the top of the
    // reference image, plus richer orange/red pooling lower down.
    final blobs = <_Blob>[
      _Blob(dx: 0.02, dy: 0.68, r: 0.34, color: const Color(0xFFF2C230)),
      _Blob(dx: 0.28, dy: 0.52, r: 0.38, color: const Color(0xFFF6C93A)),
      _Blob(dx: 0.55, dy: 0.40, r: 0.40, color: const Color(0xFFF6A72A)),
      _Blob(dx: 0.80, dy: 0.28, r: 0.36, color: const Color(0xFFF2C230)),
      _Blob(dx: 1.00, dy: 0.58, r: 0.34, color: const Color(0xFFF2790A)),
      _Blob(dx: 0.15, dy: 0.85, r: 0.44, color: const Color(0xFFF2790A)),
      _Blob(dx: 0.50, dy: 0.90, r: 0.48, color: const Color(0xFFEE4B11)),
      _Blob(dx: 0.85, dy: 0.82, r: 0.46, color: const Color(0xFFEE1B1B)),
      _Blob(dx: 0.50, dy: 1.05, r: 0.55, color: const Color(0xFFE60F0F)),
    ];

    for (final b in blobs) {
      final center = Offset(size.width * b.dx, size.height * b.dy);
      final radius = size.width * b.r;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color, b.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => false;
}

class _Blob {
  final double dx;
  final double dy;
  final double r;
  final Color color;

  const _Blob({
    required this.dx,
    required this.dy,
    required this.r,
    required this.color,
  });
}
