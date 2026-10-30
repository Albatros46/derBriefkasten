import '../models/category.dart';

/// OCR metninden kategori, gönderen ve son tarih önerileri çıkarır.
class AnalysisResult {
  final String categoryKey;
  final String? sender;
  final String? title;
  final DateTime? deadline;

  const AnalysisResult({required this.categoryKey, this.sender, this.title, this.deadline});
}

class DocumentAnalyzer {
  static final _date = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{2,4})\b');
  static final _deadlineWord = RegExp(
    r'(bis zum|bis spätestens|spätestens|frist|zahlbar bis|fällig|innerhalb|son tarih|kadar)',
    caseSensitive: false,
  );
  static final _withinDays = RegExp(
    r'innerhalb\s+(?:von\s+)?(\d{1,3}|einer|zwei|drei|vier)\s+(tagen|wochen|woche|monat|monaten)',
    caseSensitive: false,
  );
  static final _subject = RegExp(r'^\s*(betreff|betr\.|konu)\s*[:\-]?\s*(.+)$', caseSensitive: false);

  static AnalysisResult analyze(String text, {DateTime? now}) {
    now ??= DateTime.now();
    final lower = text.toLowerCase();

    var bestKey = 'other';
    var bestScore = 0;
    for (final c in categories) {
      var score = 0;
      for (final k in c.keywords) {
        if (lower.contains(k)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestKey = c.key;
      }
    }

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.length > 2).toList();

    String? title;
    for (final l in lines) {
      final m = _subject.firstMatch(l);
      if (m != null) {
        title = m.group(2)!.trim();
        break;
      }
    }

    // Antetteki ilk satır genellikle gönderendir.
    final sender = lines.isEmpty ? null : lines.first;

    return AnalysisResult(
      categoryKey: bestKey,
      sender: sender,
      title: title,
      deadline: _findDeadline(text, now),
    );
  }

  static DateTime? _findDeadline(String text, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    // "bis zum 15.11.2026" gibi: son-tarih kelimesinden sonraki 60 karakter içindeki ilk tarih
    for (final w in _deadlineWord.allMatches(text)) {
      final window = text.substring(w.start, (w.end + 60).clamp(0, text.length));
      final d = _date.firstMatch(window);
      final parsed = d == null ? null : _parse(d);
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    // "innerhalb von 14 Tagen" / "innerhalb eines Monats"
    final w = _withinDays.firstMatch(text);
    if (w != null) {
      const words = {'einer': 1, 'zwei': 2, 'drei': 3, 'vier': 4};
      final n = int.tryParse(w.group(1)!) ?? words[w.group(1)!.toLowerCase()] ?? 0;
      final unit = w.group(2)!.toLowerCase();
      if (n > 0) {
        if (unit.startsWith('tag')) return today.add(Duration(days: n));
        if (unit.startsWith('woche')) return today.add(Duration(days: 7 * n));
        return DateTime(today.year, today.month + n, today.day);
      }
    }
    return null;
  }

  static DateTime? _parse(RegExpMatch m) {
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final d = DateTime(year, month, day);
    return d.month == month ? d : null;
  }
}
