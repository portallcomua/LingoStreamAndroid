import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String? latestVersion;
  final String? releaseUrl;
  final String? error;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    this.latestVersion,
    this.releaseUrl,
    this.error,
  });
}

class UpdateService {
  static const String _latestReleaseApi =
      'https://api.github.com/repos/portallcomua/LingoStreamAndroid/releases/latest';

  static const String _fallbackReleaseUrl =
      'https://github.com/portallcomua/LingoStreamAndroid/releases/latest';

  static Future<UpdateCheckResult> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      final response = await http.get(Uri.parse(_latestReleaseApi));

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          error: 'GitHub update check failed: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final latestVersion =
          (data['tag_name'] ?? '').toString().replaceAll('v', '').trim();

      final releaseUrl =
          (data['html_url'] ?? _fallbackReleaseUrl).toString().trim();

      if (latestVersion.isEmpty) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          error: 'GitHub latest release tag is empty',
        );
      }

      return UpdateCheckResult(
        hasUpdate: latestVersion != currentVersion,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl.isEmpty ? _fallbackReleaseUrl : releaseUrl,
      );
    } catch (e) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: 'unknown',
        error: e.toString(),
      );
    }
  }

  static Future<void> openLatestRelease() async {
    final uri = Uri.parse(_fallbackReleaseUrl);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> openReleaseUrl(String? url) async {
    final uri = Uri.tryParse(url ?? _fallbackReleaseUrl);

    await launchUrl(
      uri ?? Uri.parse(_fallbackReleaseUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
