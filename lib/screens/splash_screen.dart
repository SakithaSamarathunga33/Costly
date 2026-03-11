import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Initialize database and check auth state
    _initializeApp();

    // Simulate loading progress bar
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 1.0) {
        timer.cancel();
      } else {
        setState(() {
          _progress += 0.02;
        });
      }
    });
  }

  /// Connect to MongoDB and check if user session exists
  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    // Wait for progress bar to complete before navigating
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return _progress < 1.0;
    });

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Route based on authentication state
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login_screen');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // colors
    const Color primary = Color(0xFF00ADB5);
    const Color bgDark = Color(0xFF222831);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Background Abstract Pattern
          Positioned(
            top: -96,
            left: -96,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -96,
            right: -96,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.1),
              ),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decorative Visual Element Spacer
                  const SizedBox(height: 20),
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(text: 'COST'),
                        TextSpan(
                          text: 'LY',
                          style: TextStyle(color: primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Master your finances with ease',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Progress Bar
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INITIALIZING',
                              style: TextStyle(
                                color: primary.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white10,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Decorative Visual Element
                  const SizedBox(height: 48),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBIoUyggPPOqFKUegzoCUQmlPU82BZjB6kiuy96uGVIQpE7Y17jHhwUQDSdd2uzxpD0mTrUmQg0QK0HBlhLsdWwN7Eq3D4JHel-Lgm9aYgodSvyaFoDHXatrSfrQxhZsOujIrxJS_gjO5soAJbdLe5HH-swqpK23x3cVC1ubEueGYMYG_jkahx4Txin3ShnOuJQGQxcYBd49qF_Vdi4R9pPjS-2bWTlV8pFXbqezPPY1kBdvkioF37fKu-2xjsxFUsRMQR0HMebgvzx',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 48,
                      width: 156,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_up,
                              color: primary, size: 16),
                          const SizedBox(width: 12),
                          Container(
                            width: 96,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Branding
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'POWERED BY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'COSTLY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
