import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/shared/welcome_card_widget.dart';

void main() {
  testWidgets('shows Khmer greeting and workplace information', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WelcomeCardWidget(
      userName: 'សុខ ដារ៉ា', outletName: 'សាខាទី១', stationName: 'Cashier 01', now: DateTime(2026, 8, 20, 9),
    ))));
    expect(find.textContaining('អរុណសួស្តី'), findsOneWidget);
    expect(find.text('សុខ ដារ៉ា'), findsOneWidget);
    expect(find.text('សាខាទី១'), findsOneWidget);
    expect(find.text('Cashier 01'), findsOneWidget);
  });

  testWidgets('uses afternoon and evening Khmer greetings', (tester) async {
    Future<void> pumpAt(int hour) => tester.pumpWidget(MaterialApp(home: WelcomeCardWidget(
      userName: 'User', outletName: 'Outlet', stationName: 'Station', now: DateTime(2026, 8, 20, hour),
    )));
    await pumpAt(14);
    expect(find.textContaining('ទិវាសួស្តី'), findsOneWidget);
    await pumpAt(20);
    expect(find.textContaining('សាយណ្ហសួស្តី'), findsOneWidget);
  });

  testWidgets('shows business information and logo when user has no photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeCardWidget(
          userName: 'User',
          outletName: 'Outlet',
          stationName: 'Station',
          businessNameKh: 'រោងចក្រទឹកកក',
          businessNameEn: 'Ice Factory',
          businessAddress: 'Phnom Penh',
          businessPhone: '012 345 678',
          businessLogoUrl: 'https://example.com/logo.png',
          now: DateTime(2026, 8, 20, 9),
        ),
      ),
    );

    expect(find.text('រោងចក្រទឹកកក'), findsOneWidget);
    expect(find.text('Ice Factory'), findsOneWidget);
    expect(find.text('Phnom Penh'), findsOneWidget);
    expect(find.text('012 345 678'), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-business-logo')), findsOneWidget);
  });
}
