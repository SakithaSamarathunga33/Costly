import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../utils/top_toast.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  static const _keyEnabled = 'notif_daily_enabled';
  static const _keyHour = 'notif_daily_hour';
  static const _keyMinute = 'notif_daily_minute';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool(_keyEnabled) ?? false;
      _reminderTime = TimeOfDay(
        hour: prefs.getInt(_keyHour) ?? 20,
        minute: prefs.getInt(_keyMinute) ?? 0,
      );
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, _dailyReminder);
    await prefs.setInt(_keyHour, _reminderTime.hour);
    await prefs.setInt(_keyMinute, _reminderTime.minute);
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final svc = NotificationService();
    if (value) {
      final granted = await svc.requestPermission();
      if (!granted) {
        if (mounted) {
          showTopToast(context, 'Notification permission denied', isError: true);
        }
        return;
      }
      await svc.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await svc.cancelDailyReminder();
    }
    setState(() => _dailyReminder = value);
    await _savePrefs();
    if (mounted) {
      showTopToast(
          context,
          value
              ? 'Daily reminder set for ${_reminderTime.format(context)}'
              : 'Daily reminder disabled');
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF5D3891)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    if (_dailyReminder) {
      await NotificationService().scheduleDailyReminder(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
    await _savePrefs();
    if (mounted) {
      showTopToast(context, 'Reminder time updated');
    }
  }

  Future<void> _testNotification() async {
    final granted = await NotificationService().requestPermission();
    if (!granted) {
      if (mounted) {
        showTopToast(context, 'Permission denied', isError: true);
      }
      return;
    }
    await NotificationService().showInstant(
      id: 99,
      title: 'Costly Test Notification',
      body: 'Notifications are working correctly!',
    );
    if (mounted) showTopToast(context, 'Test notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const primary = Color(0xFF5D3891);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Daily reminder section
          _sectionLabel('Daily Reminder', cs),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Enable daily reminder',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  subtitle: Text(
                      'Remind me to log expenses each day',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant)),
                  value: _dailyReminder,
                  onChanged: _toggleDailyReminder,
                  activeThumbColor: primary,
                  activeTrackColor: primary.withValues(alpha: 0.4),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  enabled: _dailyReminder,
                  leading: const Icon(Icons.access_time_rounded,
                      color: primary),
                  title: const Text('Reminder time',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    _reminderTime.format(context),
                    style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  onTap: _dailyReminder ? _pickTime : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget alerts section
          _sectionLabel('Budget Alerts', cs),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_outlined,
                      color: primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget exceeded alerts',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      Text(
                          'Automatically notified when you exceed budget thresholds (70%, 90%, 100%)',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2ECC71), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Test notification
          _sectionLabel('Test', cs),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notifications_outlined, color: primary),
              label: const Text('Send test notification',
                  style:
                      TextStyle(color: primary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cs.onSurface));
}
