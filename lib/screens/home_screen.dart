import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../services/document_repository.dart';
import '../widgets/common.dart';
import 'document_detail_screen.dart';
import 'document_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _query = '';
  String? _category;

  Future<void> _scan() async {
    final pages = await scanPages(context);
    if (pages == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentEditScreen(newPages: pages)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DocumentRepository>();
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(_tab == 0 ? 'documents' : 'reminders')),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(email)),
              PopupMenuItem(
                onTap: () => FirebaseAuth.instance.signOut(),
                child: ListTile(leading: const Icon(Icons.logout), title: Text(context.t('logout'))),
              ),
            ],
          ),
        ],
      ),
      body: repo.loading
          ? const Center(child: CircularProgressIndicator())
          : _tab == 0
              ? _documentsTab(repo)
              : _remindersTab(repo),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scan,
        icon: const Icon(Icons.document_scanner),
        label: Text(context.t('scan')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.folder_open), label: context.t('documents')),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: repo.openReminders.isNotEmpty,
              label: Text('${repo.openReminders.length}'),
              child: const Icon(Icons.notifications_active_outlined),
            ),
            label: context.t('reminders'),
          ),
        ],
      ),
    );
  }

  Widget _documentsTab(DocumentRepository repo) {
    final q = _query.toLowerCase();
    final all = repo.documents;
    final filtered = all.where((d) {
      if (_category != null && d.category != _category) return false;
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) ||
          d.sender.toLowerCase().contains(q) ||
          d.note.toLowerCase().contains(q) ||
          d.ocrText.toLowerCase().contains(q);
    }).toList();

    final counts = <String, int>{};
    for (final d in all) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SearchBar(
            hintText: context.t('search'),
            leading: const Icon(Icons.search),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${context.t('all')} (${all.length})'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final c in categories)
                if ((counts[c.key] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      avatar: Icon(c.icon, color: c.color, size: 18),
                      label: Text('${context.t(c.labelKey)} (${counts[c.key]})'),
                      selected: _category == c.key,
                      onSelected: (s) => setState(() => _category = s ? c.key : null),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _empty(context.t('noDocuments'), Icons.inbox)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => DocumentTile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _remindersTab(DocumentRepository repo) {
    final items = repo.openReminders;
    if (items.isEmpty) return _empty(context.t('noReminders'), Icons.notifications_off_outlined);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final d = items[i];
        final color = d.isOverdue ? Theme.of(context).colorScheme.error : null;
        return ListTile(
          leading: CategoryAvatar(d.category),
          title: Text(d.title),
          subtitle: Text([
            if (d.replyDeadline != null) '${context.t('replyDeadline')}: ${formatDate(context, d.replyDeadline!)}',
            if (d.reminderAt != null) '${context.t('reminderAt')}: ${formatDateTime(context, d.reminderAt!)}',
            if (d.isOverdue) context.t('overdue'),
          ].join('\n')),
          isThreeLine: d.replyDeadline != null && d.reminderAt != null,
          textColor: color,
          trailing: IconButton(
            tooltip: context.t('markReplied'),
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => repo.markReplied(d),
          ),
          onTap: () => _openDetail(d),
        );
      },
    );
  }

  void _openDetail(Document d) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: d.id)));

  Widget _empty(String text, IconData icon) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class DocumentTile extends StatelessWidget {
  const DocumentTile(this.doc, {super.key});

  final Document doc;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 56,
          child: doc.pages.isEmpty ? CategoryAvatar(doc.category) : PageImage(doc.pages.first),
        ),
      ),
      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${context.t(categoryByKey(doc.category).labelKey)} · ${formatDate(context, doc.receivedAt)}'
        '${doc.sender.isEmpty ? '' : '\n${doc.sender}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: doc.sender.isNotEmpty,
      trailing: doc.hasOpenReminder
          ? Icon(Icons.notifications_active,
              color: doc.isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id))),
    );
  }
}
