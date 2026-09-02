import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deskdash/app/theme.dart';
import 'package:deskdash/product/product_app.dart';

void main() {
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget app() => MaterialApp(theme: AppTheme.build(), home: const ProductApp());

  testWidgets('пакеты уборки открываются', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('DeskDash'), findsOneWidget);
    expect(find.text('Чистый стол 5 минут'), findsWidgets);
    expect(find.text('Начать спринт'), findsWidgets);
  });

  testWidgets('вкладки переключаются без ошибок', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Конструктор сценария'), findsWidgets);

    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    expect(find.text('История спринтов'), findsWidgets);

    await tester.tap(find.text('Опции'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsWidgets);
  });

  testWidgets('экран спринта открывается с таймером', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начать спринт').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Пауза'), findsOneWidget);
    expect(find.text('След. шаг'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('на узком экране ничего не переполняется', (tester) async {
    tester.view.physicalSize = const Size(720, 1440);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
