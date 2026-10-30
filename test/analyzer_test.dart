import 'package:evrak_kutusu/services/analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 30);

  test('Finanzamt mektubu vergi kategorisine ve son tarihe eşlenir', () {
    const text = 'Finanzamt München\nBetreff: Einkommensteuerbescheid 2025\n'
        'Bitte reichen Sie die Unterlagen bis zum 20.11.2026 ein.';
    final r = DocumentAnalyzer.analyze(text, now: now);
    expect(r.categoryKey, 'tax');
    expect(r.sender, 'Finanzamt München');
    expect(r.title, 'Einkommensteuerbescheid 2025');
    expect(r.deadline, DateTime(2026, 11, 20));
  });

  test('"innerhalb von 14 Tagen" bugünden 14 gün sonrası olur', () {
    const text = 'Stadtwerke\nRechnung Nr. 123\nZahlen Sie innerhalb von 14 Tagen.';
    final r = DocumentAnalyzer.analyze(text, now: now);
    expect(r.categoryKey, 'invoice');
    expect(r.deadline, DateTime(2026, 11, 13));
  });

  test('Geçmiş tarih son tarih sayılmaz, eşleşme yoksa "other"', () {
    const text = 'Hallo\nTreffen am 01.01.2020, Frist war 02.02.2020.';
    final r = DocumentAnalyzer.analyze(text, now: now);
    expect(r.categoryKey, 'other');
    expect(r.deadline, isNull);
  });
}
