import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
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
    final cs = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
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

  void _showChangePasswordSheet(
      BuildContext context, AuthProvider authProvider) {
    final cs = Theme.of(context).colorScheme;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 20),
              _passwordField(
                ctx,
                controller: currentCtrl,
                hint: 'Current password',
                obscure: obscureCurrent,
                onToggle: () =>
                    setSheet(() => obscureCurrent = !obscureCurrent),
              ),
              const SizedBox(height: 12),
              _passwordField(
                ctx,
                controller: newCtrl,
                hint: 'New password',
                obscure: obscureNew,
                onToggle: () => setSheet(() => obscureNew = !obscureNew),
              ),
              const SizedBox(height: 12),
              _passwordField(
                ctx,
                controller: confirmCtrl,
                hint: 'Confirm new password',
                obscure: obscureConfirm,
                onToggle: () =>
                    setSheet(() => obscureConfirm = !obscureConfirm),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3891),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (newCtrl.text != confirmCtrl.text) {
                      showTopToast(ctx, 'Passwords do not match',
                          isError: true);
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      showTopToast(ctx, 'Password must be at least 6 characters',
                          isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    final ok = await authProvider.changePassword(
                      currentPassword: currentCtrl.text,
                      newPassword: newCtrl.text,
                    );
                    if (!context.mounted) return;
                    if (ok) {
                      showTopToast(context, 'Password updated successfully');
                    } else {
                      showTopToast(
                          context,
                          authProvider.error ??
                              'Failed to change password',
                          isError: true);
                    }
                  },
                  child: const Text('Update Password',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, AuthProvider authProvider) {
    final cs = Theme.of(context).colorScheme;
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: cs.surfaceContainerLow,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Account',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This will permanently delete your account and all data. This cannot be undone.',
                style:
                    TextStyle(fontSize: 14, color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Enter your password to confirm',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setDialog(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await authProvider.deleteAccount(
                    password: passwordCtrl.text);
                if (!context.mounted) return;
                if (ok) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login_screen', (_) => false);
                } else {
                  showTopToast(
                      context,
                      authProvider.error ?? 'Failed to delete account',
                      isError: true);
                }
              },
              child: const Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  bool _isGoogleUser() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  }

  void _showThemePicker(BuildContext context, ThemeProvider themeProvider) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              trailing: themeProvider.mode == ThemeMode.light
                  ? const Icon(Icons.check, color: Color(0xFF5D3891))
                  : null,
              onTap: () {
                themeProvider.setMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              trailing: themeProvider.mode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Color(0xFF5D3891))
                  : null,
              onTap: () {
                themeProvider.setMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto_outlined),
              title: const Text('System default'),
              trailing: themeProvider.mode == ThemeMode.system
                  ? const Icon(Icons.check, color: Color(0xFF5D3891))
                  : null,
              onTap: () {
                themeProvider.setMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, AuthProvider authProvider) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
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
                    Text(
                      'Select Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    return RootBackHandler(
      child: Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: cs.onSurface,
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
                // --- Avatar + Name Section ---
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
                            border: Border.all(color: cs.surface, width: 2.5),
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
                  style: TextStyle(
                    color: cs.onSurface,
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
                    color: cs.onSurface.withOpacity(0.45),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 22),

                // --- Action Buttons ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/edit_profile');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: cs.surfaceContainerLow,
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

                // --- PREFERENCES Section ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Appearance item (hidden)
                // _buildPreferenceItem(context,
                //   icon: Icons.dark_mode_outlined,
                //   iconBg: primary.withValues(alpha: 0.08),
                //   iconColor: primary,
                //   title: 'Appearance',
                //   subtitle: themeProvider.mode == ThemeMode.dark
                //       ? 'Dark mode'
                //       : themeProvider.mode == ThemeMode.light
                //           ? 'Light mode'
                //           : 'System default',
                //   onTap: () => _showThemePicker(context, themeProvider),
                // ),
                // const SizedBox(height: 10),

                // Notification Settings item
                _buildPreferenceItem(context,
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
                _buildPreferenceItem(context,
                  icon: Icons.account_balance_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Debts & Loans',
                  subtitle: 'Track money you owe or are owed',
                  onTap: () => Navigator.pushNamed(context, '/debts'),
                ),
                const SizedBox(height: 10),

                // Savings Goals item
                _buildPreferenceItem(context,
                  icon: Icons.savings_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Savings Goals',
                  subtitle: 'Track progress toward financial goals',
                  onTap: () => Navigator.pushNamed(context, '/savings_goals'),
                ),
                const SizedBox(height: 10),

                // Recurring Transactions item
                _buildPreferenceItem(context,
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
                _buildPreferenceItem(context,
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: primary.withValues(alpha: 0.08),
                  iconColor: primary,
                  title: 'Budget Settings',
                  subtitle: 'Set monthly spending limits',
                  onTap: () => Navigator.pushNamed(context, '/budget_settings'),
                ),
                const SizedBox(height: 10),

                // Currency item
                _buildPreferenceItem(context,
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
                        : '�';
                    return _buildPreferenceItem(context,
                      icon: Icons.system_update_alt,
                      iconBg: primary.withOpacity(0.08),
                      iconColor: primary,
                      title: 'Check for updates',
                      subtitle: 'Installed $sub � GitHub releases',
                      onTap: () =>
                          AppUpdateService.checkForUpdate(context),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- ACCOUNT Section ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Hide Change Password for Google sign-in users
                if (!_isGoogleUser()) ...[
                  _buildPreferenceItem(context,
                    icon: Icons.lock_outline_rounded,
                    iconBg: primary.withValues(alpha: 0.08),
                    iconColor: primary,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _showChangePasswordSheet(context, authProvider),
                  ),
                  const SizedBox(height: 10),
                ],

                _buildPreferenceItem(context,
                  icon: Icons.delete_forever_outlined,
                  iconBg: Colors.red.withValues(alpha: 0.08),
                  iconColor: Colors.red,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove your account and data',
                  onTap: () =>
                      _showDeleteAccountDialog(context, authProvider),
                ),
                const SizedBox(height: 24),

                // --- Logout ---
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

  // --- Preference list item ---
  Widget _buildPreferenceItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
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
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
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
