import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../services/cloudinary_service.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/app_animations.dart';
import '../widgets/root_back_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/top_toast.dart';
import '../utils/constants.dart';
import '../services/app_update_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showImagePickerOptions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D3891).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: Color(0xFF5D3891), size: 22),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(
                      context, authProvider, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D3891).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Color(0xFF5D3891), size: 22),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(
                      context, authProvider, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickAndUploadImage(
    BuildContext context,
    AuthProvider authProvider,
    ImageSource source,
  ) async {
    try {
      final cloudinary = CloudinaryService();
      final imageFile = await cloudinary.pickImage(source: source);

      if (imageFile == null) return;

      if (!context.mounted) return;

      // Show uploading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF5D3891),
                  ),
                  SizedBox(height: 16),
                  Text('Uploading photo...',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      );

      final success = await authProvider.updateProfilePicture(imageFile);

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog

      if (success) {
        showTopToast(context, 'Profile picture updated!');
      } else {
        showTopToast(context, authProvider.error ?? 'Failed to upload image',
            isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      // Dismiss loading dialog if still showing
      Navigator.of(context, rootNavigator: true).pop();
      showTopToast(context, 'Error: ${e.toString()}', isError: true);
    }
  }

  void _showCurrencyPicker(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: kCurrencyOptions.length,
                        itemBuilder: (ctx, index) {
                          final currency = kCurrencyOptions[index];
                          final isSelected = currency['code'] == authProvider.userCurrency;
                          return ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF5D3891)
                                    : const Color(0xFF5D3891).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  currency['symbol'] ?? '\$',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF5D3891),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              currency['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(currency['code'] ?? ''),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF5D3891))
                                : null,
                            onTap: () async {
                              if (!isSelected) {
                                final success = await authProvider
                                    .updateCurrency(currency['code'] ?? 'USD');
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  if (success) {
                                    showTopToast(context, 'Currency updated!');
                                  } else {
                                    showTopToast(context,
                                        'Failed to update currency',
                                        isError: true);
                                  }
                                }
                              } else {
                                Navigator.pop(ctx);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);

    final authProvider = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    return RootBackHandler(
      child: Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScreenEntrance(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 120),
              child: StaggeredColumn(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // ─── Avatar + Name Section ───
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Avatar circle with image or initial
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: primary.withOpacity(0.1),
                        child: authProvider.userProfilePicUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  authProvider.userProfilePicUrl!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return CircleAvatar(
                                      radius: 48,
                                      backgroundColor:
                                          primary.withOpacity(0.15),
                                      child: const CircularProgressIndicator(
                                        color: primary,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                      radius: 48,
                                      backgroundColor:
                                          primary.withOpacity(0.15),
                                      child: Text(
                                        authProvider.userName.isNotEmpty
                                            ? authProvider.userName[0]
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: primary,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : CircleAvatar(
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
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/edit_profile');
                    },
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

                // Notification Settings item
                _buildPreferenceItem(
                  icon: Icons.notifications_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Notifications',
                  subtitle: 'Daily reminders & budget alerts',
                  onTap: () =>
                      Navigator.pushNamed(context, '/notification_settings'),
                ),
                const SizedBox(height: 10),

                // Debts & Loans item
                _buildPreferenceItem(
                  icon: Icons.account_balance_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Debts & Loans',
                  subtitle: 'Track money you owe or are owed',
                  onTap: () => Navigator.pushNamed(context, '/debts'),
                ),
                const SizedBox(height: 10),

                // Savings Goals item
                _buildPreferenceItem(
                  icon: Icons.savings_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Savings Goals',
                  subtitle: 'Track progress toward financial goals',
                  onTap: () => Navigator.pushNamed(context, '/savings_goals'),
                ),
                const SizedBox(height: 10),

                // Recurring Transactions item
                _buildPreferenceItem(
                  icon: Icons.repeat_rounded,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Recurring Transactions',
                  subtitle: 'Manage repeating income & expenses',
                  onTap: () =>
                      Navigator.pushNamed(context, '/recurring_transactions'),
                ),
                const SizedBox(height: 10),

                // Budget Settings item
                _buildPreferenceItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Budget Settings',
                  subtitle: 'Set monthly spending limits',
                  onTap: () => Navigator.pushNamed(context, '/budget_settings'),
                ),
                const SizedBox(height: 10),

                // Currency item
                _buildPreferenceItem(
                  icon: Icons.attach_money,
                  iconBg: primary.withOpacity(0.08),
                  iconColor: primary,
                  title: 'Currency',
                  subtitle: '${getCurrencySymbol(authProvider.userCurrency)} (${authProvider.userCurrency})',
                  onTap: () => _showCurrencyPicker(context, authProvider),
                ),
                const SizedBox(height: 10),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    final sub = snap.hasData
                        ? 'v${snap.data!.version} (${snap.data!.buildNumber})'
                        : '…';
                    return _buildPreferenceItem(
                      icon: Icons.system_update_alt,
                      iconBg: primary.withOpacity(0.08),
                      iconColor: primary,
                      title: 'Check for updates',
                      subtitle: 'Installed $sub · GitHub releases',
                      onTap: () =>
                          AppUpdateService.checkForUpdate(context),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ─── Logout ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.red.withOpacity(0.15),
                      highlightColor: Colors.red.withOpacity(0.08),
                      onTap: authProvider.isLoading
                          ? null
                          : () async {
                              final catProvider = Provider.of<CategoryProvider>(
                                  context,
                                  listen: false);
                              await authProvider.logout();
                              txProvider.clear();
                              catProvider.clear();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login_screen',
                                  (route) => false,
                                );
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: authProvider.isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Logging out...',
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout,
                                      color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          ),
          const FloatingNavBar(currentIndex: 3),
        ],
      ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withOpacity(0.08),
        highlightColor: iconColor.withOpacity(0.04),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
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
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF2D2D2D).withOpacity(0.25),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
