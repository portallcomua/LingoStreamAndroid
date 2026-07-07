import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService({TextRecognitionScript script = TextRecognitionScript.latin})
      : _recognizer = TextRecognizer(script: script);

  final TextRecognizer _recognizer;
  String _lastRecognized = '';

  String get lastRecognized => _lastRecognized;

  Future<String> recognizeInputImage(InputImage image) async {
    final result = await _recognizer.processImage(image);
    final text = result.text.trim();
    if (text.isNotEmpty) {
      _lastRecognized = text;
    }
    return text;
  }

  Future<String> recognizeFromFile(String path) {
    return recognizeInputImage(InputImage.fromFilePath(path));
  }

  void dispose() {
    _recognizer.close();
  }
}
