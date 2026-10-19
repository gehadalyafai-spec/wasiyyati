import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/pdf_export.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';
import 'will_history_screen.dart';

enum _LeaveChoice { save, discard }

class WillScreen extends StatefulWidget {
  const WillScreen({super.key, required this.controller});
  final VaultController controller;
  @override
  State<WillScreen> createState() => WillScreenState();
}

/// Public State type so the root navigation can ask before leaving the editor.
class WillScreenState extends State<WillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _city, _executor, _phone,
      _bequests, _instructions;
  bool _busy = false;
  bool _reloading = false;
  bool _leaveDialogOpen = false;

  List<TextEditingController> get _fields => [
    _name, _city, _executor, _phone, _bequests, _instructions,
  ];

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
    for (final field in _fields) {
      field.addListener(_onTextEdited);
    }
  }

  void _onTextEdited() {
    if (!_reloading && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.removeListener(_onTextEdited);
      field.dispose();
    }
    super.dispose();
  }

  WillDraft _draftFromInputs({DateTime? reviewedAt}) => WillDraft(
    fullName: _name.text.trim(),
    city: _city.text.trim(),
    executorName: _executor.text.trim(),
    executorContact: _phone.text.trim(),
    bequests: _bequests.text.trim(),
    instructions: _instructions.text.trim(),
    lastReviewed: reviewedAt ?? widget.controller.will.lastReviewed,
  );

  bool get hasUnsavedChanges =>
      !_draftFromInputs().hasSameContent(widget.controller.will);

  void _loadSavedDraft() {
    final draft = widget.controller.will;
    _reloading = true;
    try {
      _name.text = draft.fullName;
      _city.text = draft.city;
      _executor.text = draft.executorName;
      _phone.text = draft.executorContact;
      _bequests.text = draft.bequests;
      _instructions.text = draft.instructions;
    } finally {
      _reloading = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _save({bool showFeedback = true}) async {
    if (_busy) {
      return false;
    }
    if (!hasUnsavedChanges) {
      return true;
    }
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    final draft = _draftFromInputs(reviewedAt: DateTime.now());
    setState(() => _busy = true);
    try {
      await widget.controller.saveWill(draft);
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('حُفظت المسودة مشفرة على هذا الجهاز'),
        ));
      }
      return true;
    } catch (error) {
      if (mounted) {
        showError(context, error);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Best-effort encrypted save before the app is hidden by the device lock.
  /// Navigation between tabs always waits for an explicit save/discard choice.
  Future<void> saveOnBackground() async {
    if (mounted && hasUnsavedChanges && !_busy) {
      await _save(showFeedback: false);
    }
  }

  /// False means that the tab transition or back navigation must be cancelled.
  Future<bool> confirmLeave() async {
    if (!mounted || _busy || _leaveDialogOpen) {
      return false;
    }
    if (!hasUnsavedChanges) {
      return true;
    }
    _leaveDialogOpen = true;
    try {
      final choice = await showDialog<_LeaveChoice>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تغييرات لم تُحفظ'),
          content: const Text(
            'عدّلت مسودة الوصية. هل تريد حفظ التغييرات مشفرة قبل المغادرة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, _LeaveChoice.discard),
              child: const Text('تجاهل التعديلات'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, _LeaveChoice.save),
              child: const Text('حفظ ومغادرة'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null) {
        return false;
      }
      if (choice == _LeaveChoice.discard) {
        _loadSavedDraft();
        return true;
      }
      return await _save(showFeedback: false);
    } finally {
      _leaveDialogOpen = false;
    }
  }

  Future<void> _handleSystemBack(bool didPop) async {
    if (didPop) {
      return;
    }
    if (await confirmLeave() && mounted) {
      // Allow PopScope to rebuild with a clean editor before retrying the pop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  Future<void> _openHistory() async {
    if (!await _save(showFeedback: false) || !mounted) {
      return;
    }
    final restored = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => WillHistoryScreen(controller: widget.controller),
    ));
    if (restored == true && mounted) {
      _loadSavedDraft();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تمت استعادة المسودة السابقة وحُفظت مشفرة'),
      ));
    }
  }

  Future<void> _review() async {
    if (await _save(showFeedback: false) && mounted) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => WillPreviewScreen(controller: widget.controller),
      ));
    }
  }

  Widget _textField(TextEditingController controller, String label, int limit,
      {int lines = 1, String? hint, Key? fieldKey}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: fieldKey,
      controller: controller,
      readOnly: _busy,
      maxLines: lines,
      maxLength: limit,
      decoration: formDecoration(label, hint: hint),
    ),
  );

  Widget _chapter(int index, String title, String description,
      List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 13),
    child: WPaperCard(padding: EdgeInsets.zero, radius: 18,
      child: ExpansionTile(
        key: ValueKey('will-chapter-$index'),
        maintainState: true,
        initiallyExpanded: index == 1,
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(17, 0, 17, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 39, height: 39, alignment: Alignment.center,
          decoration: BoxDecoration(color: WasiyyatiColors.ink,
            borderRadius: BorderRadius.circular(12)),
          child: Text('$index', style: const TextStyle(
            color: WasiyyatiColors.paper, fontWeight: FontWeight.w800)),
        ),
        title: Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800)),
        subtitle: Text(description, style: const TextStyle(
          color: WasiyyatiColors.secondaryInk, fontSize: 11.5, height: 1.5)),
        children: [const Divider(height: 18), ...children],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final current = _draftFromInputs();
    final fields = current.filledFieldCount;
    final dirty = hasUnsavedChanges;
    return PopScope(
      canPop: !dirty && !_busy,
      onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
      child: Scaffold(
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
                      Text('مسودتك الشخصية', style: TextStyle(
                        color: WasiyyatiColors.paper,
                        fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('المؤشر لعدد الحقول المكتوبة، وليس لصحة الوصية',
                        style: TextStyle(color: Color(0xFFCFD8CF), fontSize: 10.5)),
                    ])),
                ]),
                const SizedBox(height: 15),
                LinearProgressIndicator(value: fields / WillDraft.editableFieldCount,
                  minHeight: 5, backgroundColor: const Color(0xFF53665C),
                  valueColor: const AlwaysStoppedAnimation(WasiyyatiColors.copper),
                  borderRadius: BorderRadius.circular(10)),
                const SizedBox(height: 9),
                Text('الحقول المكتوبة: $fields من ${WillDraft.editableFieldCount}',
                  style: const TextStyle(color: Color(0xFFD4DDCF), fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(dirty ? Icons.edit_note_rounded : Icons.check_circle_outline_rounded,
                    size: 17, color: const Color(0xFFE5DAC4)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    dirty ? 'تغييرات غير محفوظة' : 'لا توجد تغييرات معلّقة',
                    key: const Key('will-save-status'),
                    style: const TextStyle(color: Color(0xFFE5DAC4),
                      fontWeight: FontWeight.w700, fontSize: 12))),
                ]),
              ])),
            const SizedBox(height: 15),
            const WInfoBanner(
              text: 'هذه مسودة تنظيمية غير موثّقة. بعض الوصايا تخضع لشروط شرعية وقانونية خاصة؛ راجعها مع مختص في بلدك.'),
            _chapter(1, 'بيانات الموصي', 'معلومات التعريف الأساسية بالوثيقة', [
              _textField(_name, 'الاسم الكامل', 120,
                fieldKey: const Key('will-full-name')),
              _textField(_city, 'المدينة / البلد', 80),
            ]),
            _chapter(2, 'المعني بتنفيذ الوصية',
              'تسجيل بياناته لا يمنحه صلاحيات رسمية تلقائيًا', [
              _textField(_executor, 'اسم الشخص', 120),
              _textField(_phone, 'وسيلة التواصل', 100),
            ]),
            _chapter(3, 'نص الوصية',
              'مسودة لعرضها على مختص شرعي وقانوني قبل اعتمادها', [
              _textField(_bequests, 'ما تريد الوصية به', 6000, lines: 6,
                hint: 'اكتب الوصايا التي ترغب بمراجعتها وتوثيقها'),
            ]),
            _chapter(4, 'ملاحظات للأسرة',
              'معلومات تنظيمية مفيدة دون كلمات مرور أو رموز سرية', [
              _textField(_instructions, 'إرشادات ومواقع المستندات', 4000,
                lines: 5, hint: 'مثال: مكان حفظ وثائق الملكية'),
            ]),
            const SizedBox(height: 25),
            FilledButton.icon(
              key: const Key('save-will'),
              onPressed: _busy || !dirty ? null : () => _save(),
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(_busy ? 'جارٍ الحفظ...' : 'حفظ المسودة المشفرة'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _review,
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('حفظ ثم معاينة الوثيقة'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('will-history'),
              onPressed: _busy ? null : _openHistory,
              icon: const Icon(Icons.history_rounded),
              label: Text('الإصدارات السابقة (${widget.controller.revisions.length})'),
            ),
            const SizedBox(height: 15),
            const Text('سيُطلب منك حفظ التغييرات أو تجاهلها قبل مغادرة المحرر.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WasiyyatiColors.secondaryInk, fontSize: 11.5)),
          ]),
        )),
      ),
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
          const WInfoBanner(text: 'هذه المعاينة تعرض آخر مسودة محفوظة فقط. '
            'أي تعديلات غير محفوظة لا تدخل في هذه النسخة.'),
          const SizedBox(height: 16),
          WPaperCard(radius: 6, padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const WDocumentSeal(size: 48),
                const Spacer(),
                Text('مسودة للمراجعة فقط', style: TextStyle(
                  color: WasiyyatiColors.secondaryInk,
                  fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 15),
              const Center(child: Text('بسم الله الرحمن الرحيم',
                style: TextStyle(color: WasiyyatiColors.copper,
                  fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700))),
              const Divider(height: 29),
              const Text('مسودة وصية شخصية', style: TextStyle(
                fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 27)),
              const SizedBox(height: 8),
              Text('الحقول الواردة: ${w.filledFieldCount} من '
                '${WillDraft.editableFieldCount}',
                style: const TextStyle(color: WasiyyatiColors.secondaryInk,
                  fontSize: 12)),
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
