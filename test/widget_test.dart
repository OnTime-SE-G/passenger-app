import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:passenger_app/screens/passenger_search_home_screen.dart';

void main() {
  testWidgets('Search home shows Where to', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassengerSearchHomeScreen()),
    );
    expect(find.text('Where to?'), findsOneWidget);
  });
}
