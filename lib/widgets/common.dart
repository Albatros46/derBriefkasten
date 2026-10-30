import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../l10n/strings.dart';
import '../models/category.dart';
import '../services/file_service.dart';

/// Hem yeni taranmış (mutlak yol) hem kayıtlı (göreli yol) sayfaları gösterir.
class PageImage extends StatelessWidget {
  const PageImage(this.path, {super.key, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (p.isAbsolute(path)) return Image.file(File(path), fit: fit);
    return FutureBuilder<File>(
      future: FileService.resolve(path),
      builder: (_, snap) => snap.hasData
          ? Image.file(snap.data!, fit: fit, errorBuilder: (_, _, _) => const Icon(Icons.broken_image))
          : const SizedBox.shrink(),
    );
  }
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.categoryKey, {super.key, this.radius = 20});

  final String categoryKey;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = categoryByKey(categoryKey);
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.color.withValues(alpha: 0.15),
      child: Icon(c.icon, color: c.color, size: radius),
    );
  }
}

String formatDate(BuildContext context, DateTime d) =>
    DateFormat.yMd(Localizations.localeOf(context).languageCode).format(d);

String formatDateTime(BuildContext context, DateTime d) =>
    DateFormat.yMd(Localizations.localeOf(context).languageCode).add_Hm().format(d);

/// Belge tarayıcıyı açar (otomatik kenar algılama, kırpma, çok sayfa).
/// İptal edilirse null döner.
Future<List<String>?> scanPages(BuildContext context) async {
  try {
    return await CunningDocumentScanner.getPictures(scannerSource: ScannerSource.cameraAndGallery);
  } on CunningDocumentScannerException catch (e) {
    if (context.mounted) {
      final msg = e.code == 'permission_denied' ? context.t('cameraDenied') : '${context.t('scanFailed')}: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    return null;
  }
}

Future<DateTime?> pickDate(BuildContext context, DateTime? initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 20),
    lastDate: DateTime(now.year + 10),
  );
}

Future<DateTime?> pickDateTime(BuildContext context, DateTime? initial) async {
  final date = await pickDate(context, initial);
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial ?? DateTime(date.year, date.month, date.day, 9)),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
