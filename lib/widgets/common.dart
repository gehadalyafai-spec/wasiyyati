import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/wasiyyati_theme.dart';

// Backward-compatible names retained for any older imports in the project.
const evergreen = WasiyyatiColors.ink;
const forest = WasiyyatiColors.ink;
const cream = WasiyyatiColors.canvas;
const muted = WasiyyatiColors.secondaryInk;

/// Caps horizontal width without forcing a fixed height.
class WScreenWidth extends StatelessWidget {
  const WScreenWidth({
    super.key,
    required this.child,
    this.shrinkWrapHeight = false,
  });
  final Widget child;

  /// The bottom navigation bar must occupy only its intrinsic height.
  /// A default Center in Scaffold.bottomNavigationBar can expand to the
  /// full viewport and leave no room for the body.
  final bool shrinkWrapHeight;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: child,
    );
    if (shrinkWrapHeight) {
      return Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: content,
      );
    }
    return Center(child: content);
  }
}

class WPageIntro extends StatelessWidget {
  const WPageIntro({super.key, required this.eyebrow, required this.title,
    this.description});
  final String eyebrow;
  final String title;
  final String? description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9, bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow, style: const TextStyle(color: WasiyyatiColors.copper,
          fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 5),
      Text(title, style: const TextStyle(
          fontFamily: 'serif', fontSize: 32, height: 1.35,
          fontWeight: FontWeight.w700, color: WasiyyatiColors.ink)),
      if (description != null) ...[
        const SizedBox(height: 8),
        Text(description!, style: const TextStyle(
            color: WasiyyatiColors.secondaryInk, height: 1.65, fontSize: 13)),
      ],
    ]),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.caption, this.trailing});
  final String title;
  final String? caption;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 3, height: 26,
        decoration: BoxDecoration(color: WasiyyatiColors.copper,
          borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(caption!, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ])),
      ?trailing,
    ]),
  );
}

class WPaperCard extends StatelessWidget {
  const WPaperCard({super.key, required this.child, this.padding = const EdgeInsets.all(18),
    this.onTap, this.radius = 19});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) => Material(
    color: WasiyyatiColors.paper,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: WasiyyatiColors.rule, width: .75),
    ),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius),
      child: Padding(padding: padding, child: child)),
  );
}

/// Ornamental embossing for a private draft, not an official/legal seal.
class WDocumentSeal extends StatelessWidget {
  const WDocumentSeal({super.key, this.size = 47, this.light = false});
  final double size;
  final bool light;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'رمز زخرفي للوثيقة غير الرسمية',
    child: CustomPaint(size: Size.square(size), painter: _SealPainter(
      light ? const Color(0xFFD9C19B) : WasiyyatiColors.copper)),
  );
}

class _SealPainter extends CustomPainter {
  const _SealPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * .43;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawCircle(center, r, stroke);
    canvas.drawCircle(center, r * .78, stroke);
    final diamond = Path()
      ..moveTo(center.dx, center.dy - r * .56)
      ..lineTo(center.dx + r * .56, center.dy)
      ..lineTo(center.dx, center.dy + r * .56)
      ..lineTo(center.dx - r * .56, center.dy)
      ..close();
    canvas.drawPath(diamond, stroke);
    canvas.drawCircle(center, r * .1, Paint()..color = color);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawCircle(Offset(center.dx + r * .9 * math.cos(angle),
          center.dy + r * .9 * math.sin(angle)), 1.4, Paint()..color = color);
    }
  }
  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) => oldDelegate.color != color;
}

class WDocumentHero extends StatelessWidget {
  const WDocumentHero({super.key, required this.hasDraft,
    required this.onOpen, this.lastReviewed});
  final bool hasDraft;
  final VoidCallback onOpen;
  final DateTime? lastReviewed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 8, top: 6),
    child: Stack(children: [
      Positioned.fill(top: 10, right: 9, child: DecoratedBox(
        decoration: BoxDecoration(color: WasiyyatiColors.copper.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(21)))),
      Material(color: WasiyyatiColors.ink, borderRadius: BorderRadius.circular(21),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onOpen, child: Stack(children: [
          Positioned(top: -42, left: -54,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF61736B).withValues(alpha: .35), width: 1.2)))),
          Padding(padding: const EdgeInsets.all(23), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const WDocumentSeal(light: true, size: 47),
                const Spacer(),
                Text('وثيقتي الشخصية', style: TextStyle(
                  color: const Color(0xFFDAC7A5).withValues(alpha: .94),
                  fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 18),
              const Text('كُلُّ حَقٍّ مَحفوظ',
                style: TextStyle(color: WasiyyatiColors.paper, fontFamily: 'serif',
                  fontSize: 30, height: 1.45, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('اجمع ما لك وما عليك في وثيقة واضحة، تحفظ حقوقك وتعين أسرتك.',
                style: TextStyle(color: Color(0xFFD6DFD7), fontSize: 12.5, height: 1.8)),
              const SizedBox(height: 21),
              const Divider(height: 1, color: Color(0xFF586C60)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text(hasDraft ? 'مسودتك محفوظة على الجهاز' : 'ابدأ مسودة وصيتك',
                  style: const TextStyle(color: Color(0xFFE5DAC4), fontWeight: FontWeight.w700,
                    fontSize: 13))),
                const Icon(Icons.arrow_back_rounded, color: Color(0xFFE5DAC4), size: 20),
              ]),
            ])),
        ])),
      ),
    ]),
  );
}

class WInfoBanner extends StatelessWidget {
  const WInfoBanner({super.key, required this.text, this.icon = Icons.info_outline_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: WasiyyatiColors.sage,
      borderRadius: BorderRadius.circular(16)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: WasiyyatiColors.ink, size: 20),
      const SizedBox(width: 11),
      Expanded(child: Text(text,
        style: const TextStyle(color: WasiyyatiColors.ink, height: 1.7, fontSize: 12.5))),
    ]),
  );
}

class WChapterHeader extends StatelessWidget {
  const WChapterHeader({super.key, required this.number, required this.title,
    this.subtitle});
  final String number, title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 19, bottom: 13),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 39, height: 39, alignment: Alignment.center,
        decoration: BoxDecoration(color: WasiyyatiColors.ink,
          borderRadius: BorderRadius.circular(12)),
        child: Text(number, style: const TextStyle(
          color: WasiyyatiColors.paper, fontWeight: FontWeight.w800))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        if (subtitle != null) Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(subtitle!, style: const TextStyle(fontSize: 11.5,
            color: WasiyyatiColors.secondaryInk, height: 1.6))),
      ])),
    ]),
  );
}

class EmptyInfo extends StatelessWidget {
  const EmptyInfo({super.key, required this.icon, required this.title,
    required this.message, this.action});
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(18),
    child: WPaperCard(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const WDocumentSeal(size: 62),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(height: 1.65, color: muted, fontSize: 13)),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    )),
  ));
}

InputDecoration formDecoration(String title, {String? hint}) => InputDecoration(
  labelText: title, hintText: hint, alignLabelWithHint: true);

Future<bool> confirmAction(BuildContext context, {required String title,
  required String message, String confirm = 'متابعة'}) async =>
  await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirm)),
    ],
  )) ?? false;

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('تعذّر حفظ التغييرات. تحقق من مساحة الجهاز وحاول مجددًا.')));
}
