import 'package:access_map/app/access_map_app.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Pumps the app, flushing the 300ms mock repository delay so no
/// timers are left pending at the end of a test.
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const AccessMapApp());
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Completes onboarding (Blind / Low Vision) and enters the map.
Future<AppState> completeOnboarding(WidgetTester tester) async {
  await pumpApp(tester);

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

  return tester.element(find.byType(MaterialApp)).read<AppState>();
}

const _detailsList = ValueKey('place-details-list');
const _reviewList = ValueKey('write-review-list');

/// Drags the keyed list until [finder] finds at least one widget.
/// Tolerates multiple matches (unlike dragUntilVisible's .single check).
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  Key listKey,
) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byKey(listKey), const Offset(0, -250));
    await tester.pump();
  }
  await tester.pumpAndSettle();
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('welcome onboarding shows brand, core capabilities, and open map CTA', (tester) async {
    await pumpApp(tester);

    expect(find.text('AccessSetu'), findsOneWidget);
    expect(find.text('GET STARTED & EXPLORE MAP'), findsOneWidget);
    expect(find.text('Accessible Discovery & Navigation'), findsOneWidget);
  });

  testWidgets('welcome onboarding shows accessibility focus options', (tester) async {
    await pumpApp(tester);

    for (final need in AccessibilityNeed.values) {
      expect(find.text(need.displayName), findsOneWidget);
    }
  });

  testWidgets('need persists into profile after onboarding', (tester) async {
    final state = await completeOnboarding(tester);

    expect(state.profile.onboardingComplete, isTrue);
    expect(state.profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision), isTrue);
  });

  testWidgets('map shell shows places, search and tabs after onboarding', (tester) async {
    await completeOnboarding(tester);

    expect(find.text('Search accessible places...'), findsOneWidget);
    expect(find.text('Map'), findsWidgets);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('wheelchair score hidden for visual profile, shown after profile change', (tester) async {
    await completeOnboarding(tester);

    // Switch to Discover tab to browse places
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    // Open the first place details.
    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();

    expect(find.text('Friendly Score'), findsOneWidget);
    expect(find.text('Wheelchair-Friendly'), findsNothing);

    // Go back to the shell, open Profile via the nav bar, add a
    // wheelchair need.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await scrollUntilVisible(
      tester,
      find.text('Wheelchair / Mobility'),
      const ValueKey('profile-list'),
    );
    await tester.tap(find.text('Wheelchair / Mobility'));
    await tester.pumpAndSettle();

    final state = tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(state.profile.shouldShowWheelchairScore, isTrue);
  });

  testWidgets('search finds a place and opens its details', (tester) async {
    await completeOnboarding(tester);

    await tester.enterText(find.byType(TextField).first, 'fishka');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();

    expect(find.text('Friendly Score'), findsOneWidget);
    expect(find.text('Accessibility overview'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    await scrollUntilVisible(tester, find.text('Accessibility features'), _detailsList);
    expect(find.text('Accessibility features'), findsOneWidget);
    await scrollUntilVisible(tester, find.text('Reviews'), _detailsList);
    expect(find.text('Reviews'), findsOneWidget);
  });

  testWidgets('review submission awards +5 community points', (tester) async {
    final state = await completeOnboarding(tester);
    final pointsBefore = state.profile.communityPoints;

    // Switch to Discover tab and open place details
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();
    await scrollUntilVisible(tester, find.text('Write'), _detailsList);
    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();

    // The comment field sits below the rating sliders, so scroll to it.
    await scrollUntilVisible(tester, find.byType(TextField), _reviewList);
    await tester.enterText(
      find.byType(TextField),
      'Staff guided me patiently and the entrance was step-free throughout.',
    );
    await tester.pump();
    await scrollUntilVisible(tester, find.text('Submit Review'), _reviewList);
    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final stateAfter =
        tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(stateAfter.profile.communityPoints, pointsBefore + 5);
    expect(stateAfter.profile.reviewCount, greaterThan(0));
    expect(stateAfter.profile.recentActivity.first.type.displayName, 'Review');
  });

  testWidgets('helpful vote works from details', (tester) async {
    await completeOnboarding(tester);

    // Switch to Discover tab
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();
    await scrollUntilVisible(tester, find.textContaining('Helpful'), _detailsList);
    await tester.drag(find.byKey(_detailsList), const Offset(0, -250));
    await tester.pumpAndSettle();

    final placeBefore = tester
        .element(find.byType(MaterialApp))
        .read<AppState>()
        .places
        .firstWhere((p) => p.name == 'Fishka Restaurant');
    final votesBefore = placeBefore.reviews.first.helpfulVotes;

    await tester.tap(find.textContaining('Helpful').first);
    await tester.pumpAndSettle();

    final state = tester.element(find.byType(MaterialApp)).read<AppState>();
    final placeAfter = state.places.firstWhere((p) => p.name == 'Fishka Restaurant');
    expect(
      placeAfter.reviews.first.helpfulVotes,
      votesBefore + 1,
    );
  });

  testWidgets('feature confirmation awards +3 points', (tester) async {
    final state = await completeOnboarding(tester);

    // Switch to Discover tab
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();

    final pointsBefore = state.profile.communityPoints;
    await scrollUntilVisible(tester, find.text('Confirm'), _detailsList);
    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();

    final stateAfter =
        tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(stateAfter.profile.communityPoints, pointsBefore + 3);
    expect(
      stateAfter.profile.recentActivity.first.description,
      contains('Confirmed'),
    );
  });
}
