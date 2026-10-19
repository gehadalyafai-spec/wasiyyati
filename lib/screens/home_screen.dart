import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../utils/home_summary.dart';
import '../utils/record_details.dart';
import '../utils/review_schedule.dart';
import '../widgets/common.dart';
import 'entry_form.dart';
import 'records_screen.dart';
import 'review_screen.dart';
import 'will_screen.dart';

/// The home is intentionally a document index, not a generic KPI dashboard.
/// Counts denote records, never imply a will is legally complete.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final VaultController controller;

  @override
  Widget build(BuildContext context) {
    final summary = HomeSummary.fromEntries(controller.entries);
    return SafeArea(
    child: WScreenWidth(child: ListView(
      key: const Key('home-scroll'),
      padding: const EdgeInsets.fromLTRB(23, 8, 23, 29),
      children: [
        Row(children: [
          const WDocumentSeal(size: 38),
          const SizedBox(width: 8),
          const Expanded(child: Text('وصيتي', style: TextStyle(
            fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w800))),
          IconButton(
            tooltip: 'معلومات الخصوصية',
            icon: const Icon(Icons.shield_outlined, size: 22),
            onPressed: () => showDialog<void>(context: context, builder: (_) => const AlertDialog(
              title: Text('خصوصيتك أولًا'),
              content: Text('تُحفظ المسودة والسجلات مشفرة على جهازك. لا توجد مزامنة سحابية في هذه النسخة؛ فقدان الجهاز أو حذف التطبيق قد يفقدك البيانات.'),
            )),
          ),
        ]),
        const SizedBox(height: 10),
        const WPageIntro(eyebrow: 'دفتر الأمانات الشخصي',
          title: 'السلام عليكم',
          description: 'وثيقة تنمو معك، تحفظ ما لك وما عليك.'),
        WDocumentHero(hasDraft: controller.will.hasContent,
          lastReviewed: controller.will.lastReviewed,
          onOpen: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => WillScreen(controller: controller)))),
        const SizedBox(height: 15),
        _QuickOverview(
          summary: summary,
          onAdd: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EntryForm(controller: controller),
            ),
          ),
          onAll: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => RecordsScreen(controller: controller),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ReviewDigest(
          schedule: ReviewSchedule.fromEntries(controller.entries, DateTime.now()),
          onOpen: () => Navigator.push<void>(context, MaterialPageRoute(
            builder: (_) => ReviewScreen(controller: controller))),
        ),
        const SizedBox(height: 24),
        if (!summary.isEmpty) ...[
          SectionHeading(
            'آخر السجلات',
            caption: 'افتح أي قيد لعرضه أو تعديله',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => RecordsScreen(controller: controller),
                ),
              ),
              child: const Text('عرض الكل'),
            ),
          ),
          _RecentRecords(
            entries: summary.recent,
            onOpen: (entry) => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => EntryForm(controller: controller, entry: entry),
              ),
            ),
          ),
          const SizedBox(height: 19),
        ],
        const SectionHeading('فهرس الحقوق', caption: 'انتقل إلى القسم الذي تريد تنظيمه'),
        for (final category in const [
          (EntryKind.receivable, Icons.south_west_rounded, 'حقوق لي', 'مستحقات عند الآخرين', '٠١'),
          (EntryKind.owed, Icons.north_east_rounded, 'ديون عليّ', 'حقوق يجب الوفاء بها', '٠٢'),
          (EntryKind.trust, Icons.inventory_2_outlined, 'الأمانات', 'أشياء وودائع محفوظة', '٠٣'),
          (EntryKind.asset, Icons.home_work_outlined, 'الممتلكات', 'فهرس الأصول والمستندات', '٠٤'),
        ]) ...[
          _IndexRow(
            number: category.$5,
            title: category.$3,
            description: category.$4,
            icon: category.$2,
            count: controller.countFor(category.$1),
            onOpen: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordsScreen(controller: controller,
                initialKind: category.$1))),
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 21),
        const WInfoBanner(
          icon: Icons.format_quote_rounded,
          text: '«ما حقُّ امرئٍ مسلمٍ له شيءٌ يريد أن يوصي فيه، يبيت ليلتين، إلا ووصيته مكتوبة عنده» — رواه البخاري ومسلم.'),
        const SizedBox(height: 15),
        const Text('هذا التطبيق لتنظيم البيانات ولا يُعد توثيقًا رسميًا للوصية.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: WasiyyatiColors.secondaryInk)),
      ],
    )),
  );
  }
}

class _QuickOverview extends StatelessWidget {
  const _QuickOverview({
    required this.summary,
    required this.onAdd,
    required this.onAll,
  });
  final HomeSummary summary;
  final VoidCallback onAdd;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => WPaperCard(
    key: const Key('home-quick-overview'),
    padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('دفتر الحقوق', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 15,
        )),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: _CountItem(
            title: 'إجمالي القيود', count: summary.total,
            color: WasiyyatiColors.ink,
          )),
          Container(width: 1, height: 38, color: WasiyyatiColors.rule),
          Expanded(child: _CountItem(
            title: 'قيد المراجعة', count: summary.pending,
            color: WasiyyatiColors.copper,
          )),
          Container(width: 1, height: 38, color: WasiyyatiColors.rule),
          Expanded(child: _CountItem(
            title: 'تمت التسوية', count: summary.completed,
            color: WasiyyatiColors.positive,
          )),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: FilledButton.icon(
            key: const Key('home-add-record'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('إضافة سجل'),
          )),
          const SizedBox(width: 9),
          Expanded(child: OutlinedButton.icon(
            key: const Key('home-all-records'),
            onPressed: onAll,
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: const Text('فتح السجل'),
          )),
        ]),
        const SizedBox(height: 7),
        const Text(
          'الأرقام لعدد القيود فقط، وليست مجموعًا ماليًا أو حكمًا على الحقوق.',
          style: TextStyle(
            fontSize: 10.5,
            height: 1.6,
            color: WasiyyatiColors.secondaryInk,
          ),
        ),
      ],
    ),
  );
}

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.title, required this.count, required this.color,
  });
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$count', style: TextStyle(
        fontSize: 23, fontWeight: FontWeight.w800, color: color,
      )),
      const SizedBox(height: 3),
      Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 10.5, color: WasiyyatiColors.secondaryInk,
        ),
      ),
    ],
  );
}

class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.entries, required this.onOpen});
  final List<VaultEntry> entries;
  final ValueChanged<VaultEntry> onOpen;

  @override
  Widget build(BuildContext context) => WPaperCard(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    child: Column(children: [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        _RecentRow(
          item: entries[i],
          onTap: () => onOpen(entries[i]),
        ),
      ],
    ]),
  );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item, required this.onTap});
  final VaultEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.kind) {
      EntryKind.owed => Icons.north_east_rounded,
      EntryKind.receivable => Icons.south_west_rounded,
      EntryKind.trust => Icons.inventory_2_outlined,
      EntryKind.asset => Icons.home_work_outlined,
    };
    return InkWell(
      key: ValueKey('home-recent-${item.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 1),
        child: Row(children: [
          Container(
            height: 35, width: 35,
            decoration: BoxDecoration(
              color: WasiyyatiColors.sage,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: WasiyyatiColors.ink),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.kind.plural} • ${item.completed ? 'تمت التسوية' : 'غير مسوّى'}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11, color: WasiyyatiColors.secondaryInk,
                ),
              ),
            ],
          )),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              formatRecordDate(item.updatedAt),
              style: const TextStyle(
                fontSize: 10, color: WasiyyatiColors.secondaryInk,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.chevron_left_rounded,
              size: 17, color: WasiyyatiColors.copper,
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ReviewDigest extends StatelessWidget {
  const _ReviewDigest({required this.schedule, required this.onOpen});

  final ReviewSchedule schedule;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => WPaperCard(
    key: const Key('home-review-digest'),
    onTap: onOpen,
    padding: const EdgeInsets.fromLTRB(17, 16, 16, 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: WasiyyatiColors.sage,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: WasiyyatiColors.ink,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مواعيد تحتاج متابعة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('حسب التواريخ التي سجلتها',
                style: TextStyle(
                  fontSize: 11.5, color: WasiyyatiColors.secondaryInk)),
            ],
          )),
          const Icon(Icons.chevron_left_rounded,
            color: WasiyyatiColors.copper),
        ]),
        const SizedBox(height: 14),
        if (schedule.isEmpty)
          const Text(
            'لم تُسجّل مواعيد غير مسوّاة بعد. يمكنك إضافتها من سجل الحقوق.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.65,
              color: WasiyyatiColors.secondaryInk,
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _DigestNumber('فات موعدها', schedule.overdue.length,
                WasiyyatiColors.warning),
              _DigestNumber('اليوم', schedule.today.length, WasiyyatiColors.ink),
              _DigestNumber('خلال ٧ أيام', schedule.upcoming.length,
                WasiyyatiColors.positive),
              _DigestNumber('لاحقًا', schedule.later.length,
                WasiyyatiColors.secondaryInk),
            ],
          ),
        const SizedBox(height: 11),
        const Text(
          'فتح جدول المراجعة ←',
          style: TextStyle(
            fontSize: 12.5,
            color: WasiyyatiColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _DigestNumber extends StatelessWidget {
  const _DigestNumber(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$count', style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: color,
      )),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
        fontSize: 11.5,
        color: WasiyyatiColors.secondaryInk,
      )),
    ],
  );
}

class _IndexRow extends StatelessWidget {
  const _IndexRow({required this.number, required this.title,
    required this.description, required this.icon, required this.count,
    required this.onOpen});
  final String number, title, description;
  final IconData icon;
  final int count;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => WPaperCard(
    padding: EdgeInsets.zero, onTap: onOpen,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        SizedBox(width: 36, child: Text(number, style: const TextStyle(
          color: WasiyyatiColors.copper, fontSize: 15, fontWeight: FontWeight.w800))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 11.5,
            color: WasiyyatiColors.secondaryInk)),
        ])),
        Column(children: [
          Text('$count', style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: WasiyyatiColors.ink)),
          const Text('سجل', style: TextStyle(fontSize: 10,
            color: WasiyyatiColors.secondaryInk)),
        ]),
        const SizedBox(width: 10),
        const Icon(Icons.chevron_left_rounded, size: 18,
          color: WasiyyatiColors.copper),
      ])),
  );
}
