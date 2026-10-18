import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/pdf_export.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';

class WillScreen extends StatefulWidget {
  const WillScreen({super.key, required this.controller});
  final VaultController controller;
  @override
  State<WillScreen> createState() => _WillScreenState();
}

class _WillScreenState extends State<WillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _city, _executor, _phone,
      _bequests, _instructions;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final w = widget.controller.will;
    _name = TextEditingController(text: w.fullName);
    _city = TextEditingController(text: w.city);
    _executor = TextEditingController(text: w.executorName);
    _phone = TextEditingController(text: w.executorContact);
    _bequests = TextEditingController(text: w.bequests);
    _instructions = TextEditingController(text: w.instructions);
  }

  @override
  void dispose() {
    for (final field in [_name, _city, _executor, _phone, _bequests, _instructions]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<bool> _save({bool showFeedback = true}) async {
    if (!_formKey.currentState!.validate() || _busy) return false;
    setState(() => _busy = true);
    final draft = WillDraft(
      fullName: _name.text.trim(), city: _city.text.trim(),
      executorName: _executor.text.trim(), executorContact: _phone.text.trim(),
      bequests: _bequests.text.trim(), instructions: _instructions.text.trim(),
      lastReviewed: DateTime.now(),
    );
    try {
      await widget.controller.saveWill(draft);
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُفظت المسودة مشفرة على هذا الجهاز')));
      }
      return true;
    } catch (error) {
      if (mounted) showError(context, error);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    if (await _save(showFeedback: false) && mounted) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => WillPreviewScreen(controller: widget.controller)));
    }
  }

  Widget _textField(TextEditingController controller, String label, int limit,
      {int lines = 1, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      maxLength: limit,
      decoration: formDecoration(label, hint: hint),
    ),
  );

  Widget _chapter(String number, String title, String description,
      List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      WChapterHeader(number: number, title: title, subtitle: description),
      WPaperCard(child: Column(children: children)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.will;
    final fields = data.filledFieldCount;
    return Scaffold(
      appBar: AppBar(title: const Text('تحرير الوصية')),
      body: WScreenWidth(child: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.fromLTRB(23, 0, 23, 32), children: [
          const WPageIntro(
            eyebrow: 'الوثيقة الحيّة • فصل الوصية',
            title: 'مسودة وصيتي',
            description: 'اكتبها وراجعها متى شئت، ثم اعرضها على مختص قبل التوثيق.'),
          Container(padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(color: WasiyyatiColors.ink,
              borderRadius: BorderRadius.circular(21)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const WDocumentSeal(light: true, size: 39),
                const SizedBox(width: 13),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('مسودتك الشخصية', style: TextStyle(color: WasiyyatiColors.paper,
                      fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('ليس مؤشرًا لصحة الوصية الشرعية أو القانونية',
                      style: TextStyle(color: Color(0xFFCFD8CF), fontSize: 10.5)),
                  ])),
              ]),
              const SizedBox(height: 15),
              LinearProgressIndicator(value: fields / WillDraft.editableFieldCount,
                minHeight: 5, backgroundColor: const Color(0xFF53665C),
                valueColor: const AlwaysStoppedAnimation(WasiyyatiColors.copper),
                borderRadius: BorderRadius.circular(10)),
              const SizedBox(height: 9),
              Text('الحقول المحفوظة: $fields من ${WillDraft.editableFieldCount}',
                style: const TextStyle(color: Color(0xFFD4DDCF), fontSize: 12)),
            ])),
          const SizedBox(height: 15),
          const WInfoBanner(
            text: 'هذه مسودة تنظيمية غير موثّقة. بعض الوصايا تخضع لشروط شرعية وقانونية خاصة؛ راجعها مع مختص في بلدك.'),
          _chapter('١', 'بيانات الموصي', 'معلومات التعريف الأساسية بالوثيقة', [
            _textField(_name, 'الاسم الكامل', 120),
            _textField(_city, 'المدينة / البلد', 80),
          ]),
          _chapter('٢', 'المعني بتنفيذ الوصية',
            'تسجيل بياناته لا يمنحه صلاحيات رسمية تلقائيًا', [
            _textField(_executor, 'اسم الشخص', 120),
            _textField(_phone, 'وسيلة التواصل', 100),
          ]),
          _chapter('٣', 'نص الوصية',
            'مسودة لعرضها على مختص شرعي وقانوني قبل اعتمادها', [
            _textField(_bequests, 'ما تريد الوصية به', 6000, lines: 6,
              hint: 'اكتب الوصايا التي ترغب بمراجعتها وتوثيقها'),
          ]),
          _chapter('٤', 'ملاحظات للأسرة',
            'معلومات تنظيمية مفيدة دون كلمات مرور أو رموز سرية', [
            _textField(_instructions, 'إرشادات ومواقع المستندات', 4000,
              lines: 5, hint: 'مثال: مكان حفظ وثائق الملكية'),
          ]),
          const SizedBox(height: 25),
          FilledButton.icon(
            key: const Key('save-will'),
            onPressed: _busy ? null : () => _save(),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(_busy ? 'جارٍ الحفظ...' : 'حفظ المسودة المشفرة'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _review,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('حفظ ثم معاينة الوثيقة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WasiyyatiColors.ink,
              side: const BorderSide(color: WasiyyatiColors.rule),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
          const SizedBox(height: 15),
          const Text('احفظ تغييراتك قبل مغادرة الصفحة.', textAlign: TextAlign.center,
            style: TextStyle(color: WasiyyatiColors.secondaryInk, fontSize: 11.5)),
        ]),
      )),
    );
  }
}

/// Private, read-only preview; the PDF remains a separate explicit share.
class WillPreviewScreen extends StatefulWidget {
  const WillPreviewScreen({super.key, required this.controller});
  final VaultController controller;
  @override
  State<WillPreviewScreen> createState() => _WillPreviewScreenState();
}

class _WillPreviewScreenState extends State<WillPreviewScreen> {
  bool exporting = false;
  Future<void> _export() async {
    if (exporting) return;
    final allow = await confirmAction(context,
      title: 'مشاركة ملف غير مشفر',
      message: 'سيحتوي PDF على معلومات شخصية غير مشفرة. لا يعتبر توثيقًا رسميًا ولا تحفظه في مكان عام. قد يحتاج التصدير إلى اتصال بالإنترنت لتنزيل الخط.',
      confirm: 'موافق، تصدير');
    if (!allow || !mounted) return;
    setState(() => exporting = true);
    try {
      await PdfExport.share(widget.controller.snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تصدير PDF. تحقق من الاتصال وحاول مجددًا.')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget _part(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: WasiyyatiColors.copper,
        fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 6),
      Text(value.trim().isEmpty ? 'غير مذكور' : value,
        style: const TextStyle(height: 1.8, fontSize: 14)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final w = widget.controller.will;
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة المسودة')),
      body: WScreenWidth(child: ListView(
        padding: const EdgeInsets.fromLTRB(23, 0, 23, 35),
        children: [
          const WPageIntro(eyebrow: 'معاينة الوثيقة', title: 'قبل التصدير',
            description: 'اقرأ التفاصيل، ثم راجعها شرعيًا وقانونيًا عند الحاجة.'),
          WPaperCard(radius: 6, padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: WDocumentSeal(size: 48)),
              const SizedBox(height: 15),
              const Center(child: Text('بسم الله الرحمن الرحيم',
                style: TextStyle(color: WasiyyatiColors.copper,
                  fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700))),
              const Divider(height: 29),
              const Text('مسودة وصية شخصية', style: TextStyle(
                fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 27)),
              const SizedBox(height: 25),
              _part('الاسم الكامل', w.fullName),
              _part('المدينة / البلد', w.city),
              _part('الشخص المعني بالتنفيذ', w.executorName),
              _part('وسيلة التواصل', w.executorContact),
              const Divider(height: 30),
              _part('نص الوصية', w.bequests),
              const Divider(height: 30),
              _part('إرشادات للأسرة', w.instructions),
              const Divider(height: 30),
              const Text('مسودة تنظيمية — لا تُعد وثيقة رسمية معتمدة',
                textAlign: TextAlign.center,
                style: TextStyle(color: WasiyyatiColors.warning,
                  fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: exporting ? null : _export,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(exporting ? 'جارٍ تجهيز PDF...' : 'تصدير نسخة للمراجعة')),
        ],
      )),
    );
  }
}
