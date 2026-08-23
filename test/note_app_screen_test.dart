import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/features/notes/note_app_screen.dart';
import 'package:ice_control_sale/features/notes/note_controller.dart';
import 'package:ice_control_sale/services/note_service.dart';

void main() {
  testWidgets('shows pinned and regular note cards and validates title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    var listCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_count')) {
        return _response({'message': 0});
      }
      if (request.method == 'GET') {
        listCalls++;
        final filters = request.url.queryParameters['filters'] ?? '';
        final isPinnedRequest =
            filters.contains('custom_is_pin') && filters.contains(',1]');
        return _response({
          'data': isPinnedRequest
              ? [
                  _note(
                    'PIN-1',
                    pinned: true,
                    title: 'Pinned note',
                    content:
                        'Line one with a long reminder. Line two has more details. '
                        'Line three continues the note. Line four must be hidden. '
                        'Line five is visible only after expanding the card.',
                  ),
                ]
              : [
                  _note('NOTE-1', title: 'Regular note', tags: const ['work']),
                ],
        });
      }
      return _response({'data': _note('NEW-1', title: 'New note')});
    });
    final outlet = SessionOutletController(configuredOutlet: 'Outlet A');
    Get.put<SessionOutletController>(outlet);
    Get.put<NoteController>(
      NoteController(
        service: NoteService(
          Uri.parse('http://127.0.0.1:8888/'),
          client: client,
        ),
        outletController: outlet,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        home: const NoteAppScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(listCalls, 2);
    expect(find.byKey(const ValueKey('note-card-PIN-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-card-NOTE-1')), findsOneWidget);
    expect(find.text('#work'), findsOneWidget);
    expect(find.text('បានខ្ទាស់'), findsOneWidget);
    expect(find.text('កំណត់ចំណាំទាំងអស់'), findsOneWidget);
    final longContent = find.textContaining('Line one with a long reminder');
    expect(tester.widget<Text>(longContent).maxLines, 3);
    expect(
      tester.getSize(find.byKey(const ValueKey('note-card-PIN-1'))).height,
      lessThan(224),
    );
    final collapsedHeight = tester
        .getSize(find.byKey(const ValueKey('note-card-PIN-1')))
        .height;
    expect(find.text('អានបន្ថែម'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('read-more-note-PIN-1')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(longContent).maxLines, isNull);
    expect(find.text('បង្ហាញតិច'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('note-card-PIN-1'))).height,
      greaterThan(collapsedHeight),
    );

    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-editor-dialog')), findsOneWidget);
    expect(find.byType(QuillSimpleToolbar), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('note-tag-input')),
      'urgent, #Today',
    );
    await tester.tap(find.byKey(const ValueKey('add-note-tag')));
    await tester.pump();
    expect(find.text('#urgent'), findsOneWidget);
    expect(find.text('#Today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pump();
    expect(find.text('សូមបញ្ចូលចំណងជើង។'), findsOneWidget);
  });

  testWidgets('outlet change reloads notes with the new outlet filter', (
    tester,
  ) async {
    addTearDown(Get.reset);
    final requestedOutlets = <String>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_count')) {
        return _response({'message': 0});
      }
      final filters =
          jsonDecode(request.url.queryParameters['filters']!) as List;
      requestedOutlets.add((filters.first as List).last.toString());
      return _response({'data': []});
    });
    final outlet = SessionOutletController(configuredOutlet: 'Outlet A');
    Get.put<SessionOutletController>(outlet);
    Get.put<NoteController>(
      NoteController(
        service: NoteService(
          Uri.parse('http://127.0.0.1:8888/'),
          client: client,
        ),
        outletController: outlet,
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: NoteAppScreen()));
    await tester.pumpAndSettle();

    outlet.commitOutlet('Outlet B');
    await tester.pumpAndSettle();

    expect(requestedOutlets, ['Outlet A', 'Outlet A', 'Outlet B', 'Outlet B']);
  });

  testWidgets('search applies after a 1.5 second debounce', (tester) async {
    addTearDown(Get.reset);
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_count')) {
        return _response({'message': 0});
      }
      final filters = request.url.queryParameters['filters'] ?? '';
      if (filters.contains('custom_is_pin') && filters.contains(',1]')) {
        return _response({'data': []});
      }
      return _response({
        'data': [
          _note('MATCH', title: 'Apple note', tags: const ['urgent']),
          _note('OTHER', title: 'Banana note'),
        ],
      });
    });
    final outlet = SessionOutletController(configuredOutlet: 'Outlet A');
    Get.put<SessionOutletController>(outlet);
    Get.put<NoteController>(
      NoteController(
        service: NoteService(
          Uri.parse('http://127.0.0.1:8888/'),
          client: client,
        ),
        outletController: outlet,
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: NoteAppScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note-search-input')),
      'urgent',
    );
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byKey(const ValueKey('note-card-OTHER')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('note-card-MATCH')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-card-OTHER')), findsNothing);
  });

  testWidgets('loads the next 20-note page near the scroll bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    final requestedOffsets = <int>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_count')) {
        return _response({'message': 0});
      }
      final filters = request.url.queryParameters['filters'] ?? '';
      if (filters.contains('custom_is_pin') && filters.contains(',1]')) {
        return _response({'data': []});
      }
      final offset = int.parse(request.url.queryParameters['limit_start']!);
      requestedOffsets.add(offset);
      return _response({
        'data': offset == 0
            ? [
                for (var index = 0; index < 20; index++)
                  _note('REG-$index', title: 'Regular note $index'),
              ]
            : [
                _note('REG-20', title: 'Regular note 20'),
                _note('REG-21', title: 'Regular note 21'),
                _note('REG-22', title: 'Regular note 22'),
              ],
      });
    });
    final outlet = SessionOutletController(configuredOutlet: 'Outlet A');
    Get.put<SessionOutletController>(outlet);
    Get.put<NoteController>(
      NoteController(
        service: NoteService(
          Uri.parse('http://127.0.0.1:8888/'),
          client: client,
        ),
        outletController: outlet,
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: NoteAppScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-card-REG-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-card-REG-20')), findsNothing);

    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, -3000),
      1500,
    );
    await tester.pumpAndSettle();

    expect(requestedOffsets, [0, 20]);
    expect(find.byKey(const ValueKey('note-card-REG-20')), findsOneWidget);
    expect(Get.find<NoteController>().hasMoreRegularNotes.value, isFalse);
  });

  testWidgets('blocks a sixth pinned note before calling the API', (
    tester,
  ) async {
    addTearDown(Get.reset);
    var updateCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_count')) {
        return _response({'message': 0});
      }
      if (request.method == 'PUT') {
        updateCalls++;
        return _response({
          'data': _note('REG-1', title: 'Regular', pinned: true),
        });
      }
      final filters = request.url.queryParameters['filters'] ?? '';
      if (filters.contains('custom_is_pin') && filters.contains(',1]')) {
        return _response({
          'data': [
            for (var index = 0; index < 5; index++)
              _note('PIN-$index', title: 'Pinned $index', pinned: true),
          ],
        });
      }
      return _response({
        'data': [_note('REG-1', title: 'Regular')],
      });
    });
    final outlet = SessionOutletController(configuredOutlet: 'Outlet A');
    Get.put<SessionOutletController>(outlet);
    final controller = Get.put<NoteController>(
      NoteController(
        service: NoteService(
          Uri.parse('http://127.0.0.1:8888/'),
          client: client,
        ),
        outletController: outlet,
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: NoteAppScreen()));
    await tester.pumpAndSettle();

    final success = await controller.togglePinned(controller.notes.single);

    expect(success, isFalse);
    expect(controller.lastMutationError.value, NoteController.pinLimitMessage);
    expect(updateCalls, 0);
    expect(controller.pinnedNotes, hasLength(5));
  });
}

Map<String, dynamic> _note(
  String name, {
  required String title,
  bool pinned = false,
  String content = 'Body text',
  List<String> tags = const [],
}) => {
  'name': name,
  'title': title,
  'content': '<p>$content</p>',
  'custom_color': '#FFF2B2',
  'custom_outlet': 'Outlet A',
  'custom_is_pin': pinned ? 1 : 0,
  '_user_tags': tags.join(','),
  'modified': '2026-08-21 10:30:00',
};

http.Response _response(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
