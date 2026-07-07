import 'package:flutter/services.dart';

import '../config/app_config.dart';

enum CaptureMode {
  screenOverlay,
  camera,
}

class CaptureService {
  CaptureService._();

  static const _channel = MethodChannel(AppConfig.captureChannel);

  static Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<bool> startScreenCapture({
    required String sourceLang,
    required String targetLang,
    required String mode,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('startCapture', {
            'sourceLang': sourceLang,
            'targetLang': targetLang,
            'mode': mode,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> stopScreenCapture() async {
    try {
      await _channel.invokeMethod<void>('stopCapture');
    } catch (_) {}
  }
}
