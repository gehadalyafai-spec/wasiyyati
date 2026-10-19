import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../utils/review_schedule.dart';
import '../widgets/common.dart';
import 'records_screen.dart';
import 'review_screen.dart';
import 'will_screen.dart';

/// The home is intentionally a document index, not a generic KPI dashboard.
/// Counts denote records, never imply a will is legally complete.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final VaultController controller;

  @override
  Widget build(BuildContext context) => SafeArea(
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
        _ReviewDigest(
          schedule: ReviewSchedule.fromEntries(controller.entries, DateTime.now()),
          onOpen: () => Navigator.push<void>(context, MaterialPageRoute(
            builder: (_) => ReviewScreen(controller: controller))),
        ),
        const SizedBox(height: 24),
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
