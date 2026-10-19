import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/main.dart';
import 'package:wasiyyati/screens/home_screen.dart';
import 'package:wasiyyati/services/encrypted_vault.dart';
import 'package:wasiyyati/services/vault_controller.dart';
import 'package:wasiyyati/theme/wasiyyati_theme.dart';
import 'package:wasiyyati/widgets/common.dart';

void main() {
  testWidgets('home occupies the screen and document navigation stays at bottom',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = VaultController(EncryptedVault());
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      theme: buildWasiyyatiTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: HomeScreen(controller: controller),
          bottomNavigationBar: DocumentNavigation(
            selected: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('home-scroll')), findsOneWidget);
    expect(find.text('وصيتي'), findsOneWidget);
    expect(find.text('السلام عليكم'), findsOneWidget);

    final nav = tester.getRect(find.byKey(const Key('document-navigation')));
    expect(nav.height, lessThan(130));
    expect(nav.top, greaterThan(550));
    expect(nav.bottom, closeTo(740, 1));
    expect(tester.getTopLeft(find.text('السلام عليكم')).dy,
      lessThan(nav.top));
  });

  testWidgets('regular width wrapper still gives scrollable pages full height',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WScreenWidth(
          child: ListView(children: const [Text('scroll-body')]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final listSize = tester.getSize(find.byType(ListView));
    expect(listSize.height, greaterThan(350));
  });
}
