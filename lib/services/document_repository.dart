import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/document.dart';
import 'database_service.dart';
import 'file_service.dart';
import 'notification_service.dart';

/// Oturum açmış kullanıcının evraklarını yönetir ve ekranlara bildirir.
class DocumentRepository extends ChangeNotifier {
  DocumentRepository(this.userId, this._db) {
    load();
  }

  final String userId;
  final DatabaseService _db;

  List<Document> _documents = [];
  bool loading = true;

  List<Document> get documents => List.unmodifiable(_documents);

  List<Document> get openReminders {
    final list = _documents.where((d) => d.hasOpenReminder).toList();
    DateTime key(Document d) => d.replyDeadline ?? d.reminderAt ?? DateTime(9999);
    list.sort((a, b) => key(a).compareTo(key(b)));
    return list;
  }

  Document? byId(String id) {
    for (final d in _documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> load() async {
    _documents = await _db.documentsFor(userId);
    loading = false;
    notifyListeners();
  }

  /// Kaydeder ve hatırlatma bildirimini günceller. [lang] bildirim metninin dilidir.
  Future<void> save(Document doc, {required String lang}) async {
    await _db.upsert(doc);
    await _syncReminder(doc, lang);
    await load();
  }

  Future<void> markReplied(Document doc) async {
    doc.replied = true;
    await _db.upsert(doc);
    await NotificationService.cancel(doc.notificationId);
    await load();
  }

  Future<void> delete(Document doc) async {
    await NotificationService.cancel(doc.notificationId);
    await _db.delete(doc.id);
    await FileService.deleteDocumentDir(userId, doc.id);
    await load();
  }

  Future<void> _syncReminder(Document doc, String lang) async {
    if (!doc.hasOpenReminder || doc.reminderAt == null) {
      await NotificationService.cancel(doc.notificationId);
      return;
    }
    final deadline = doc.replyDeadline == null
        ? ''
        : ' – ${trFor(lang, 'deadlinePrefix')}: ${DateFormat.yMd(lang).format(doc.replyDeadline!)}';
    await NotificationService.schedule(
      id: doc.notificationId,
      when: doc.reminderAt!,
      title: trFor(lang, 'reminderNotifTitle'),
      body: '${doc.title}$deadline',
    );
  }
}
