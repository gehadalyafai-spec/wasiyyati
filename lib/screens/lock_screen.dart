import 'package:flutter/material.dart';

import '../services/app_lock.dart';
import '../theme/wasiyyati_theme.dart';
import '../widgets/common.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.lock});
  final AppLock lock;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: WScreenWidth(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const WDocumentSeal(size: 76),
            const SizedBox(height: 24),
            const Text('وصيتي محمية', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800,
              color: WasiyyatiColors.ink)),
            const SizedBox(height: 12),
            const Text('استخدم بصمة الجهاز أو رمز قفل الشاشة للمتابعة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WasiyyatiColors.secondaryInk, height: 1.7)),
            const SizedBox(height: 22),
            if (lock.error != null) ...[
              Text(lock.error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: lock.authenticating ? null : () async {
                lock.clearTemporaryAuthError();
                await lock.unlock();
              },
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(lock.authenticating ? 'جارٍ التحقق...' : 'فتح الخزنة'),
            ),
          ]),
        )),
      ),
    ),
  );
}
