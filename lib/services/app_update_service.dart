import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../utils/top_toast.dart';
import 'app_update_storage.dart';

/// Checks GitHub Releases for a newer APK and offers download + install (Android).
class AppUpdateService {
  AppUpdateService._();

  static String get _releasesPageUrl {
    final o = kGitHubRepoOwner.trim();
    final r = kGitHubRepoName.trim();
    if (o.isEmpty || r.isEmpty) return 'https://github.com';
    return 'https://github.com/$o/$r/releases';
  }

  static String get _apiLatestUrl {
    final o = kGitHubRepoOwner.trim();
    final r = kGitHubRepoName.trim();
    return 'https://api.github.com/repos/$o/$r/releases/latest';
  }

  static bool get _repoConfigured =>
      kGitHubRepoOwner.trim().isNotEmpty && kGitHubRepoName.trim().isNotEmpty;

  /// True if the GitHub release tag is newer than the installed app (from [PackageInfo]).
  static bool _isNewerVersion(PackageInfo installed, String tagName) {
    final t = tagName.trim();
    if (t.isEmpty) return false;
    final tagVer = t.startsWith('v') ? t.substring(1) : t;
    try {
      final installedVer = Version.parse(_versionNameOnly(installed.version));
      final releaseVer = Version.parse(_versionNameOnly(tagVer));
      return releaseVer > installedVer;
    } catch (_) {
      return false;
    }
  }

  static String _versionNameOnly(String v) {
    final i = v.indexOf('+');
    return i >= 0 ? v.substring(0, i) : v;
  }

  /// Android: user must allow installing APKs for this app (Install unknown apps).
  static Future<bool> _ensureInstallPackagesPermission(
    BuildContext context,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    Future<PermissionStatus> check() async {
      final s = await Permission.requestInstallPackages.status;
      if (s.isGranted) return s;
      return Permission.requestInstallPackages.request();
    }

    var status = await check();
    if (status.isGranted) return true;

    if (!context.mounted) return false;
    final openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Allow app updates'),
        content: const Text(
          'To install the downloaded update, Android needs permission to install '
          'apps from this source.\n\n'
          'Tap Open settings, then enable “Install unknown apps” or “Allow from this source” '
          'for Costly, and return here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );

    if (openSettings == true) {
      await openAppSettings();
      if (!context.mounted) return false;
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Continue update'),
          content: const Text(
            'After you enabled installs for Costly, tap Continue to open the installer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (retry != true) return false;
      status = await check();
      return status.isGranted;
    }
    return false;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    if (!_repoConfigured) {
      showTopToast(
        context,
        'Set kGitHubRepoOwner in lib/utils/constants.dart to your GitHub username.',
        isError: true,
      );
      return;
    }

    if (kIsWeb) {
      final uri = Uri.parse(_releasesPageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final uri = Uri.parse(_releasesPageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!context.mounted) return;
      showTopToast(
        context,
        'Open the releases page in the browser to download for iOS.',
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      showTopToast(
        context,
        'In-app APK updates are only supported on Android.',
      );
      return;
    }

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF5D3891)),
                SizedBox(height: 16),
                Text(
                  'Checking for updates…',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final info = await PackageInfo.fromPlatform();
      final currentLabel =
          '${info.version}${info.buildNumber.isNotEmpty ? '+${info.buildNumber}' : ''}';

      final res = await http.get(
        Uri.parse(_apiLatestUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (res.statusCode == 404) {
        showTopToast(
          context,
          'No GitHub release yet. Push a tag (e.g. v1.0.0) to create one.',
          isError: true,
        );
        return;
      }
      if (res.statusCode != 200) {
        showTopToast(
          context,
          'Could not check updates (${res.statusCode}). Try again later.',
          isError: true,
        );
        return;
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final tagName = map['tag_name'] as String? ?? '';
      final body = map['body'] as String? ?? '';
      final assets = map['assets'] as List<dynamic>? ?? [];

      if (!_isNewerVersion(info, tagName)) {
        showTopToast(
          context,
          'You’re on the latest version (v$currentLabel).',
        );
        return;
      }

      String? apkUrl;
      String? apkName;
      for (final raw in assets) {
        final a = raw as Map<String, dynamic>;
        final name = a['name'] as String? ?? '';
        final url = a['browser_download_url'] as String?;
        if (url != null && name.toLowerCase().endsWith('.apk')) {
          apkUrl = url;
          apkName = name;
          break;
        }
      }

      if (apkUrl == null || apkUrl.isEmpty) {
        showTopToast(
          context,
          'Release $tagName has no .apk file. Opening releases on GitHub.',
          isError: true,
        );
        final uri = Uri.parse(_releasesPageUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }

      if (!context.mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update available'),
          content: SingleChildScrollView(
            child: Text(
              'Latest: $tagName\nInstalled: v$currentLabel\n\n'
              '${apkName != null ? 'File: $apkName\n\n' : ''}'
              '${body.length > 400 ? '${body.substring(0, 400)}…' : body}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Download & install'),
            ),
          ],
        ),
      );

      if (go != true || !context.mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5D3891)),
                  SizedBox(height: 16),
                  Text(
                    'Downloading…',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final apkRes = await http.get(Uri.parse(apkUrl));
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (apkRes.statusCode != 200) {
        showTopToast(
          context,
          'Download failed (${apkRes.statusCode}).',
          isError: true,
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final fileName = apkName ?? 'Costly-update.apk';
      final path = await saveApkToTemp(dir.path, fileName, apkRes.bodyBytes);

      if (!context.mounted) return;
      final allowed = await _ensureInstallPackagesPermission(context);
      if (!context.mounted) return;
      if (!allowed) {
        showTopToast(
          context,
          'Install permission is required to update. Enable it in Settings, then tap Check for updates again.',
          isError: true,
        );
        return;
      }

      final result = await OpenFile.open(path);
      if (!context.mounted) return;
      if (result.type != ResultType.done) {
        showTopToast(
          context,
          'Could not open the installer. Try Files → Downloads, or enable installs for Costly in Settings.',
          isError: true,
        );
      }
    } catch (e, st) {
      debugPrint('AppUpdateService: $e\n$st');
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        showTopToast(
          context,
          'Update check failed: $e',
          isError: true,
        );
      }
    }
  }
}
