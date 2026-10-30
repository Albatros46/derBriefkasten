import 'dart:convert';

/// Taranmış bir posta/evrak. Sayfa dosyaları uygulama belgeler klasörüne göre
/// göreli yol olarak saklanır (iOS'ta kapsayıcı yolu güncellemelerde değişir).
class Document {
  final String id;
  final String userId;
  String title;
  String category;
  String sender;
  DateTime receivedAt;
  final DateTime createdAt;
  List<String> pages;
  String ocrText;
  bool needsReply;
  DateTime? replyDeadline;
  DateTime? reminderAt;
  int notificationId;
  bool replied;
  String note;

  Document({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.sender = '',
    required this.receivedAt,
    required this.createdAt,
    required this.pages,
    this.ocrText = '',
    this.needsReply = false,
    this.replyDeadline,
    this.reminderAt,
    required this.notificationId,
    this.replied = false,
    this.note = '',
  });

  bool get hasOpenReminder => needsReply && !replied;

  bool get isOverdue =>
      hasOpenReminder && replyDeadline != null && replyDeadline!.isBefore(DateTime.now());

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'sender': sender,
        'received_at': receivedAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'pages': jsonEncode(pages),
        'ocr_text': ocrText,
        'needs_reply': needsReply ? 1 : 0,
        'reply_deadline': replyDeadline?.millisecondsSinceEpoch,
        'reminder_at': reminderAt?.millisecondsSinceEpoch,
        'notification_id': notificationId,
        'replied': replied ? 1 : 0,
        'note': note,
      };

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

  factory Document.fromMap(Map<String, Object?> m) => Document(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        title: m['title'] as String,
        category: m['category'] as String,
        sender: (m['sender'] as String?) ?? '',
        receivedAt: _date(m['received_at'])!,
        createdAt: _date(m['created_at'])!,
        pages: (jsonDecode(m['pages'] as String) as List).cast<String>(),
        ocrText: (m['ocr_text'] as String?) ?? '',
        needsReply: m['needs_reply'] == 1,
        replyDeadline: _date(m['reply_deadline']),
        reminderAt: _date(m['reminder_at']),
        notificationId: m['notification_id'] as int,
        replied: m['replied'] == 1,
        note: (m['note'] as String?) ?? '',
      );
}
