import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/strings.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../services/analyzer.dart';
import '../services/document_repository.dart';
import '../services/file_service.dart';
import '../services/ocr_service.dart';
import '../widgets/common.dart';

/// Yeni taranan evrakı kaydetme veya mevcut evrakı düzenleme ekranı.
class DocumentEditScreen extends StatefulWidget {
  const DocumentEditScreen({super.key, this.existing, this.newPages = const []});

  final Document? existing;
  final List<String> newPages;

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  final _title = TextEditingController();
  final _sender = TextEditingController();
  final _note = TextEditingController();

  late List<String> _pages;
  late String _category;
  late DateTime _receivedAt;
  bool _needsReply = false;
  DateTime? _deadline;
  DateTime? _reminderAt;
  String _ocrText = '';
  String? _suggestedCategory;
  bool _deadlineDetected = false;
  bool _recognizing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _pages = [...?d?.pages, ...widget.newPages];
    _category = d?.category ?? 'other';
    _receivedAt = d?.receivedAt ?? DateTime.now();
    _title.text = d?.title ?? '';
    _sender.text = d?.sender ?? '';
    _note.text = d?.note ?? '';
    _needsReply = d?.needsReply ?? false;
    _deadline = d?.replyDeadline;
    _reminderAt = d?.reminderAt;
    _ocrText = d?.ocrText ?? '';
    if (widget.newPages.isNotEmpty) _recognize(widget.newPages, applySuggestions: d == null);
  }

  @override
  void dispose() {
    _title.dispose();
    _sender.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _recognize(List<String> absolutePaths, {required bool applySuggestions}) async {
    setState(() => _recognizing = true);
    try {
      final text = await OcrService.recognize(absolutePaths);
      if (!mounted) return;
      _ocrText = [_ocrText, text].where((s) => s.isNotEmpty).join('\n\n');
      final r = DocumentAnalyzer.analyze(_ocrText);
      setState(() {
        _suggestedCategory = r.categoryKey;
        if (!applySuggestions) return;
        _category = r.categoryKey;
        if (_title.text.isEmpty && r.title != null) _title.text = r.title!;
        if (_sender.text.isEmpty && r.sender != null) _sender.text = r.sender!;
        if (r.deadline != null) {
          _deadlineDetected = true;
          _needsReply = true;
          _deadline = r.deadline;
          _reminderAt = _defaultReminder(r.deadline!);
        }
      });
    } catch (_) {
      // OCR başarısız olursa kullanıcı alanları elle doldurabilir.
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  /// Son tarihten 3 gün önce saat 09:00; bu geçmişteyse yarın 09:00.
  DateTime _defaultReminder(DateTime deadline) {
    final d = deadline.subtract(const Duration(days: 3));
    final candidate = DateTime(d.year, d.month, d.day, 9);
    if (candidate.isAfter(DateTime.now())) return candidate;
    final t = DateTime.now().add(const Duration(days: 1));
    return DateTime(t.year, t.month, t.day, 9);
  }

  Future<void> _addPages() async {
    final pages = await scanPages(context);
    if (pages == null) return;
    setState(() => _pages.addAll(pages));
    _recognize(pages, applySuggestions: widget.existing == null);
  }

  Future<void> _save() async {
    if (_pages.isEmpty) return;
    setState(() => _saving = true);
    final repo = context.read<DocumentRepository>();
    final lang = languageOf(Localizations.localeOf(context));
    final untitled = context.t('untitled');
    final existing = widget.existing;
    final id = existing?.id ?? const Uuid().v4();

    final stored = await FileService.persistPages(repo.userId, id, _pages);
    if (existing != null) {
      await FileService.deleteFiles(existing.pages.where((rel) => !stored.contains(rel)));
    }

    final doc = Document(
      id: id,
      userId: repo.userId,
      title: _title.text.trim().isEmpty ? untitled : _title.text.trim(),
      category: _category,
      sender: _sender.text.trim(),
      receivedAt: _receivedAt,
      createdAt: existing?.createdAt ?? DateTime.now(),
      pages: stored,
      ocrText: _ocrText,
      needsReply: _needsReply,
      replyDeadline: _needsReply ? _deadline : null,
      reminderAt: _needsReply ? _reminderAt : null,
      notificationId: existing?.notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      replied: existing?.replied ?? false,
      note: _note.text.trim(),
    );
    await repo.save(doc, lang: lang);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(widget.existing == null ? 'newDocument' : 'editDocument')),
        actions: [
          TextButton.icon(
            onPressed: _saving || _pages.isEmpty ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(context.t('save')),
          ),
        ],
        bottom: _recognizing || _saving
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(width: 115, height: 160, child: PageImage(_pages[i])),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton.filledTonal(
                            iconSize: 18,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _pages.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: 115,
                  child: OutlinedButton(
                    onPressed: _addPages,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [const Icon(Icons.add_a_photo), Text(context.t('addPage'), textAlign: TextAlign.center)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_recognizing)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(context.t('recognizing'))),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: context.t('title'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sender,
            decoration: InputDecoration(labelText: context.t('sender'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: context.t('category'),
              border: const OutlineInputBorder(),
              helperText: _suggestedCategory == null
                  ? null
                  : '${context.t('suggestedCategory')}: ${context.t(categoryByKey(_suggestedCategory!).labelKey)}',
            ),
            items: [
              for (final c in categories)
                DropdownMenuItem(
                  value: c.key,
                  child: Row(children: [
                    Icon(c.icon, color: c.color, size: 20),
                    const SizedBox(width: 8),
                    Text(context.t(c.labelKey)),
                  ]),
                ),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'other'),
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(context.t('receivedDate')),
            subtitle: Text(formatDate(context, _receivedAt)),
            onTap: () async {
              final d = await pickDate(context, _receivedAt);
              if (d != null) setState(() => _receivedAt = d);
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.reply),
            title: Text(context.t('needsReply')),
            subtitle: _deadlineDetected ? Text(context.t('detectedDeadline')) : null,
            value: _needsReply,
            onChanged: (v) => setState(() {
              _needsReply = v;
              if (v && _reminderAt == null) {
                _reminderAt = _defaultReminder(_deadline ?? DateTime.now().add(const Duration(days: 7)));
              }
            }),
          ),
          if (_needsReply) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: Text(context.t('replyDeadline')),
              subtitle: Text(_deadline == null ? context.t('pickDate') : formatDate(context, _deadline!)),
              onTap: () async {
                final d = await pickDate(context, _deadline);
                if (d != null) setState(() => _deadline = d);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: Text(context.t('reminderAt')),
              subtitle: Text(_reminderAt == null ? context.t('pickDate') : formatDateTime(context, _reminderAt!)),
              onTap: () async {
                final d = await pickDateTime(context, _reminderAt);
                if (d != null) setState(() => _reminderAt = d);
              },
            ),
          ],
          const Divider(),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: context.t('note'), border: const OutlineInputBorder()),
          ),
          if (_ocrText.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(context.t('recognizedText')),
              children: [SelectableText(_ocrText)],
            ),
          const SizedBox(height: 24),
          Text('${_pages.length} ${context.t('pages')}',
              style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
