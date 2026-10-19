import 'package:flutter/material.dart';
import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../utils/arabic_number.dart';
import '../utils/record_details.dart';
import '../widgets/common.dart';

class EntryForm extends StatefulWidget {
  const EntryForm({super.key, required this.controller, this.entry, this.defaultKind});
  final VaultController controller;
  final VaultEntry? entry;
  final EntryKind? defaultKind;
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title, _party, _amount, _notes;
  late EntryKind _kind;
  String? _currencyCode;
  DateTime? _dueDate;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final item = widget.entry;
    _title = TextEditingController(text: item?.title ?? '');
    _party = TextEditingController(text: item?.party ?? '');
    _amount = TextEditingController(text: item?.amount?.toString() ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _kind = item?.kind ?? widget.defaultKind ?? EntryKind.owed;
    _currencyCode = item?.currencyCode;
    _dueDate = item?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _party.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (chosen != null && mounted) {
      setState(() => _dueDate = chosen);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    final now = DateTime.now();
    final old = widget.entry;
    final amount = _amount.text.trim();
    final record = VaultEntry(
      id: old?.id ?? widget.controller.newId(),
      kind: _kind,
      title: _title.text.trim(),
      party: _party.text.trim(),
      amount: amount.isEmpty ? null : parseMoneyInput(amount),
      currencyCode: amount.isEmpty ? null : _currencyCode,
      dueDate: _dueDate,
      notes: _notes.text.trim(),
      completed: old?.completed ?? false,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await widget.controller.saveEntry(record);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.entry == null ? 'إضافة حق' : 'تعديل السجل')),
    body: WScreenWidth(child: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(23, 0, 23, 35), children: [
        WPageIntro(
          eyebrow: 'فصل الحقوق • سجل شخصي',
          title: widget.entry == null ? 'قيد جديد' : 'تحرير القيد',
          description: 'المعلومات تُحفظ مشفرة في خزنتك داخل الجهاز.'),
        const WChapterHeader(number: '١', title: 'نوع السجل',
          subtitle: 'اختر الصنف الأقرب لهذا الحق أو الأمانة'),
        WPaperCard(child: DropdownButtonFormField<EntryKind>(
          key: const Key('entry-kind'),
          initialValue: _kind,
          isExpanded: true,
          decoration: formDecoration('التصنيف'),
          items: EntryKind.values.map((kind) => DropdownMenuItem(
            value: kind, child: Text(kind.plural))).toList(),
          onChanged: (kind) => setState(() => _kind = kind ?? _kind),
        )),
        const WChapterHeader(number: '٢', title: 'البيانات الأساسية',
          subtitle: 'ساعد نفسك وأسرتك في التعرف على الحق لاحقًا'),
        WPaperCard(child: Column(children: [
          TextFormField(
            key: const Key('entry-title'),
            controller: _title, maxLength: 120,
            decoration: formDecoration('عنوان السجل *',
              hint: 'مثال: مبلغ مستحق لصديق'),
            validator: (value) => value == null || value.trim().isEmpty
              ? 'أدخل عنوانًا' : null,
          ),
          const SizedBox(height: 9),
          TextFormField(controller: _party, maxLength: 120,
            decoration: formDecoration('الشخص أو الجهة المعنية')),
          const SizedBox(height: 9),
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: formDecoration('المبلغ (اختياري)',
              hint: 'مثل ١٥٠٠ أو 1500.50'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final number = parseMoneyInput(value);
              if (number == null || !number.isFinite || number < 0) {
                return 'أدخل مبلغًا صحيحًا غير سالب';
              }
              return null;
            },
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            key: const Key('entry-currency'),
            initialValue: _currencyCode ?? '',
            isExpanded: true,
            decoration: formDecoration('العملة (اختياري)'),
            items: [
              const DropdownMenuItem<String>(
                value: '', child: Text('غير محددة'),
              ),
              for (final option in supportedRecordCurrencies.entries)
                DropdownMenuItem<String>(
                  value: option.key,
                  child: Text('${option.value} (${option.key})'),
                ),
              if (_currencyCode != null &&
                  !supportedRecordCurrencies.containsKey(_currencyCode))
                DropdownMenuItem<String>(
                  value: _currencyCode!,
                  child: Text(_currencyCode!),
                ),
            ],
            onChanged: (value) => setState(
              () => _currencyCode = value == null || value.isEmpty ? null : value,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              key: const Key('entry-due-date'),
              onPressed: _pickDueDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(_dueDate == null
                  ? 'إضافة موعد استحقاق أو مراجعة'
                  : 'الموعد: ${formatRecordDate(_dueDate!)}'),
            )),
            if (_dueDate != null)
              IconButton(
                tooltip: 'إزالة الموعد',
                onPressed: () => setState(() => _dueDate = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ]),
        ])),
        const WChapterHeader(number: '٣', title: 'تفاصيل داعمة',
          subtitle: 'متى نشأ الحق؟ أين يوجد المستند؟ وما الذي ينبغي معرفته؟'),
        WPaperCard(child: TextFormField(
          controller: _notes, maxLength: 4000, maxLines: 6,
          decoration: formDecoration('الملاحظات',
            hint: 'تفاصيل الاتفاق أو مكان الإثبات. لا تضع كلمات مرور.'),
        )),
        const SizedBox(height: 19),
        const WInfoBanner(text: 'هذا السجل للتنظيم الشخصي، ولا يثبت دينًا أو ملكية دون مستندات وإجراءات معتبرة.'),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('save-entry'),
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.lock_outline_rounded),
          label: Text(_busy ? 'جارٍ الحفظ...' : 'حفظ في الخزنة'),
        ),
      ]),
    )),
  );
}
