import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_lock.dart';
import '../services/pdf_export.dart';
import '../services/portable_backup.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';
import 'will_screen.dart';
import 'will_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller, required this.appLock});
  final VaultController controller;
  final AppLock appLock;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } on FormatException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('تعذّر إتمام العملية. تحقق من الملف والمحاولة.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> _askPassword({required bool creating}) async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? validation;
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) =>
          AlertDialog(
            title: Text(creating ? 'حماية النسخة الاحتياطية' : 'كلمة مرور النسخة'),
            content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('هذه الكلمة منفصلة عن رمز الهاتف. إذا فقدتها، لا يمكن فك تشفير النسخة.'),
                const SizedBox(height: 14),
                TextField(controller: first, obscureText: true,
                  enableSuggestions: false, autocorrect: false,
                  decoration: const InputDecoration(labelText: 'كلمة مرور النسخة')),
                if (creating) ...[
                  const SizedBox(height: 12),
                  TextField(controller: second, obscureText: true,
                    enableSuggestions: false, autocorrect: false,
                    decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور')),
                ],
                if (validation != null) ...[
                  const SizedBox(height: 10),
                  Text(validation!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            )),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (first.text.isEmpty ||
                      (creating && first.text.runes.length < PortableBackup.minPasswordLength)) {
                    setDialogState(() => validation = creating
                      ? 'استخدم ١٢ حرفًا على الأقل.' : 'أدخل كلمة المرور.');
                    return;
                  }
                  if (creating && first.text != second.text) {
                    setDialogState(() => validation = 'الكلمتان غير متطابقتين.');
                    return;
                  }
                  Navigator.pop(dialogContext, first.text);
                },
                child: const Text('متابعة'),
              ),
            ],
          )),
      );
    } finally {
      first.dispose();
      second.dispose();
    }
  }

  Future<void> _exportPdf() async {
    if (busy) return;
    final accepted = await confirmAction(context,
      title: 'تصدير ملف غير مشفر',
      message: 'يحوي PDF معلومات حساسة. لا تشاركه إلا مع شخص موثوق. ولا يُعد توثيقًا رسميًا.',
      confirm: 'تصدير');
    if (!accepted || !mounted) return;
    await _withBusy(() async {
      await PdfExport.share(widget.controller.snapshot);
    });
  }

  Future<void> _exportBackup() async {
    if (busy) return;
    final password = await _askPassword(creating: true);
    if (password == null || !mounted) return;
    await _withBusy(() async {
      final data = await PortableBackup.create(widget.controller.snapshot, password);
      // Only ciphertext is ever written to the shareable temporary file.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}wasiyyati-${DateTime.now().millisecondsSinceEpoch}.wbackup');
      await file.writeAsString(data, flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: 'نسخة وصيتي المشفرة',
      ));
      _message('احفظ النسخة في مكان آمن، وتأكد من إمكان الوصول إليها عند الحاجة.');
    });
  }

  Future<void> _importBackup() async {
    if (busy) return;
    final selection = await FilePicker.pickFile(
      type: FileType.custom, allowedExtensions: ['wbackup']);
    if (selection == null || !mounted) return;
    final length = selection.lengthSync() ?? await selection.length();
    if (length == null || length > PortableBackup.maxEncodedLength) {
      _message('تعذّر قراءة الحجم أو الملف كبير جدًا.');
      return;
    }
    final password = await _askPassword(creating: false);
    if (password == null || !mounted) return;
    await _withBusy(() async {
      // Authenticate BEFORE asking to replace any existing data.
      final bytes = await selection.readAsBytes();
      if (bytes.length > PortableBackup.maxEncodedLength) {
        throw const FormatException('حجم غير مدعوم');
      }
      final restored = await PortableBackup.restore(utf8.decode(bytes), password);
      if (!mounted) return;
      final accepted = await confirmAction(context,
        title: 'استبدال بيانات الخزنة؟',
        message: 'سيُستبدل محتوى وصيتك وحقوقك الحالي بمحتوى النسخة الاحتياطية. '
          'أنشئ نسخة من بياناتك الحالية قبل الموافقة. هذه الخطوة لا تدمج السجلات.',
        confirm: 'نعم، استبدال البيانات');
      if (!accepted || !mounted) return;
      await widget.controller.replaceFromBackup(restored);
      _message('استُعيدت النسخة المشفرة بنجاح.');
    });
  }

  Future<void> _changeLock(bool value) async {
    if (busy) return;
    await _withBusy(() async {
      final ok = await widget.appLock.setEnabled(value);
      if (!ok) {
        _message('لم تتغير الحماية. فعّل قفل الشاشة في جهازك ثم حاول مرة أخرى.');
      } else {
        _message(value ? 'تم تفعيل قفل وصيتي.' : 'تم إيقاف قفل وصيتي.');
      }
    });
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback action) =>
      WPaperCard(padding: EdgeInsets.zero, onTap: busy ? null : action,
        child: ListTile(
          leading: Icon(icon, color: WasiyyatiColors.ink),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded, color: WasiyyatiColors.copper),
        ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الخصوصية والوثائق')),
    body: WScreenWidth(child: ListView(
      padding: const EdgeInsets.fromLTRB(23, 0, 23, 34),
      children: [
        const WPageIntro(eyebrow: 'مساحة محمية محليًا',
          title: 'خزنة الوثائق',
          description: 'احفظ نسخة مستقلة من معلوماتك، وتحكم في قفل التطبيق.'),
        Container(padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(color: WasiyyatiColors.ink,
            borderRadius: BorderRadius.circular(22)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WDocumentSeal(size: 50, light: true),
            SizedBox(height: 14),
            Text('وثيقتك، وخصوصيتك', style: TextStyle(
              color: WasiyyatiColors.paper, fontSize: 21,
              fontWeight: FontWeight.w800)),
            SizedBox(height: 9),
            Text('التخزين مشفر محليًا. ويمكنك إضافة قفل الجهاز وتصدير نسخة احتياطية محمية بكلمة مرور مستقلة.',
              style: TextStyle(color: Color(0xFFD9E3D9), fontSize: 12.5, height: 1.8)),
          ]),
        ),
        const SizedBox(height: 24),
        const SectionHeading('قفل التطبيق', caption: 'بصمة أو رمز قفل الجهاز'),
        WPaperCard(child: AnimatedBuilder(animation: widget.appLock,
          builder: (context, _) => SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('تفعيل قفل وصيتي'),
            subtitle: const Text('يطلب التحقق عند فتح التطبيق والعودة إليه.'),
            value: widget.appLock.enabled,
            onChanged: busy ? null : _changeLock,
          ))),
        const SizedBox(height: 23),
        const SectionHeading('النسخ الاحتياطي', caption: 'النسخة مشفرة وقابلة للاستعادة على جهاز آخر'),
        _tile(Icons.enhanced_encryption_outlined, 'إنشاء نسخة مشفرة',
          'ملف محمي بكلمة مرور تختارها، ويصلح للنقل بين الأجهزة.', _exportBackup),
        const SizedBox(height: 9),
        _tile(Icons.settings_backup_restore_rounded, 'استعادة نسخة محفوظة',
          'يتطلب كلمة المرور، ويستبدل بيانات الخزنة الحالية بعد تأكيدك.', _importBackup),
        const SizedBox(height: 23),
        const SectionHeading('المسودة'),
        _tile(Icons.menu_book_outlined, 'معاينة مسودة الوصية',
          'الاطلاع دون مشاركتها', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => WillPreviewScreen(controller: widget.controller)))),
        const SizedBox(height: 9),
        _tile(Icons.history_rounded, 'الإصدارات السابقة للوصية',
          'معاينة صياغات قديمة واستعادتها إلى المسودة الحالية',
          () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => WillHistoryScreen(controller: widget.controller)))),
        const SizedBox(height: 9),
        _tile(Icons.picture_as_pdf_outlined, 'تصدير PDF غير مشفر',
          'مخصص للطباعة والمراجعة، وليس وثيقة رسمية', _exportPdf),
        const SizedBox(height: 23),
        const WInfoBanner(text: 'لا تخزن كلمات مرور الحسابات البنكية. '
          'قفل الشاشة يحمي العرض، والتشفير يحمي الملفات على الجهاز. '
          'لا تشارك النسخة الاحتياطية مع كلمة مرورها في القناة نفسها.'),
        const SizedBox(height: 22),
        const Text('وصيتي • الإصدار 0.4.0', textAlign: TextAlign.center,
          style: TextStyle(color: WasiyyatiColors.secondaryInk, fontSize: 11.5)),
      ],
    )),
  );
}
