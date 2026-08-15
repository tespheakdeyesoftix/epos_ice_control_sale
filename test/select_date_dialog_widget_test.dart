import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/shared/select_date_dialog_widget.dart';

void main() {
  testWidgets('អនុញ្ញាតថ្ងៃអនាគតមិនលើសមួយថ្ងៃ', (tester) async {
    DateTime? result;
    final today = DateTime(2026, 8, 14);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<DateTime>(
                  context: context,
                  builder: (_) => SelectDateDialogWidget(
                    initialDate: DateTime(2026, 8, 20),
                    today: today,
                  ),
                );
              },
              child: const Text('បើក'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();

    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendar.firstDate, DateTime(1900, 1, 1));
    expect(calendar.lastDate, DateTime(2026, 8, 15));
    expect(calendar.initialDate, DateTime(2026, 8, 15));
    expect(find.text('15 / 08 / 2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-posting-date')));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 8, 15));
  });
}
