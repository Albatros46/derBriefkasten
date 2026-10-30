import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/document.dart';

/// Evrak kayıtları cihazda SQLite içinde, kullanıcıya (Firebase uid) göre ayrılmış tutulur.
class DatabaseService {
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'evrak_kutusu.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            sender TEXT,
            received_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            pages TEXT NOT NULL,
            ocr_text TEXT,
            needs_reply INTEGER NOT NULL DEFAULT 0,
            reply_deadline INTEGER,
            reminder_at INTEGER,
            notification_id INTEGER NOT NULL,
            replied INTEGER NOT NULL DEFAULT 0,
            note TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_documents_user ON documents(user_id)');
      },
    );
  }

  Future<List<Document>> documentsFor(String userId) async {
    final rows = await (await db).query(
      'documents',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'received_at DESC, created_at DESC',
    );
    return rows.map(Document.fromMap).toList();
  }

  Future<void> upsert(Document doc) async {
    await (await db).insert('documents', doc.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    await (await db).delete('documents', where: 'id = ?', whereArgs: [id]);
  }
}
