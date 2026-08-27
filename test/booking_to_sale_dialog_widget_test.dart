import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/booking/booking.dart';
import 'package:ice_control_sale/features/booking/widgets/booking_to_sale_dialog_widget.dart';
import 'package:ice_control_sale/features/sell/product.dart';

void main() {
  testWidgets('selects available products and locks unavailable products', (
    tester,
  ) async {
    List<BookingToSaleProductSelection>? result;
    const bookingProducts = [
      BookingProduct(
        productCode: 'P-01',
        productName: 'Available Ice',
        unit: 'Bag',
        quantity: 10,
        price: 1500,
        totalAmount: 15000,
        transactionType: 'Sale',
      ),
      BookingProduct(
        productCode: 'P-02',
        productName: 'Unavailable Ice',
        unit: 'Bag',
        quantity: 20,
        price: 2000,
        totalAmount: 40000,
        transactionType: 'Sale',
      ),
    ];
    const outletProducts = [
      Product(
        code: 'P-01',
        name: 'Available Ice',
        category: 'Ice',
        unit: 'Bag',
        price: 1500,
        color: '#1677FF',
        photo: '',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showBookingToSaleProductDialog(
                  context,
                  bookingProducts: bookingProducts,
                  outletProducts: outletProducts,
                  outletName: 'Main Outlet',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final available = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('booking-to-sale-checkbox-P-01')),
    );
    final unavailable = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('booking-to-sale-checkbox-P-02')),
    );
    expect(available.value, isTrue);
    expect(available.onChanged, isNotNull);
    expect(unavailable.value, isFalse);
    expect(unavailable.onChanged, isNull);

    await tester.tap(
      find.byKey(const ValueKey('confirm-booking-to-sale-products')),
    );
    await tester.pumpAndSettle();
    expect(result, hasLength(1));
    expect(result!.single.bookingProduct.productCode, 'P-01');
  });
}
