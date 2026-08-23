import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/note_service.dart';

void main() {
  final baseUri = Uri.parse('http://127.0.0.1:8888/');

  test('lists a 20-note regular page for only the requested outlet', () async {
    late http.Request sent;
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        sent = request;
        return _response({
          'data': [_noteJson()],
        });
      }),
    );

    final notes = await service.listRegularForOutlet('Outlet A', offset: 20);

    expect(sent.method, 'GET');
    expect(sent.url.path, '/api/resource/Note');
    expect(jsonDecode(sent.url.queryParameters['fields']!), NoteService.fields);
    expect(jsonDecode(sent.url.queryParameters['filters']!), [
      ['custom_outlet', '=', 'Outlet A'],
      ['custom_is_pin', '=', 0],
    ]);
    expect(sent.url.queryParameters['order_by'], 'modified desc');
    expect(sent.url.queryParameters['limit_start'], '20');
    expect(sent.url.queryParameters['limit_page_length'], '20');
    expect(notes.single.name, 'NOTE-0001');
  });

  test('loads pinned notes separately with a maximum of five', () async {
    late http.Request sent;
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        sent = request;
        return _response({'data': []});
      }),
    );

    await service.listPinnedForOutlet('Outlet A');

    expect(jsonDecode(sent.url.queryParameters['filters']!), [
      ['custom_outlet', '=', 'Outlet A'],
      ['custom_is_pin', '=', 1],
    ]);
    expect(sent.url.queryParameters['limit_start'], '0');
    expect(sent.url.queryParameters['limit_page_length'], '5');
  });

  test('due query filters by outlet and exact local date', () async {
    late http.Request sent;
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        sent = request;
        return _response({'data': []});
      }),
    );

    await service.dueToday(
      outlet: 'Outlet A',
      today: DateTime(2026, 8, 21, 23, 59),
    );

    expect(jsonDecode(sent.url.queryParameters['filters']!), [
      ['custom_outlet', '=', 'Outlet A'],
      ['custom_notify_on', '=', '2026-08-21'],
    ]);
  });

  test('due count uses reportViewCount with Note filters', () async {
    late http.Request sent;
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        sent = request;
        return _response({'message': 7});
      }),
    );

    final count = await service.dueTodayCount(
      outlet: 'Outlet A',
      today: DateTime(2026, 8, 23, 18),
    );

    expect(count, 7);
    expect(sent.url.path, '/api/method/frappe.desk.reportview.get_count');
    expect(sent.url.queryParameters['doctype'], 'Note');
    expect(jsonDecode(sent.url.queryParameters['filters']!), [
      ['Note', 'custom_outlet', '=', 'Outlet A'],
      ['Note', 'custom_notify_on', '=', '2026-08-23'],
    ]);
    expect(sent.url.queryParameters['fields'], '[]');
    expect(sent.url.queryParameters['distinct'], 'false');
  });

  test(
    'create forces the supplied session outlet and encodes fields',
    () async {
      late http.Request sent;
      final service = NoteService(
        baseUri,
        client: MockClient((request) async {
          sent = request;
          return _response({'data': _noteJson()});
        }),
      );

      await service.create(
        outlet: 'Outlet A',
        title: ' Title ',
        content: '<p>Body</p>',
        color: '#FFF2B2',
        isPinned: true,
        notifyOn: DateTime(2026, 8, 21),
      );

      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/resource/Note');
      expect(body['title'], 'Title');
      expect(body['custom_outlet'], 'Outlet A');
      expect(body['custom_is_pin'], 1);
      expect(body['custom_notify_on'], '2026-08-21');
    },
  );

  test('create synchronizes tags through native Frappe add_tag RPC', () async {
    final requests = <http.Request>[];
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        requests.add(request);
        return request.url.path == '/api/resource/Note'
            ? _response({'data': _noteJson()})
            : _response({'message': 'ok'});
      }),
    );

    final saved = await service.create(
      outlet: 'Outlet A',
      title: 'Tagged note',
      content: '<p>Body</p>',
      color: '#FFFFFF',
      isPinned: false,
      tags: const ['urgent', '#Today', 'URGENT'],
    );

    expect(saved.tags, ['urgent', 'Today']);
    expect(requests.map((request) => request.url.path), [
      '/api/resource/Note',
      '/api/method/frappe.desk.doctype.tag.tag.add_tag',
      '/api/method/frappe.desk.doctype.tag.tag.add_tag',
    ]);
    expect(requests[1].bodyFields, {
      'tag': 'urgent',
      'dt': 'Note',
      'dn': 'NOTE-0001',
    });
    expect(requests[2].bodyFields['tag'], 'Today');
  });

  test('update adds and removes only changed native tags', () async {
    final requests = <http.Request>[];
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        requests.add(request);
        return request.method == 'PUT'
            ? _response({'data': _noteJson()})
            : _response({'message': 'ok'});
      }),
    );

    final saved = await service.update(
      name: 'NOTE-0001',
      title: 'Updated',
      content: '<p>Body</p>',
      color: '#FFFFFF',
      isPinned: false,
      existingTags: const ['keep', 'remove'],
      tags: const ['keep', 'add'],
    );

    expect(saved.tags, ['keep', 'add']);
    expect(requests.map((request) => request.url.path), [
      '/api/resource/Note/NOTE-0001',
      '/api/method/frappe.desk.doctype.tag.tag.remove_tag',
      '/api/method/frappe.desk.doctype.tag.tag.add_tag',
    ]);
    expect(requests[1].bodyFields['tag'], 'remove');
    expect(requests[2].bodyFields['tag'], 'add');
  });

  test('updates and deletes an encoded Note resource', () async {
    final requests = <http.Request>[];
    final service = NoteService(
      baseUri,
      client: MockClient((request) async {
        requests.add(request);
        return request.method == 'DELETE'
            ? _response({'data': 'ok'})
            : _response({'data': _noteJson(name: 'NOTE / 1')});
      }),
    );

    await service.update(
      name: 'NOTE / 1',
      title: 'Updated',
      content: '<p>Body</p>',
      color: '#FFFFFF',
      isPinned: false,
    );
    await service.delete('NOTE / 1');

    expect(requests[0].method, 'PUT');
    expect(requests[0].url.path, '/api/resource/Note/NOTE%20%2F%201');
    expect(requests[1].method, 'DELETE');
    expect(requests[1].url.path, '/api/resource/Note/NOTE%20%2F%201');
  });

  test('throws NoteServiceException for unsuccessful responses', () async {
    final service = NoteService(
      baseUri,
      client: MockClient((_) async => _response({}, statusCode: 403)),
    );

    await expectLater(
      service.listRegularForOutlet('Outlet A'),
      throwsA(
        isA<NoteServiceException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });
}

Map<String, dynamic> _noteJson({String name = 'NOTE-0001'}) => {
  'name': name,
  'title': 'Title',
  'content': '<p>Body</p>',
  'custom_color': '#FFF2B2',
  'custom_outlet': 'Outlet A',
  'custom_is_pin': 1,
  'custom_notify_on': '2026-08-21',
};

http.Response _response(Object body, {int statusCode = 200}) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
