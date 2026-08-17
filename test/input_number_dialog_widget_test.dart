import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/shared/input_number_dialog_widget.dart';

void main() {
  testWidgets('first keypad press replaces the initial value', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: InputNumberDialogWidget(initialValue: 12.5)),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('quantity-input')),
        matching: find.text('12.5'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('number-key-3')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('quantity-input')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('number-key-4')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('quantity-input')),
        matching: find.text('34'),
      ),
      findsOneWidget,
    );
  });
}
