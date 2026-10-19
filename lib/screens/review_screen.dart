import 'package:flutter/material.dart';

import '../models/vault_data.dart';
import '../services/vault_controller.dart';
import '../theme/wasiyyati_theme.dart';
import '../utils/record_details.dart';
import '../utils/review_schedule.dart';
import '../widgets/common.dart';
import 'entry_form.dart';
import 'records_screen.dart';

/// An on-device review list, based only on dates chosen by the user.
/// This page does not schedule OS notifications or validate legal deadlines.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.controller});

  final VaultController controller;

  Future<void> _openEntry(BuildContext context, VaultEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EntryForm(controller: controller, entry: entry),
      ),
    );
  }

  Future<void> _completeEntry(BuildContext context, VaultEntry entry) async {
    final agreed = await confirmAction(
      context,
      title: 'تأكيد تسوية السجل',
      message: 'هل تريد وضع علامة «تمت التسوية» على هذا السجل؟ '
          'يمكن إعادة تعديل الحالة لاحقًا من سجل الحقوق.',
      confirm: 'تأكيد التسوية',
    );
    if (!agreed || !context.mounted) {
      return;
    }
    try {
      await controller.changeCompleted(entry, true);
    } catch (error) {
      if (context.mounted) {
        showError(context, error);
      }
    }
  }

  List<Widget> _section(
    BuildContext context, {
    required String heading,
    required String caption,
    required List<VaultEntry> entries,
    required DateTime today,
    required IconData icon,
    required bool late,
  }) => [
    Padding(
      padding: const EdgeInsets.only(top: 15),
      child: SectionHeading(
        heading,
        caption: '$caption • ${entries.length} سجل',
      ),
    ),
    for (final record in entries) ...[
      _recordCard(context, record, today, icon, late),
      const SizedBox(height: 9),
    ],
  ];

  Widget _recordCard(
    BuildContext context,
    VaultEntry entry,
    DateTime today,
    IconData icon,
    bool late,
  ) {
    final due = entry.dueDate!;
    final isMoneyRight =
        entry.kind == EntryKind.owed || entry.kind == EntryKind.receivable;
    return WPaperCard(
      key: ValueKey('review-record-${entry.id}'),
      onTap: () => _openEntry(context, entry),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: late ? const Color(0xFFF5E9E2) : WasiyyatiColors.sage,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: late ? WasiyyatiColors.warning : WasiyyatiColors.ink,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.kind.plural}'
                      '${entry.party.isEmpty ? '' : ' • ${entry.party}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: WasiyyatiColors.secondaryInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_left_rounded,
                color: WasiyyatiColors.secondaryInk,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatRecordDate(due),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                reviewRelativeLabel(due, today),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: late
                      ? WasiyyatiColors.warning
                      : WasiyyatiColors.secondaryInk,
                ),
              ),
              if (entry.amount != null)
                Text(
                  '${entry.amount} ${currencyDescription(entry.currencyCode)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: WasiyyatiColors.secondaryInk,
                  ),
                ),
            ],
          ),
          if (isMoneyRight) ...[
            const Divider(height: 24),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _completeEntry(context, entry),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('تمت التسوية'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('متابعة المواعيد')),
    body: WScreenWidth(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final today = DateTime.now();
          final plan = ReviewSchedule.fromEntries(controller.entries, today);
          return ListView(
            key: const Key('review-list'),
            padding: const EdgeInsets.fromLTRB(23, 4, 23, 36),
            children: [
              const WPageIntro(
                eyebrow: 'دفتر الحقوق • جدول المراجعة',
                title: 'ما يحتاج متابعة',
                description: 'مواعيد كتبتها بنفسك للحقوق والأمانات والممتلكات.',
              ),
              WPaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص المواعيد المسجلة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        Text('فات موعدها: ${plan.overdue.length}'),
                        Text('اليوم: ${plan.today.length}'),
                        Text('خلال ٧ أيام: ${plan.upcoming.length}'),
                        Text('لاحقًا: ${plan.later.length}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const WInfoBanner(
                icon: Icons.info_outline_rounded,
                text: 'هذا جدول للمراجعة داخل التطبيق فقط؛ '
                    'لا يرسل إشعارات تلقائية، ولا يعني انتهاء الموعد '
                    'وجود تأخر قانوني أو ثبوت دين.',
              ),
              if (plan.isEmpty) ...[
                const SizedBox(height: 20),
                const EmptyInfo(
                  icon: Icons.event_available_outlined,
                  title: 'لا توجد مواعيد تحتاج متابعة',
                  message: 'يمكنك إضافة موعد اختياري لأي سجل من سجل الحقوق.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => RecordsScreen(controller: controller),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('فتح سجل الحقوق'),
                ),
              ] else ...[
                if (plan.overdue.isNotEmpty)
                  ..._section(
                    context,
                    heading: 'مواعيد مضت',
                    caption: 'تحقق من حالة هذه السجلات',
                    entries: plan.overdue,
                    today: today,
                    icon: Icons.error_outline_rounded,
                    late: true,
                  ),
                if (plan.today.isNotEmpty)
                  ..._section(
                    context,
                    heading: 'مواعيد اليوم',
                    caption: 'موعد مراجعة أو استحقاق مسجّل',
                    entries: plan.today,
                    today: today,
                    icon: Icons.today_outlined,
                    late: false,
                  ),
                if (plan.upcoming.isNotEmpty)
                  ..._section(
                    context,
                    heading: 'خلال الأيام السبعة القادمة',
                    caption: 'مرتبة من الأقرب إلى الأبعد',
                    entries: plan.upcoming,
                    today: today,
                    icon: Icons.event_outlined,
                    late: false,
                  ),
                if (plan.later.isNotEmpty)
                  ..._section(
                    context,
                    heading: 'مواعيد لاحقة',
                    caption: 'سجلات للمراجعة مستقبلًا',
                    entries: plan.later,
                    today: today,
                    icon: Icons.event_note_outlined,
                    late: false,
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
