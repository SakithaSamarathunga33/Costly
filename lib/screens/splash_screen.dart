import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _timer;
  bool _hasNavigated = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late AnimationController _ambientController;
  late AnimationController _breathController;
  late AnimationController _ringsController;
  late AnimationController _waveController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _logoController.forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _ringsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _initializeApp();

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 1.0) {
        timer.cancel();
      } else {
        setState(() {
          _progress += 0.017;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return _progress < 1.0;
    });

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (authProvider.isLoggedIn) {
      final txProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      await txProvider.fetchTransactions(authProvider.userId);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home_dashboard',
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login_screen',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _logoController.dispose();
    _ambientController.dispose();
    _breathController.dispose();
    _ringsController.dispose();
    _waveController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color accent = Color(0xFFB794F4);
    const Color deep = Color(0xFF3D2666);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            final t = _ambientController.value;
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + t * 0.15, -1),
                  end: Alignment(1 - t * 0.1, 1.05),
                  colors: [
                    Color.lerp(
                      const Color(0xFFFDFCFF),
                      const Color(0xFFE8E0F7),
                      (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.35,
                    )!,
                    const Color(0xFFF0EBFA),
                    Color.lerp(
                      const Color(0xFFE4DCF5),
                      const Color(0xFFD4C8ED),
                      (math.cos(t * math.pi * 2) * 0.5 + 0.5),
                    )!,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
              child: Stack(
                children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MeshGridPainter(
                    progress: t,
                    color: primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                top: -100,
                right: -80,
                child: _GlowOrb(
                  size: 300,
                  color: primary.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -120,
                child: _GlowOrb(
                  size: 340,
                  color: accent.withValues(alpha: 0.14),
                ),
              ),
              Positioned(
                bottom: -20,
                right: -30,
                child: _GlowOrb(
                  size: 200,
                  color: deep.withValues(alpha: 0.12),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _logoController,
                        _breathController,
                        _ringsController,
                      ]),
                      builder: (context, _) {
                        final breath = 1.0 +
                            0.035 *
                                math.sin(_breathController.value * math.pi * 2);
                        return SizedBox(
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              RotationTransition(
                                turns: _ringsController,
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _OrbitRingPainter(
                                    primary: primary,
                                    accent: accent,
                                    phase: 0,
                                  ),
                                ),
                              ),
                              RotationTransition(
                                turns: ReverseAnimation(_ringsController),
                                child: CustomPaint(
                                  size: const Size(168, 168),
                                  painter: _OrbitRingPainter(
                                    primary: accent,
                                    accent: primary,
                                    phase: 1,
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: _logoScale.value * breath,
                                child: Opacity(
                                  opacity: _logoOpacity.value,
                                  child: const _LogoCard(
                                    primary: Color(0xFF5D3891)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF2D2D2D),
                          primary,
                          deep,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        kAppDisplayName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.2,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Smart expense tracking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF2D2D2D).withValues(alpha: 0.42),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(flex: 2),
                    _WaveLoader(
                      controller: _waveController,
                      primary: primary,
                      accent: accent,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return _IndeterminateShimmerBar(
                            progress: _shimmerController.value,
                            primary: primary,
                            accent: accent,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Loading experience',
                      style: TextStyle(
                        color: primary.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'v$kAppVersionLabel',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.28),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: primary.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Encrypted',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              'assets/images/logo2.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            kAppDisplayName,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.38),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final Color primary;

  const _LogoCard({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 18),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.95),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27.5),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Transform.scale(
            scale: 1.28,
            child: Image.asset(
              'assets/images/logo2.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeshGridPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MeshGridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    const step = 42.0;
    final offset = progress * 20;
    for (double x = -offset % step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offset % step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.72],
          ),
        ),
      ),
    );
  }
}

/// Two offset arcs for a soft orbit feel (counter-rotated by parent).
class _OrbitRingPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final int phase;

  _OrbitRingPainter({
    required this.primary,
    required this.accent,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: r);

    final sweep = phase == 0 ? math.pi * 1.15 : math.pi * 0.95;
    final start = phase == 0 ? -math.pi / 2 : math.pi * 0.2;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          primary.withValues(alpha: 0.05),
          primary,
          accent,
          primary.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) => false;
}

class _WaveLoader extends StatelessWidget {
  final AnimationController controller;
  final Color primary;
  final Color accent;

  const _WaveLoader({
    required this.controller,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final phase = controller.value * 2 * math.pi + i * 0.65;
            final h = 12.0 + 22.0 * (math.sin(phase) * 0.5 + 0.5);
            final t = (math.sin(phase) * 0.5 + 0.5);
            final c = Color.lerp(primary, accent, t)!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      c.withValues(alpha: 0.35),
                      c,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Sliding gradient bar (indeterminate — not tied to fake % progress).
class _IndeterminateShimmerBar extends StatelessWidget {
  final double progress;
  final Color primary;
  final Color accent;

  const _IndeterminateShimmerBar({
    required this.progress,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final slide = (progress * 1.4 - 0.2) * w;
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            width: w,
            height: 4,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Container(
                  color: primary.withValues(alpha: 0.12),
                ),
                Positioned(
                  left: slide - w * 0.35,
                  width: w * 0.45,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          accent.withValues(alpha: 0.9),
                          primary,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
