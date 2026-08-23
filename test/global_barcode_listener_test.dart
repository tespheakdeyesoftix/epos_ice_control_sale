import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/global_search/global_barcode_listener.dart';

void main() {
  test('returns a fast scanner sequence when Enter is submitted', () {
    final buffer = BarcodeScanBuffer();
    final start = DateTime(2026, 8, 23, 10);

    for (var index = 0; index < 'SO-001'.length; index++) {
      buffer.addCharacter(
        'SO-001'[index],
        at: start.add(Duration(milliseconds: index * 20)),
      );
    }

    expect(
      buffer.submit(at: start.add(const Duration(milliseconds: 130))),
      'SO-001',
    );
  });

  test('ignores normal typing with a long gap between characters', () {
    final buffer = BarcodeScanBuffer();
    final start = DateTime(2026, 8, 23, 10);
    buffer.addCharacter('S', at: start);
    buffer.addCharacter('O', at: start.add(const Duration(milliseconds: 250)));
    buffer.addCharacter('1', at: start.add(const Duration(milliseconds: 270)));

    expect(
      buffer.submit(at: start.add(const Duration(milliseconds: 290))),
      isNull,
    );
  });
}
