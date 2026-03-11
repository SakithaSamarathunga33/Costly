import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/floating_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);

    final authProvider = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: textMain, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 120),
            child: Column(
              children: [
                // ─── Avatar + Name Section ───
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Avatar circle with initial
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: primary.withOpacity(0.1),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: primary.withOpacity(0.15),
                        child: Text(
                          authProvider.userName.isNotEmpty
                              ? authProvider.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Edit badge
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User name
                Text(
                  authProvider.userName.isNotEmpty
                      ? authProvider.userName
                      : 'User',
                  style: const TextStyle(
                    color: textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),

                // User email
                Text(
                  authProvider.userEmail.isNotEmpty
                      ? authProvider.userEmail
                      : 'user@example.com',
                  style: TextStyle(
                    color: textMain.withOpacity(0.45),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 22),

                // ─── Action Buttons ───
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: primary.withOpacity(0.3), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // ─── PREFERENCES Section ───
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      color: textMain.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Settings item
                _buildPreferenceItem(
                  icon: Icons.settings_outlined,
                  iconBg: primary.withOpacity(0.08),
                  iconColor: primary,
                  title: 'Settings',
                  subtitle: 'Privacy, Notifications, Theme',
                  onTap: () {},
                ),
                const SizedBox(height: 10),

                // Export Data item
                _buildPreferenceItem(
                  icon: Icons.download_outlined,
                  iconBg: primary.withOpacity(0.08),
                  iconColor: primary,
                  title: 'Export Data',
                  subtitle: 'Download your activity history',
                  onTap: () {},
                ),
                const SizedBox(height: 24),

                // ─── Logout ───
                GestureDetector(
                  onTap: () async {
                    await authProvider.logout();
                    txProvider.clear();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login_screen');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            color: Colors.red.withOpacity(0.7), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const FloatingNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  // ─── Preference list item ───
  Widget _buildPreferenceItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2D2D2D),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFF2D2D2D).withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF2D2D2D).withOpacity(0.25),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
