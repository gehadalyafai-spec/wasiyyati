import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../utils/record_details.dart';
import '../widgets/common.dart';
import 'entry_form.dart';

enum _SettlementFilter { all, pending, completed }
enum _RecordsOrder { newest, oldest, nearestDue }

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.controller, this.initialKind});
  final VaultController controller;
  final EntryKind? initialKind;
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final searchController = TextEditingController();
  EntryKind? filter;
  String query = '';
  _SettlementFilter settlement = _SettlementFilter.all;
  _RecordsOrder order = _RecordsOrder.newest;

  @override
  void initState() {
    super.initState();
    filter = widget.initialKind;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  int _compareEntries(VaultEntry a, VaultEntry b) {
    switch (order) {
      case _RecordsOrder.newest:
        return b.updatedAt.compareTo(a.updatedAt);
      case _RecordsOrder.oldest:
        return a.updatedAt.compareTo(b.updatedAt);
      case _RecordsOrder.nearestDue:
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue == null && bDue == null) {
          return b.updatedAt.compareTo(a.updatedAt);
        }
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        final comparison = aDue.compareTo(bDue);
        return comparison == 0 ? b.updatedAt.compareTo(a.updatedAt) : comparison;
    }
  }

  Future<void> _openForm({VaultEntry? entry}) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntryForm(controller: widget.controller, entry: entry,
        defaultKind: filter)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('سجل الحقوق'), actions: [
      IconButton(tooltip: 'إضافة حق', icon: const Icon(Icons.add_circle_outline_rounded),
        onPressed: () => _openForm()),
    ]),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('add-record'),
      backgroundColor: WasiyyatiColors.ink,
      foregroundColor: WasiyyatiColors.paper,
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add),
      label: const Text('حق جديد', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: WScreenWidth(child: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final matches = widget.controller.entries.where((entry) {
          if (filter != null && entry.kind != filter) return false;
          if (settlement == _SettlementFilter.pending && entry.completed) {
            return false;
          }
          if (settlement == _SettlementFilter.completed && !entry.completed) {
            return false;
          }
          if (query.isEmpty) return true;
          final needle = query.toLowerCase();
          return [
            entry.title, entry.party, entry.notes, entry.kind.plural,
            entry.currencyCode ?? '', currencyDescription(entry.currencyCode),
          ].any((value) => value.toLowerCase().contains(needle));
        }).toList()..sort(_compareEntries);
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(23, 0, 23, 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WPageIntro(eyebrow: 'فصل الحقوق والأمانات',
                title: 'ما لي وما عليّ',
                description: '${widget.controller.entries.length} سجلًا محفوظًا محليًا في خزنتك.'),
              TextField(
                key: const Key('search-records'),
                controller: searchController,
                onChanged: (text) => setState(() => query = text.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث عن شخص أو حق أو وصف',
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  suffixIcon: query.isEmpty ? null : IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: () { searchController.clear(); setState(() => query = ''); },
                    icon: const Icon(Icons.close_rounded, size: 20)),
                ),
              ),
              const SizedBox(height: 13),
            ]),
          ),
          SizedBox(height: 49, child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 21),
            children: [
              _chip(null, 'الكل'),
              for (final type in EntryKind.values) _chip(type, type.plural),
            ],
          )),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(23, 3, 23, 5),
            child: Row(children: [
              const Text('الحالة', style: TextStyle(
                fontSize: 12, color: WasiyyatiColors.secondaryInk)),
              const SizedBox(width: 7),
              DropdownButton<_SettlementFilter>(
                key: const Key('records-settlement-filter'),
                value: settlement,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: _SettlementFilter.all, child: Text('الكل')),
                  DropdownMenuItem(
                    value: _SettlementFilter.pending, child: Text('غير مسوّى')),
                  DropdownMenuItem(
                    value: _SettlementFilter.completed, child: Text('تمت التسوية')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => settlement = value);
                  }
                },
              ),
              const Spacer(),
              PopupMenuButton<_RecordsOrder>(
                tooltip: 'ترتيب السجلات',
                icon: const Icon(Icons.sort_rounded),
                onSelected: (value) => setState(() => order = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RecordsOrder.newest, child: Text('الأحدث تعديلًا')),
                  PopupMenuItem(
                    value: _RecordsOrder.oldest, child: Text('الأقدم تعديلًا')),
                  PopupMenuItem(
                    value: _RecordsOrder.nearestDue,
                    child: Text('أقرب موعد أولًا')),
                ],
              ),
            ]),
          ),
          Expanded(child: matches.isEmpty
            ? EmptyInfo(
                icon: Icons.menu_book_outlined,
                title: query.isNotEmpty ? 'لم نجد سجلًا يطابق بحثك' : 'هذا الفصل فارغ بعد',
                message: query.isNotEmpty
                    ? 'جرّب اسمًا أو كلمة أخرى، أو امسح البحث.'
                    : 'أضف حقوقك وأماناتك لتكون مرتبة ويسهل الرجوع إليها.',
                action: query.isNotEmpty ? null : FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أول سجل')),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(23, 12, 23, 106),
                itemCount: matches.length,
                separatorBuilder: (context, index) => const SizedBox(height: 9),
                itemBuilder: (context, i) => _entryTile(matches[i]),
              )),
        ]);
      },
    )),
  );

  Widget _chip(EntryKind? kind, String label) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 7),
    child: ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: filter == kind ? FontWeight.w800 : FontWeight.w500,
        color: filter == kind ? WasiyyatiColors.paper : WasiyyatiColors.ink),
      selected: filter == kind,
      onSelected: (_) => setState(() => filter = kind),
    ),
  );

  Widget _entryTile(VaultEntry item) {
    final kindIcon = switch (item.kind) {
      EntryKind.owed => Icons.north_east_rounded,
      EntryKind.receivable => Icons.south_west_rounded,
      EntryKind.trust => Icons.inventory_2_outlined,
      EntryKind.asset => Icons.home_work_outlined,
    };
    return WPaperCard(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 10),
      onTap: () => _openForm(entry: item),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: WasiyyatiColors.sage,
              borderRadius: BorderRadius.circular(12)),
            child: Icon(kindIcon, size: 20, color: WasiyyatiColors.ink)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800,
                decoration: item.completed ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Text(item.kind.plural + (item.party.isEmpty ? '' : ' • ${item.party}'),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: WasiyyatiColors.secondaryInk,
                fontSize: 12)),
            if (item.amount != null) ...[
              const SizedBox(height: 5),
              Text('${item.amount} ${currencyDescription(item.currencyCode)}',
                style: const TextStyle(fontSize: 11.5,
                  color: WasiyyatiColors.secondaryInk)),
            ],
            if (item.dueDate != null) ...[
              const SizedBox(height: 5),
              Text(
                '${isRecordOverdue(item, DateTime.now()) ? 'متأخر عن الموعد' : 'موعد الاستحقاق/المراجعة'}: '
                '${formatRecordDate(item.dueDate!)}',
                style: TextStyle(fontSize: 11.5,
                  color: isRecordOverdue(item, DateTime.now())
                      ? WasiyyatiColors.warning
                      : WasiyyatiColors.secondaryInk),
              ),
            ],
          ])),
          PopupMenuButton<String>(
            tooltip: 'خيارات السجل',
            onSelected: (action) async {
              if (action == 'edit') {
                await _openForm(entry: item);
              } else if (action == 'delete') {
                if (!mounted) return;
                final approved = await confirmAction(context,
                  title: 'حذف السجل',
                  message: 'سيُحذف هذا السجل من الجهاز ولا يمكن التراجع عن العملية.',
                  confirm: 'حذف');
                if (approved) {
                  try { await widget.controller.removeEntry(item.id); }
                  catch (e) { if (mounted) showError(context, e); }
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(value: 'delete', child: Text('حذف')),
            ],
          ),
        ]),
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(item.notes, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12,
              color: WasiyyatiColors.secondaryInk)),
        ],
        const Divider(height: 21),
        Row(children: [
          SizedBox(width: 26, height: 27, child: Checkbox(
            value: item.completed,
            onChanged: (checked) async {
              try { await widget.controller.changeCompleted(item, checked ?? false); }
              catch (e) { if (mounted) showError(context, e); }
            },
          )),
          const SizedBox(width: 7),
          Expanded(child: Text(item.completed ? 'تمت التسوية / الاسترجاع' : 'لم تتم التسوية',
            style: TextStyle(color: item.completed ? WasiyyatiColors.positive :
              WasiyyatiColors.warning, fontSize: 11.5,
              fontWeight: FontWeight.w700))),
          TextButton(onPressed: () => _openForm(entry: item), child: const Text('عرض وتعديل')),
        ]),
      ]),
    );
  }
}
