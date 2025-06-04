// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:chrono_history/main.dart';

void main() {
  testWidgets('ChronoHistory app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChronoHistoryApp());

    // Verify that our app loads with the correct title.
    expect(find.text('ChronoHistory'), findsOneWidget);
    
    // We should see some indication that no timelines are selected initially
    expect(find.text('No timelines selected'), findsOneWidget);
  });
}
