import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';
import 'records_screen.dart';
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
        const SizedBox(height: 25),
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
