import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Taranan sayfa görüntülerini telefonun kalıcı uygulama belleğine kopyalar.
class FileService {
  static Directory? _base;

  static Future<Directory> base() async => _base ??= await getApplicationDocumentsDirectory();

  /// Göreli yolu (veritabanında saklanan) mutlak dosyaya çevirir.
  static Future<File> resolve(String relative) async => File(p.join((await base()).path, relative));

  /// [sourcePaths] tarayıcının geçici dosyalarıdır; kalıcı klasöre taşınır.
  /// Zaten kalıcı klasörde olan (göreli) yollar olduğu gibi döner.
  static Future<List<String>> persistPages(String userId, String docId, List<String> sourcePaths) async {
    final root = (await base()).path;
    final relDir = p.join('docs', userId, docId);
    await Directory(p.join(root, relDir)).create(recursive: true);

    final result = <String>[];
    for (final src in sourcePaths) {
      if (!p.isAbsolute(src)) {
        result.add(src);
        continue;
      }
      final ext = p.extension(src).isEmpty ? '.jpg' : p.extension(src);
      final name = '${DateTime.now().microsecondsSinceEpoch}_${result.length}$ext';
      final rel = p.join(relDir, name);
      await File(src).copy(p.join(root, rel));
      result.add(rel);
    }
    return result;
  }

  static Future<void> deleteFiles(Iterable<String> relativePaths) async {
    for (final rel in relativePaths) {
      final f = await resolve(rel);
      if (await f.exists()) await f.delete();
    }
  }

  static Future<void> deleteDocumentDir(String userId, String docId) async {
    final dir = Directory(p.join((await base()).path, 'docs', userId, docId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
