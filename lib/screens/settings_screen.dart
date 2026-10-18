import 'package:flutter/material.dart';
import '../services/pdf_export.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';
import 'will_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final VaultController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;

  Future<void> _export() async {
    if (busy) return;
    final accepted = await confirmAction(context,
      title: 'تصدير ملف غير مشفر',
      message: 'يحوي ملف PDF تفاصيل حساسة. لا تشاركه إلا مع شخص موثوق ولا تحفظه في مكان عام. الملف ليس توثيقًا رسميًا، وقد يتطلب اتصالًا لتنزيل الخط أول مرة.',
      confirm: 'موافق، متابعة');
    if (!accepted || !mounted) return;
    setState(() => busy = true);
    try {
      await PdfExport.share(widget.controller.snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تصدير PDF. تأكد من الاتصال ثم حاول مرة أخرى.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _safetyRow(IconData icon, String title, String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 22, color: WasiyyatiColors.copper),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(message, style: const TextStyle(color: WasiyyatiColors.secondaryInk,
          fontSize: 12.5, height: 1.65)),
      ])),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الخصوصية والوثائق')),
    body: WScreenWidth(child: ListView(
      padding: const EdgeInsets.fromLTRB(23, 0, 23, 34),
      children: [
        const WPageIntro(eyebrow: 'مساحة محمية محليًا',
          title: 'خزنة الوثائق',
          description: 'أدر نسخ المسودة وافهم حدود الحماية قبل مشاركة البيانات.'),
        Container(padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(color: WasiyyatiColors.ink,
            borderRadius: BorderRadius.circular(22)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WDocumentSeal(size: 50, light: true),
            SizedBox(height: 14),
            Text('خزنتك على هذا الجهاز', style: TextStyle(
              color: WasiyyatiColors.paper, fontSize: 21,
              fontWeight: FontWeight.w800, fontFamily: 'serif')),
            SizedBox(height: 9),
            Text('تُشفّر البيانات عند الحفظ، لكن هذه النسخة لا تتضمن بعد قفلًا مستقلًا بالبصمة أو نسخًا احتياطيًا قابلًا للاستعادة.',
              style: TextStyle(color: Color(0xFFD9E3D9), fontSize: 12.5, height: 1.8)),
          ]),
        ),
        const SizedBox(height: 24),
        const SectionHeading('الوثيقة', caption: 'معاينة ومشاركة صريحة بموافقتك'),
        WPaperCard(padding: EdgeInsets.zero, onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => WillPreviewScreen(controller: widget.controller))),
          child: const ListTile(
            leading: Icon(Icons.menu_book_outlined, color: WasiyyatiColors.ink),
            title: Text('معاينة مسودة الوصية', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('عرض الوثيقة دون مشاركتها'),
            trailing: Icon(Icons.chevron_left_rounded, color: WasiyyatiColors.copper),
          )),
        const SizedBox(height: 9),
        WPaperCard(padding: EdgeInsets.zero, onTap: busy ? null : _export,
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: WasiyyatiColors.ink),
            title: const Text('تصدير نسخة PDF', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(busy ? 'جارٍ تجهيز الوثيقة...' : 'ملف غير مشفر للمراجعة والطباعة'),
            trailing: const Icon(Icons.chevron_left_rounded, color: WasiyyatiColors.copper),
          )),
        const SizedBox(height: 23),
        const SectionHeading('أساسيات الأمان'),
        WPaperCard(child: Column(children: [
          _safetyRow(Icons.lock_outline, 'تشفير التخزين',
            'تُحفظ السجلات والمسودة محليًا بتشفير AES-256-GCM، والمفتاح في التخزين الآمن للنظام.'),
          const Divider(height: 1),
          _safetyRow(Icons.phone_android_rounded, 'لا مزامنة تلقائية',
            'حذف التطبيق أو فقدان الجهاز أو مفتاح التشفير قد يؤدي لفقدان البيانات. لا تعتمد عليها كنسختك الوحيدة.'),
          const Divider(height: 1),
          _safetyRow(Icons.visibility_off_outlined, 'خصوصية الوثائق',
            'لا تدخل أرقامًا سرية أو كلمات مرور. وعند مشاركة PDF تصبح المعلومات مكشوفة لمن يحصل عليه.'),
          const Divider(height: 1),
          _safetyRow(Icons.gavel_outlined, 'ضوابط التوثيق',
            'المسودات والسجلات تنظيمية، وليست سندات قضائية أو فتاوى شرعية.'),
        ])),
        const SizedBox(height: 22),
        const Text('وصيتي • النسخة التصميمية 0.2.0', textAlign: TextAlign.center,
          style: TextStyle(color: WasiyyatiColors.secondaryInk, fontSize: 11.5)),
      ],
    )),
  );
}
