import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'ocr_service.dart';
import 'translation_service.dart';

typedef SubtitleCallback = void Function(String original, String translated);

class CameraCaptureService {
  CameraCaptureService({
    required OcrService ocrService,
  }) : _ocrService = ocrService;

  final OcrService _ocrService;
  CameraController? _controller;
  Timer? _timer;
  bool _busy = false;
  String _lastProcessed = '';

  CameraController? get controller => _controller;
  bool get isRunning => _timer != null;

  Future<bool> start({
    required SubtitleCallback onSubtitle,
    CameraLensDirection lensDirection = CameraLensDirection.back,
  }) async {
    if (isRunning) return true;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return false;

    final camera = cameras.firstWhere(
      (item) => item.lensDirection == lensDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    _timer = Timer.periodic(AppConfig.ocrInterval, (_) => _scanFrame(onSubtitle));
    return true;
  }

  Future<void> _scanFrame(SubtitleCallback onSubtitle) async {
    final controller = _controller;
    if (_busy || controller == null || !controller.value.isInitialized) return;

    _busy = true;
    try {
      final photo = await controller.takePicture();
      final text = await _ocrService.recognizeFromFile(photo.path);
      if (text.length < 4 || text == _lastProcessed) return;

      _lastProcessed = text;
      final translated = await TranslationService.translate(text);
      onSubtitle(text, translated);
    } catch (error) {
      debugPrint('Camera OCR error: $error');
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _lastProcessed = '';

    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
