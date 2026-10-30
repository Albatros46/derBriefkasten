import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../services/document_repository.dart';
import '../services/pdf_service.dart';
import '../widgets/common.dart';
import 'document_edit_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _email(Document doc) => _run(() async {
        final sent = await PdfService.email(doc);
        if (!sent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('noMailApp'))));
        }
      });

  Future<void> _delete(Document doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(c.t('deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.t('delete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = context.read<DocumentRepository>();
    Navigator.of(context).pop();
    await repo.delete(doc);
  }

  @override
  Widget build(BuildContext context) {
    final doc = context.watch<DocumentRepository>().byId(widget.documentId);
    if (doc == null) return const Scaffold();
    final cat = categoryByKey(doc.category);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: context.t('edit'),
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => DocumentEditScreen(existing: doc))),
          ),
          IconButton(tooltip: context.t('delete'), icon: const Icon(Icons.delete_outline), onPressed: () => _delete(doc)),
        ],
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: doc.pages.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _PageViewer(pages: doc.pages, initial: i),
                )),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Card(clipBehavior: Clip.antiAlias, child: PageImage(doc.pages[i], fit: BoxFit.contain)),
                ),
              ),
            ),
          ),
          Center(child: Text('${doc.pages.length} ${context.t('pages')}', style: theme.textTheme.bodySmall)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _email(doc),
                  icon: const Icon(Icons.email),
                  label: Text(context.t('emailPdf')),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _run(() => PdfService.printDoc(doc)),
                  icon: const Icon(Icons.print),
                  label: Text(context.t('print')),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(() => PdfService.share(doc)),
                  icon: const Icon(Icons.ios_share),
                  label: Text(context.t('share')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(leading: CategoryAvatar(doc.category), title: Text(context.t(cat.labelKey)), subtitle: Text(context.t('category'))),
          if (doc.sender.isNotEmpty)
            ListTile(leading: const Icon(Icons.business), title: Text(doc.sender), subtitle: Text(context.t('sender'))),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(formatDate(context, doc.receivedAt)),
            subtitle: Text(context.t('receivedDate')),
          ),
          if (doc.needsReply) _replyCard(doc),
          if (doc.note.isNotEmpty)
            ListTile(leading: const Icon(Icons.sticky_note_2_outlined), title: Text(doc.note), subtitle: Text(context.t('note'))),
          if (doc.ocrText.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(context.t('recognizedText')),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              children: [SelectableText(doc.ocrText)],
            ),
        ],
      ),
    );
  }

  Widget _replyCard(Document doc) {
    final scheme = Theme.of(context).colorScheme;
    final status = doc.replied ? 'replied' : (doc.isOverdue ? 'overdue' : 'open');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: doc.isOverdue ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(doc.replied ? Icons.check_circle : Icons.reply),
              const SizedBox(width: 8),
              Text('${context.t('needsReply')} · ${context.t(status)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            if (doc.replyDeadline != null)
              Text('${context.t('replyDeadline')}: ${formatDate(context, doc.replyDeadline!)}'),
            if (doc.reminderAt != null && !doc.replied)
              Text('${context.t('reminderAt')}: ${formatDateTime(context, doc.reminderAt!)}'),
            if (!doc.replied)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.read<DocumentRepository>().markReplied(doc),
                  icon: const Icon(Icons.done),
                  label: Text(context.t('markReplied')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tam ekran, yakınlaştırılabilir sayfa görüntüleyici.
class _PageViewer extends StatelessWidget {
  const _PageViewer({required this.pages, required this.initial});

  final List<String> pages;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: pages.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(child: PageImage(pages[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
