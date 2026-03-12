import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable floating glassmorphic bottom navigation bar with a
/// notched center FAB (+) button. Use this in any screen's body
/// by wrapping your content in a [Stack] and placing this widget
/// at the bottom via [Positioned].
///
/// Example usage:
/// ```
/// Stack(
///   children: [
///     // your main content here...
///     FloatingNavBar(currentIndex: 0),
///   ],
/// )
/// ```
class FloatingNavBar extends StatelessWidget {
  /// Which tab is currently active: 0=Home, 1=History, 2=Budget, 3=Profile
  final int currentIndex;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
  });

  static const Color _primary = Color(0xFF5D3891);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ─ Dark blurred nav bar with notch ─
            Positioned.fill(
              child: ClipPath(
                clipper: _NotchedNavClipper(
                  notchRadius: 34,
                  notchMargin: 8,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3891),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D3891).withOpacity(0.35),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─ Nav items row ─
            Positioned(
              left: 0,
              right: 0,
              top: 12,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.home,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    route: '/home_dashboard',
                    index: 0,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.receipt_long,
                    label: 'History',
                    isActive: currentIndex == 1,
                    route: '/transactions_history',
                    index: 1,
                  ),
                  // Spacer for FAB notch
                  const SizedBox(width: 64),
                  _buildNavItem(
                    context: context,
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    isActive: currentIndex == 2,
                    route: '/analytics',
                    index: 2,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person,
                    label: 'Profile',
                    isActive: currentIndex == 3,
                    route: '/profile',
                    index: 3,
                  ),
                ],
              ),
            ),

            // ─ FAB (+) button sitting in the notch gap ─
            Positioned(
              top: -24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5D3891), Color(0xFF7B52AB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/add_expense');
                      },
                      customBorder: const CircleBorder(),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required String route,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.6),
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──── Custom clipper for the notched floating nav bar ────
class _NotchedNavClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchMargin;

  _NotchedNavClipper({
    this.notchRadius = 32,
    this.notchMargin = 8,
  });

  @override
  Path getClip(Size size) {
    final double totalRadius = notchRadius + notchMargin;
    final double centerX = size.width / 2;
    final double barRadius = 28.0;

    final path = Path();

    // Start at top-left with rounded corner
    path.moveTo(barRadius, 0);

    // Top edge → left side of notch
    path.lineTo(centerX - totalRadius, 0);

    // Notch curve (semicircular arc going upward)
    path.arcToPoint(
      Offset(centerX + totalRadius, 0),
      radius: Radius.circular(totalRadius),
      clockwise: false,
    );

    // Top edge → right side
    path.lineTo(size.width - barRadius, 0);

    // Top-right corner
    path.arcToPoint(
      Offset(size.width, barRadius),
      radius: Radius.circular(barRadius),
    );

    // Right edge
    path.lineTo(size.width, size.height - barRadius);

    // Bottom-right corner
    path.arcToPoint(
      Offset(size.width - barRadius, size.height),
      radius: Radius.circular(barRadius),
    );

    // Bottom edge
    path.lineTo(barRadius, size.height);

    // Bottom-left corner
    path.arcToPoint(
      Offset(0, size.height - barRadius),
      radius: Radius.circular(barRadius),
    );

    // Left edge
    path.lineTo(0, barRadius);

    // Top-left corner
    path.arcToPoint(
      Offset(barRadius, 0),
      radius: Radius.circular(barRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _NotchedNavClipper oldClipper) {
    return oldClipper.notchRadius != notchRadius ||
        oldClipper.notchMargin != notchMargin;
  }
}
