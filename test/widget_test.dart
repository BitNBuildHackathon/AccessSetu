import 'package:access_map/app/access_map_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome onboarding displays brand and capabilities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AccessMapApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AccessSetu'), findsOneWidget);
    expect(find.text('GET STARTED & EXPLORE MAP'), findsOneWidget);
    expect(find.text('Blind / Low Vision'), findsOneWidget);
  });

  testWidgets('user can complete onboarding and see map shell', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AccessMapApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    final needFinder = find.text('Blind / Low Vision');
    await tester.ensureVisible(needFinder);
    await tester.pumpAndSettle();
    await tester.tap(needFinder);
    await tester.pump();

    final ctaFinder = find.text('GET STARTED & EXPLORE MAP');
    await tester.ensureVisible(ctaFinder);
    await tester.pumpAndSettle();
    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Map'), findsWidgets);
    expect(find.text('Search accessible places...'), findsOneWidget);
  });
}
