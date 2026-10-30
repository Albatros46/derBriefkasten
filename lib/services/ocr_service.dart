import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Cihaz üzerinde (internetsiz) metin tanıma. Latin alfabesi Almanca ve Türkçeyi kapsar.
class OcrService {
  static Future<String> recognize(List<String> absolutePaths) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final buffer = StringBuffer();
      for (final path in absolutePaths) {
        final result = await recognizer.processImage(InputImage.fromFilePath(path));
        buffer.writeln(result.text);
      }
      return buffer.toString().trim();
    } finally {
      await recognizer.close();
    }
  }
}
