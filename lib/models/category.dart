import 'package:flutter/material.dart';

/// Evrak kategorileri. [keywords] OCR metninde aranır (küçük harf, Almanca + Türkçe).
class DocCategory {
  final String key;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const DocCategory(this.key, this.icon, this.color, this.keywords);

  String get labelKey => 'cat_$key';
}

const categories = <DocCategory>[
  DocCategory('tax', Icons.account_balance, Color(0xFF6D4C41), [
    'finanzamt', 'steuer', 'einkommensteuer', 'steuerbescheid', 'steuer-id',
    'steuernummer', 'vergi', 'elster',
  ]),
  DocCategory('bank', Icons.savings, Color(0xFF1565C0), [
    'bank', 'sparkasse', 'volksbank', 'kontoauszug', 'iban', 'girokonto',
    'kreditkarte', 'überweisung', 'kredit', 'commerzbank', 'postbank',
  ]),
  DocCategory('insurance', Icons.shield, Color(0xFF2E7D32), [
    'versicherung', 'versicherungsnummer', 'police', 'haftpflicht', 'allianz',
    'hausrat', 'kfz-versicherung', 'beitragsrechnung', 'sigorta',
  ]),
  DocCategory('health', Icons.local_hospital, Color(0xFFC62828), [
    'krankenkasse', 'aok', 'tk ', 'techniker', 'barmer', 'dak', 'arzt',
    'praxis', 'klinik', 'krankenhaus', 'rezept', 'gesundheitskarte', 'hastane',
  ]),
  DocCategory('authority', Icons.gavel, Color(0xFF4527A0), [
    'stadt', 'bürgeramt', 'ausländerbehörde', 'landratsamt', 'gericht',
    'aufenthaltstitel', 'rundfunkbeitrag', 'beitragsservice', 'bescheid',
    'amtsgericht', 'behörde', 'konsulat', 'polizei',
  ]),
  DocCategory('work', Icons.work, Color(0xFFEF6C00), [
    'jobcenter', 'agentur für arbeit', 'arbeitgeber', 'gehaltsabrechnung',
    'lohnabrechnung', 'arbeitsvertrag', 'bürgergeld', 'arbeitslosengeld',
    'rentenversicherung', 'familienkasse', 'kindergeld',
  ]),
  DocCategory('housing', Icons.home, Color(0xFF00838F), [
    'vermieter', 'miete', 'mietvertrag', 'nebenkosten', 'hausverwaltung',
    'betriebskosten', 'wohnung', 'kaution',
  ]),
  DocCategory('invoice', Icons.receipt_long, Color(0xFFAD1457), [
    'rechnung', 'rechnungsnummer', 'mahnung', 'zahlungserinnerung',
    'stadtwerke', 'strom', 'telekom', 'vodafone', 'o2', 'fatura', 'betrag',
  ]),
  DocCategory('school', Icons.school, Color(0xFF558B2F), [
    'schule', 'kita', 'kindergarten', 'universität', 'hochschule',
    'volkshochschule', 'integrationskurs', 'zeugnis', 'bafög', 'okul',
  ]),
  DocCategory('other', Icons.folder, Color(0xFF546E7A), []),
];

DocCategory categoryByKey(String key) =>
    categories.firstWhere((c) => c.key == key, orElse: () => categories.last);
