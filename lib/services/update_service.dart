import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String currentBuildNumber;
  final String? latestVersion;
  final String? latestBuildNumber;
  final String? releaseUrl;
  final String? releaseNotes;
  final String? error;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    this.currentBuildNumber = '',
    this.latestVersion,
    this.latestBuildNumber,
    this.releaseUrl,
    this.releaseNotes,
    this.error,
  });

  String get fullCurrentVersion =>
      currentBuildNumber.isNotEmpty ? '$currentVersion ($currentBuildNumber)' : currentVersion;

  String get fullLatestVersion => (latestBuildNumber != null && latestBuildNumber!.isNotEmpty)
      ? '$latestVersion ($latestBuildNumber)'
      : (latestVersion ?? '');
}

class UpdateService {
  static const String _latestReleaseApi =
      'https://api.github.com/repos/portallcomua/LingoStreamAndroid/releases/latest';
  static const String _fallbackReleaseUrl =
      'https://github.com/portallcomua/LingoStreamAndroid/releases/latest';

  static Future<void> init() async {
    await PackageInfo.fromPlatform();
  }

  static Future<UpdateCheckResult> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      final currentBuildNumber = packageInfo.buildNumber.trim();

      final response = await http.get(
        Uri.parse(_latestReleaseApi),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'LingoStream-App',
        },
      );

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          error: 'GitHub update check failed: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      var latestVersion = (data['tag_name'] ?? '').toString().replaceAll('v', '').trim();

      String? latestBuildNumber;
      if (latestVersion.contains('+')) {
        final parts = latestVersion.split('+');
        latestVersion = parts[0];
        latestBuildNumber = parts[1];
      }

      final releaseUrl = (data['html_url'] ?? _fallbackReleaseUrl).toString().trim();
      final releaseNotes = (data['body'] ?? '').toString().trim();

      final assets = data['assets'] as List<dynamic>?;
      String? apkDownloadUrl;
      if (assets != null) {
        for (final asset in assets) {
          if ((asset['name'] as String?)?.endsWith('.apk') ?? false) {
            apkDownloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      if (latestVersion.isEmpty) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          error: 'GitHub latest release tag is empty',
        );
      }

      final hasUpdate = _compareVersions(currentVersion, latestVersion) < 0;

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        releaseUrl: apkDownloadUrl ?? releaseUrl,
        releaseNotes: releaseNotes,
      );
    } catch (error) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: 'unknown',
        error: error.toString(),
      );
    }
  }

  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final parts2 = v2.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  static Future<bool> openReleaseUrl(String? url) async {
    final uri = Uri.tryParse(url ?? _fallbackReleaseUrl);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
