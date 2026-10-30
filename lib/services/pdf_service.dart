import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document.dart';
import 'file_service.dart';

/// Taranan sayfalardan PDF üretir; e-posta, yazdırma ve paylaşım işlemleri.
class PdfService {
  static Future<Uint8List> build(Document doc) async {
    final pdf = pw.Document(title: doc.title, creator: 'Evrak Kutusu');
    for (final rel in doc.pages) {
      final bytes = await (await FileService.resolve(rel)).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ));
    }
    return pdf.save();
  }

  static String fileName(Document doc) {
    final safe = doc.title.replaceAll(RegExp(r'[^\w\-äöüÄÖÜßçğıİöşÇĞÖŞÜ ]'), '').trim();
    return '${safe.isEmpty ? 'evrak' : safe.replaceAll(' ', '_')}.pdf';
  }

  static Future<File> _writeTemp(Document doc) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName(doc)));
    return file.writeAsBytes(await build(doc), flush: true);
  }

  /// Telefonun e-posta uygulamasını PDF eki ile açar.
  /// E-posta uygulaması yoksa false döner ve paylaşım menüsü açılır.
  static Future<bool> email(Document doc) async {
    final file = await _writeTemp(doc);
    try {
      await FlutterEmailSender.send(Email(
        subject: doc.title,
        body: doc.sender.isEmpty ? '' : '${doc.sender}\n',
        attachmentPaths: [file.path],
      ));
      return true;
    } on FlutterEmailSenderNotAvailableException {
      await _shareFile(file, doc.title);
      return false;
    }
  }

  static Future<void> printDoc(Document doc) async {
    await Printing.layoutPdf(name: fileName(doc), onLayout: (_) => build(doc));
  }

  /// Paylaşım menüsü: WhatsApp, Drive, "Dosyalara kaydet" vb.
  static Future<void> share(Document doc) async => _shareFile(await _writeTemp(doc), doc.title);

  static Future<void> _shareFile(File file, String subject) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
    ));
  }
}
