import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/shared/user_profile_widget.dart';

void main() {
  testWidgets('compact profile shows username and invokes global actions', (
    tester,
  ) async {
    var themeToggled = false;
    var loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: UserProfileWidget(
              username: 'Administrator',
              isDark: false,
              compact: true,
              onThemeToggle: () => themeToggled = true,
              onLogout: () => loggedOut = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('global-user-profile')), findsOneWidget);
    final profileButton = tester.widget<PopupMenuButton>(
      find.byType(PopupMenuButton),
    );
    expect(profileButton.tooltip, 'Administrator');

    await tester.tap(find.byKey(const ValueKey('global-user-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Administrator'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(themeToggled, isTrue);

    await tester.tap(find.byKey(const ValueKey('global-user-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });
}
