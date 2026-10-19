import 'package:flutter/material.dart';

import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';

/// Earlier local drafts are stored inside the encrypted vault, not in
/// unencrypted preferences or documents.
class WillHistoryScreen extends StatelessWidget {
  const WillHistoryScreen({super.key, required this.controller});
  final VaultController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إصدارات مسودتي')),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final revisions = controller.revisions;
            return WScreenWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(23, 5, 23, 35),
                children: [
                  const WPageIntro(
                    eyebrow: 'دفتر النسخ • محلي ومشفّر',
                    title: 'ذاكرة الوثيقة',
                    description: 'راجع صياغاتك القديمة واستعد ما تحتاجه، دون فقدان المسودة الحالية.',
                  ),
                  const WInfoBanner(
                    icon: Icons.history_rounded,
                    text: 'يُحتفظ بآخر ٢٠ نسخة سابقة عند تغيير نص المسودة وحفظه. '
                        'هذه نسخ شخصية وليست توثيقًا رسميًا أو إثباتًا لاعتماد الوصية.',
                  ),
                  const SizedBox(height: 22),
                  SectionHeading(
                    'الإصدارات السابقة',
                    caption: '${revisions.length} نسخة محفوظة داخل الخزنة',
                  ),
                  if (revisions.isEmpty)
                    const EmptyInfo(
                      icon: Icons.auto_stories_outlined,
                      title: 'لا توجد إصدارات سابقة بعد',
                      message: 'بعد حفظ مسودتك ثم تعديلها وحفظها مجددًا، ستظهر نسختها القديمة هنا.',
                    )
                  else
                    ...revisions.asMap().entries.map((item) {
                      final revision = item.value;
                      final date = revision.savedAt.toLocal();
                      final localizations = MaterialLocalizations.of(context);
                      final readableDate = localizations.formatMediumDate(date);
                      final readableTime = localizations.formatTimeOfDay(
                        TimeOfDay.fromDateTime(date),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: WPaperCard(
                          padding: EdgeInsets.zero,
                          onTap: () async {
                            final restored = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _WillRevisionDetails(
                                  controller: controller,
                                  revision: revision,
                                ),
                              ),
                            );
                            if (restored == true && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: WasiyyatiColors.sage,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.history_edu_rounded,
                                    color: WasiyyatiColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'النسخة السابقة ${item.key + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$readableDate • $readableTime',
                                        style: const TextStyle(
                                          color: WasiyyatiColors.secondaryInk,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${revision.draft.filledFieldCount} حقول مدخلة',
                                        style: const TextStyle(
                                          color: WasiyyatiColors.copper,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_left_rounded,
                                  color: WasiyyatiColors.copper,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      );
}

class _WillRevisionDetails extends StatefulWidget {
  const _WillRevisionDetails({
    required this.controller,
    required this.revision,
  });
  final VaultController controller;
  final WillRevision revision;

  @override
  State<_WillRevisionDetails> createState() => _WillRevisionDetailsState();
}

class _WillRevisionDetailsState extends State<_WillRevisionDetails> {
  bool _busy = false;

  Future<void> _restore() async {
    if (_busy) {
      return;
    }
    final accepted = await confirmAction(
      context,
      title: 'استعادة هذه المسودة؟',
      message: 'ستصبح هذه النسخة هي مسودتك الحالية. '
          'ستُحفظ المسودة الحالية في سجل الإصدارات أولًا إن كانت تحتوي على بيانات. '
          'لا تتغير الديون والأمانات.',
      confirm: 'استعادة النسخة',
    );
    if (!accepted || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.restoreWillRevision(widget.revision.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: WasiyyatiColors.copper,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.trim().isEmpty ? 'غير مدخل' : value,
              style: const TextStyle(fontSize: 14, height: 1.8),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final draft = widget.revision.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة نسخة سابقة')),
      body: WScreenWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(23, 5, 23, 35),
          children: [
            const WPageIntro(
              eyebrow: 'وثيقة للقراءة فقط',
              title: 'نسخة سابقة',
              description: 'يمكنك مراجعتها قبل اختيار استعادتها.',
            ),
            WPaperCard(
              radius: 6,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: WDocumentSeal(size: 52)),
                  const SizedBox(height: 19),
                  _field('الاسم الكامل', draft.fullName),
                  _field('المدينة / البلد', draft.city),
                  _field('المعني بالتنفيذ', draft.executorName),
                  _field('وسيلة التواصل', draft.executorContact),
                  const Divider(height: 24),
                  _field('نص الوصية', draft.bequests),
                  const Divider(height: 24),
                  _field('إرشادات للأسرة', draft.instructions),
                  const Text(
                    'هذه مسودة شخصية سابقة — لا تُعد وثيقة موثقة',
                    style: TextStyle(
                      color: WasiyyatiColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('restore-will-revision'),
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore_rounded),
              label: Text(_busy ? 'جارٍ الاستعادة...' : 'استعادة هذه النسخة'),
            ),
          ],
        ),
      ),
    );
  }
}
