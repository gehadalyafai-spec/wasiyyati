import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/records_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/will_screen.dart';
import 'services/app_lock.dart';
import 'services/encrypted_vault.dart';
import 'services/vault_controller.dart';
import 'theme/wasiyyati_theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WasiyyatiApp());
}

class WasiyyatiApp extends StatefulWidget {
  const WasiyyatiApp({super.key});
  @override
  State<WasiyyatiApp> createState() => _WasiyyatiAppState();
}

class _WasiyyatiAppState extends State<WasiyyatiApp>
    with WidgetsBindingObserver {
  late final VaultController controller;
  late final AppLock appLock;
  int selected = 0;
  final _willEditorKey = GlobalKey<WillScreenState>();

  Future<void> _switchTab(int index) async {
    if (index == selected) {
      return;
    }
    if (selected == 2) {
      final permitted = await _willEditorKey.currentState?.confirmLeave() ?? true;
      if (!permitted || !mounted) {
        return;
      }
    }
    if (mounted) {
      setState(() => selected = index);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appLock = AppLock();
    controller = VaultController(EncryptedVault());
    appLock.initialize();
    controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (selected == 2) {
        // Do not lose unsaved text when locking replaces the active screen.
        _willEditorKey.currentState?.saveOnBackground();
      }
      appLock.lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appLock.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'وصيتي',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl, child: child!),
    theme: buildWasiyyatiTheme(),
    home: AnimatedBuilder(
      animation: Listenable.merge([controller, appLock]), builder: (context, _) {
      if (!appLock.ready) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (appLock.locked) {
        return LockScreen(lock: appLock);
      }
      if (controller.error case final String error) {
        return Scaffold(body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const WDocumentSeal(size: 64),
            const SizedBox(height: 18),
            const Text('تعذّر فتح الخزنة بأمان',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 15),
            const WInfoBanner(text: 'لن نحذف بياناتك أو نستبدل مفتاح التشفير. لا تحذف التطبيق قبل معرفة المشكلة.'),
          ]),
        ))));
      }
      if (!controller.ready) {
        return const Scaffold(body: Center(
          child: CircularProgressIndicator(color: WasiyyatiColors.ink)));
      }
      final pages = [
        HomeScreen(controller: controller),
        RecordsScreen(controller: controller),
        WillScreen(key: _willEditorKey, controller: controller),
        SettingsScreen(controller: controller, appLock: appLock),
      ];
      return Scaffold(
        body: pages[selected],
        bottomNavigationBar: _DocumentNavigation(
          selected: selected,
          onSelected: _switchTab,
        ),
      );
    }),
  );
}

class _DocumentNavigation extends StatelessWidget {
  const _DocumentNavigation({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'الحقوق'),
    (Icons.description_outlined, Icons.description_rounded, 'الوصية'),
    (Icons.shield_outlined, Icons.shield_rounded, 'الخزنة'),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      decoration: const BoxDecoration(
        color: WasiyyatiColors.canvas,
        border: Border(top: BorderSide(color: WasiyyatiColors.rule, width: .8)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
      child: WScreenWidth(child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(child: Semantics(
            selected: selected == i,
            button: true,
            child: Material(color: Colors.transparent,
              child: InkWell(
                key: ValueKey('nav-$i'),
                borderRadius: BorderRadius.circular(15),
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 210),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  decoration: BoxDecoration(
                    color: selected == i ? WasiyyatiColors.sage : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(selected == i ? items[i].$2 : items[i].$1,
                      size: 21,
                      color: selected == i ? WasiyyatiColors.ink : WasiyyatiColors.secondaryInk),
                    const SizedBox(height: 4),
                    Text(items[i].$3, style: TextStyle(
                      color: selected == i ? WasiyyatiColors.ink : WasiyyatiColors.secondaryInk,
                      fontSize: 11.5,
                      fontWeight: selected == i ? FontWeight.w800 : FontWeight.w500)),
                  ]),
                ),
              ),
            ),
          )),
      ])),
    ),
  );
}
