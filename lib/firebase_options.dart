// Bu dosya, proje klasöründe `flutterfire configure` çalıştırıldığında
// kendi Firebase projenizin ayarlarıyla otomatik olarak yeniden oluşturulur.
// O zamana kadar uygulama açılışta kurulum uyarısı gösterir (bkz. README.md).
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'firebase_options.dart henüz oluşturulmadı. "flutterfire configure" çalıştırın.',
      );
}
