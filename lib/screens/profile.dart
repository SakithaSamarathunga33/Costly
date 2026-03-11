import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00ADB5);
    const Color bgDark = Color(0xFF222831);
    const Color cardDark = Color(0xFF393E46);
    const Color textMain = Color(0xFFEEEEEE);

    final authProvider = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User avatar and info card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  // Avatar with user initial
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primary,
                    child: Text(
                      authProvider.userName.isNotEmpty
                          ? authProvider.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.userName,
                    style: const TextStyle(
                      color: textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.userEmail,
                    style: TextStyle(
                      color: textMain.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account summary card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Summary',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                      'Total Transactions',
                      '${txProvider.transactions.length}',
                      Icons.receipt_long,
                      primary,
                      textMain),
                  const Divider(color: Colors.white10, height: 24),
                  _buildSummaryRow(
                      'Total Income',
                      currencyFormat.format(txProvider.totalIncome),
                      Icons.arrow_downward,
                      Colors.green,
                      textMain),
                  const Divider(color: Colors.white10, height: 24),
                  _buildSummaryRow(
                      'Total Expenses',
                      currencyFormat.format(txProvider.totalExpenses),
                      Icons.arrow_upward,
                      Colors.red,
                      textMain),
                  const Divider(color: Colors.white10, height: 24),
                  _buildSummaryRow(
                      'Current Balance',
                      currencyFormat.format(txProvider.currentBalance),
                      Icons.account_balance_wallet,
                      primary,
                      textMain),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                      Icons.notifications_outlined, 'Notifications',
                      textMain: textMain),
                  _buildSettingsItem(Icons.lock_outline, 'Privacy',
                      textMain: textMain),
                  _buildSettingsItem(Icons.help_outline, 'Help & Support',
                      textMain: textMain),
                  _buildSettingsItem(Icons.info_outline, 'About',
                      textMain: textMain),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
                txProvider.clear();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login_screen');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.red, width: 1),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Logout',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon,
      Color iconColor, Color textMain) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: textMain.withOpacity(0.7), fontSize: 14)),
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String label,
      {required Color textMain}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: textMain.withOpacity(0.5), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: textMain.withOpacity(0.8), fontSize: 14)),
          ),
          Icon(Icons.chevron_right, color: textMain.withOpacity(0.3)),
        ],
      ),
    );
  }
}
