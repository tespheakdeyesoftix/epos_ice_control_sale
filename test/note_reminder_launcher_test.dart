import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/notes/note_reminder_launcher.dart';
import 'package:ice_control_sale/services/note_service.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('shows all due-today notes once for the shell lifetime', (
    tester,
  ) async {
    var calls = 0;
    final service = NoteService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: MockClient((request) async {
        calls++;
        final filters = jsonDecode(request.url.queryParameters['filters']!);
        expect(filters, [
          ['custom_outlet', '=', 'Outlet A'],
          ['custom_notify_on', '=', '2026-08-21'],
        ]);
        return _response({
          'data': [
            _note('NOTE-1', 'First reminder'),
            _note('NOTE-2', 'Second reminder'),
          ],
        });
      }),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: NoteReminderLauncher(
            service: service,
            outlet: 'Outlet A',
            today: DateTime(2026, 8, 21),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.byKey(const ValueKey('due-note-dialog')), findsOneWidget);
    expect(find.text('First reminder'), findsOneWidget);
    expect(find.text('Second reminder'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dismiss-due-notes')));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('reminder request failure does not replace the app', (
    tester,
  ) async {
    final service = NoteService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: MockClient((_) async => _response({}, statusCode: 500)),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Text('Authenticated app'),
              NoteReminderLauncher(
                service: service,
                outlet: 'Outlet A',
                today: DateTime(2026, 8, 21),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Authenticated app'), findsOneWidget);
    expect(
      find.text('មិនអាចពិនិត្យការជូនដំណឹងកំណត់ចំណាំបានទេ។'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('due-note-dialog')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

Map<String, dynamic> _note(String name, String title) => {
  'name': name,
  'title': title,
  'content': '<p>Reminder body</p>',
  'custom_color': '#FFF2B2',
  'custom_outlet': 'Outlet A',
  'custom_notify_on': '2026-08-21',
};

http.Response _response(Object body, {int statusCode = 200}) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
