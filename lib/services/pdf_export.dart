import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/vault_data.dart';

class PdfExport {
  static Future<void> share(VaultData data) async {
    // Google Fonts are downloaded by printing on first use; connectivity may
    // be required. Future release should bundle a licensed local Arabic font.
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final doc = pw.Document();
    final textStyle = pw.TextStyle(font: regular, fontSize: 11);
    final headStyle = pw.TextStyle(font: bold, fontSize: 14);
    final will = data.will;
    final grouped = EntryKind.values.map((kind) {
      final entries = data.entries.where((entry) => entry.kind == kind).toList();
      if (entries.isEmpty) return <pw.Widget>[];
      return <pw.Widget>[
        pw.SizedBox(height: 12),
        pw.Text(kind.plural, style: headStyle, textDirection: pw.TextDirection.rtl),
        ...entries.expand((entry) => _paragraphs(
              '• ${entry.title} — ${entry.party.isEmpty ? 'دون اسم' : entry.party}'
              '${entry.amount == null ? '' : ' — ${entry.amount}'}'
              '${entry.completed ? ' — تمت التسوية' : ''}'
              '${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
              textStyle,
            )),
      ];
    }).expand((elements) => elements).toList();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text('مسودة وصيتي — وثيقة شخصية غير موثّقة', style: pw.TextStyle(font: bold, fontSize: 17)),
        pw.SizedBox(height: 6),
        pw.Text('لا تعد هذه النسخة توثيقًا رسميًا أو فتوى شرعية.', style: textStyle),
        pw.Divider(),
        _line('الاسم', will.fullName, textStyle),
        _line('المدينة', will.city, textStyle),
        _line('المكلّف بالتنفيذ', will.executorName, textStyle),
        _line('وسيلة التواصل', will.executorContact, textStyle),
        pw.SizedBox(height: 12),
        pw.Text('نص الوصية المراد مراجعته', style: headStyle),
        ..._paragraphs(will.bequests.isEmpty ? 'لم يُكتب بعد' : will.bequests, textStyle),
        pw.SizedBox(height: 12),
        pw.Text('تعليمات ومعلومات إضافية', style: headStyle),
        ..._paragraphs(will.instructions.isEmpty ? 'لا توجد' : will.instructions, textStyle),
        ...grouped,
        pw.SizedBox(height: 16),
        pw.Text('تنبيه: مشاركة هذا الملف تكشف المعلومات الواردة فيه لمن يحصل عليه.', style: textStyle),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'wasiyyati-draft.pdf');
  }

  // Limit each PDF text widget so large personal notes can flow across pages.
  static List<pw.Widget> _paragraphs(String input, pw.TextStyle style) {
    final result = <pw.Widget>[];
    for (var start = 0; start < input.length; start += 300) {
      final end = (start + 300 < input.length) ? start + 300 : input.length;
      result.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(input.substring(start, end), style: style,
          textDirection: pw.TextDirection.rtl),
      ));
    }
    return result;
  }

  static pw.Widget _line(String label, String value, pw.TextStyle style) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Text('$label: ${value.isEmpty ? 'غير محدد' : value}', style: style),
      );
}
