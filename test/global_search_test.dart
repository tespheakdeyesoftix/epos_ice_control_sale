import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/closed_sales/closed_sale.dart';
import 'package:ice_control_sale/features/global_search/global_search_controller.dart';
import 'package:ice_control_sale/features/global_search/global_search_dialog.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('loads latest 10 closed sales for the current outlet', () async {
    final service = _FakeSaleService();
    final controller = GlobalSearchController(
      saleService: service,
      outletProvider: () => 'OUTLET-2',
    );
    addTearDown(controller.dispose);

    await controller.loadInitial();

    expect(service.calls, hasLength(1));
    expect(service.calls.single.outlet, 'OUTLET-2');
    expect(service.calls.single.search, isEmpty);
    expect(service.calls.single.sortField, 'modified');
    expect(service.calls.single.sortAscending, isFalse);
    expect(service.calls.single.limit, 10);
  });

  test('debounces entered queries', () async {
    final service = _FakeSaleService();
    final controller = GlobalSearchController(
      saleService: service,
      outletProvider: () => 'OUTLET-1',
      debounceDuration: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();
    service.calls.clear();

    controller.searchController.text = 'SO-1';
    controller.handleQueryChanged('SO-1');
    controller.searchController.text = 'SO-12';
    controller.handleQueryChanged('SO-12');
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(service.calls, hasLength(1));
    expect(service.calls.single.search, 'SO-12');
    expect(service.calls.single.limit, 20);
  });

  test('ignores a stale response that finishes after a newer search', () async {
    final first = Completer<ClosedSalePage>();
    final second = Completer<ClosedSalePage>();
    final service = _FakeSaleService(
      handler: (call) => call.search.isEmpty ? first.future : second.future,
    );
    final controller = GlobalSearchController(
      saleService: service,
      outletProvider: () => 'OUTLET-1',
    );
    addTearDown(controller.dispose);

    final initialLoad = controller.loadInitial();
    controller.searchController.text = 'new';
    final newerLoad = controller.searchNow();
    second.complete(_page(_sale('SO-NEW')));
    await newerLoad;
    first.complete(_page(_sale('SO-OLD')));
    await initialLoad;

    expect(controller.results.single.name, 'SO-NEW');
  });

  testWidgets('shows recent sale cards and returns the selected invoice', (
    tester,
  ) async {
    final service = _FakeSaleService(
      handler: (_) async => _page(
        _sale(
          'SO-CLOSED-0001',
          customer: 'CUS-001',
          customerName: 'Customer A',
          driverName: 'Driver A',
          plateNumber: '2AB-1234',
          referenceNumber: 'REF-2026-001',
          quantity: 12,
        ),
      ),
    );
    ClosedSale? selected;
    var editAttempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  selected = await showGlobalSearchDialog(
                    context,
                    saleService: service,
                    outletProvider: () => 'OUTLET-1',
                    onEdit: (_) async {
                      editAttempts++;
                      return false;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('global-search-input')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('global-search-sale-SO-CLOSED-0001')),
      findsOneWidget,
    );
    expect(find.textContaining('ចំនួន 12'), findsOneWidget);
    expect(find.text('Customer A · CUS-001'), findsOneWidget);
    expect(find.text('Driver A · 2AB-1234'), findsOneWidget);
    expect(find.text('Ref: REF-2026-001'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('global-search-sale-SO-CLOSED-0001')),
          )
          .height,
      lessThan(124),
    );

    await tester.tap(
      find.byKey(const ValueKey('edit-global-search-sale-SO-CLOSED-0001')),
    );
    await tester.pumpAndSettle();
    expect(editAttempts, 1);
    expect(find.byKey(const ValueKey('global-search-dialog')), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(
      find.byKey(const ValueKey('global-search-sale-SO-CLOSED-0001')),
    );
    await tester.pumpAndSettle();
    expect(selected?.name, 'SO-CLOSED-0001');
  });
}

ClosedSale _sale(
  String name, {
  String customer = '',
  String customerName = '',
  String driverName = '',
  String plateNumber = '',
  String referenceNumber = '',
  double quantity = 1,
}) => ClosedSale(
  name: name,
  postingDate: '2026-08-21',
  customer: customer,
  customerName: customerName,
  driverName: driverName,
  plateNumber: plateNumber,
  referenceNumber: referenceNumber,
  totalSaleQuantity: quantity,
  totalAmount: 25000,
  status: 'Paid',
  modified: DateTime(2026, 8, 21, 12),
);

ClosedSalePage _page(ClosedSale sale) =>
    ClosedSalePage(items: [sale], hasMore: false);

class _SearchCall {
  const _SearchCall({
    required this.outlet,
    required this.search,
    required this.sortField,
    required this.sortAscending,
    required this.limit,
  });

  final String outlet;
  final String search;
  final String sortField;
  final bool sortAscending;
  final int limit;
}

class _FakeSaleService extends SaleService {
  _FakeSaleService({this.handler})
    : super(
        Uri.parse('http://localhost/'),
        client: MockClient((_) async => throw UnimplementedError()),
      );

  final Future<ClosedSalePage> Function(_SearchCall call)? handler;
  final calls = <_SearchCall>[];

  @override
  Future<ClosedSalePage> getClosedSales({
    required String outlet,
    String search = '',
    String startDate = '',
    String endDate = '',
    String sortField = 'posting_date',
    bool sortAscending = false,
    String customer = '',
    String driver = '',
    String status = '',
    bool splitBillOnly = false,
    String productCode = '',
    String productChildDoctype = 'Sale Product',
    int offset = 0,
    int limit = SaleService.closedSalePageSize,
  }) {
    final call = _SearchCall(
      outlet: outlet,
      search: search,
      sortField: sortField,
      sortAscending: sortAscending,
      limit: limit,
    );
    calls.add(call);
    return handler?.call(call) ??
        Future.value(const ClosedSalePage(items: [], hasMore: false));
  }
}
