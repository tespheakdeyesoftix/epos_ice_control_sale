import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/shared/receipts/receipt_template.dart';

void main() {
  test('parses Frappe template metadata and layout JSON', () {
    final template = ReceiptTemplate.fromJson({
      'name': 'Customer A5',
      'template_name': 'Customer A5',
      'paper_size': 'A5',
      'orientation': 'Landscape',
      'enabled': 1,
      'schema_version': 2,
      'layout_json': jsonEncode({
        'version': 2,
        'page': {'size': 'A4', 'orientation': 'Portrait', 'margin_mm': 12},
        'blocks': [
          {
            'id': 'title',
            'type': 'text',
            'visible': true,
            'alignment': 'center',
            'font_size': 20,
            'text': 'INVOICE',
            'position': 'absolute',
            'x_mm': 5,
            'y_mm': 8,
            'width_mm': 80,
            'height_mm': 12,
            'z_index': 2,
            'repeat': 'every_page',
            'overflow': 'shrink',
          },
        ],
      }),
    });

    expect(template.name, 'Customer A5');
    expect(template.pageSize, ReceiptPageSize.a4);
    expect(template.orientation, ReceiptOrientation.portrait);
    expect(template.marginMm, 12);
    expect(template.enabled, isTrue);
    expect(template.blocks.single.type, ReceiptBlockType.text);
    expect(template.blocks.single.fontSize, 20);
    expect(template.blocks.single.position, ReceiptPositionMode.absolute);
    expect(template.blocks.single.repeat, ReceiptPageRepeat.everyPage);
    expect(template.blocks.single.overflow, ReceiptBlockOverflow.shrink);
    expect(template.pageFormat.height, greaterThan(template.pageFormat.width));
  });

  test('serializes using the exact POS Print Template doctype', () {
    final json = ReceiptTemplate.standardA6
        .copyWith(name: '', templateName: 'Outlet A6', isBuiltIn: false)
        .toFrappeJson();

    expect(json['doctype'], 'POS Print Template');
    expect(json['template_name'], 'Outlet A6');
    expect(json['enabled'], 1);
    expect(json['layout_json'], isA<Map<String, dynamic>>());
    expect((json['layout_json'] as Map)['page'], isA<Map<String, dynamic>>());
  });

  test('migrates removed semantic block types to image and text', () {
    final template = ReceiptTemplate.fromJson({
      'name': 'Legacy',
      'template_name': 'Legacy',
      'layout_json': {
        'blocks': [
          {'id': 'logo', 'type': 'template_logo'},
          {'id': 'title', 'type': 'invoice_title'},
          {'id': 'customer', 'type': 'token_text', 'text': '{{customer_name}}'},
        ],
      },
    });

    expect(template.blocks.map((block) => block.type), [
      ReceiptBlockType.image,
      ReceiptBlockType.text,
      ReceiptBlockType.text,
    ]);
    expect(template.blocks.first.fieldname, 'template_logo');
    expect(
      (template.toLayoutJson()['blocks'] as List).map(
        (block) => (block as Map)['type'],
      ),
      ['image', 'text', 'text'],
    );
  });

  test('rejects an absolute product table and out-of-bounds blocks', () {
    final layout = ReceiptTemplate.standardA6.toLayoutJson();
    layout['blocks'] = [
      {
        'id': 'products',
        'type': 'product_table',
        'position': 'absolute',
        'x_mm': 0,
        'y_mm': 0,
        'width_mm': 90,
        'height_mm': 100,
      },
    ];

    expect(
      () => ReceiptTemplate.standardA6.applyLayoutJson(layout),
      throwsA(isA<FormatException>()),
    );
  });

  test('accepts a date block with a fieldname', () {
    final layout = ReceiptTemplate.standardA6.toLayoutJson();
    layout['blocks'] = [
      {
        'id': 'posting_date',
        'type': 'date',
        'fieldname': 'sale.posting_date',
        'show_if': 'sale.posting_date',
      },
    ];

    final template = ReceiptTemplate.standardA6.applyLayoutJson(layout);

    expect(template.blocks.single.type, ReceiptBlockType.date);
    expect(template.blocks.single.fieldname, 'sale.posting_date');
    expect(template.blocks.single.showIf, 'sale.posting_date');
  });

  test('accepts static and dynamic table top-level properties', () {
    final layout = ReceiptTemplate.standardA6.toLayoutJson();
    layout['blocks'] = [
      {
        'type': 'table',
        'border': false,
        'column_widths': [1, 2],
        'rows': [
          {
            'cells': [
              {'text': 'Invoice:'},
              {'fieldname': 'sale.name'},
            ],
          },
        ],
      },
      {
        'type': 'table',
        'source': 'sale.sale_products',
        'columns': [
          {'fieldname': 'product_name', 'label': 'Product'},
          {'fieldname': 'total_amount', 'type': 'currency'},
        ],
      },
    ];

    final template = ReceiptTemplate.standardA6.applyLayoutJson(layout);

    expect(template.blocks.map((block) => block.type), [
      ReceiptBlockType.table,
      ReceiptBlockType.table,
    ]);
    expect(template.blocks.first.properties['rows'], isA<List<dynamic>>());
    expect(template.blocks.first.properties['border'], isFalse);
    expect(template.blocks.last.properties['source'], 'sale.sale_products');
    expect(template.layoutErrors(), isEmpty);
  });

  test('rejects malformed table rows and dynamic columns', () {
    final layout = ReceiptTemplate.standardA6.toLayoutJson();
    layout['blocks'] = [
      {
        'type': 'table',
        'rows': [
          {'cells': 'not-a-list'},
        ],
      },
    ];
    expect(
      () => ReceiptTemplate.standardA6.applyLayoutJson(layout),
      throwsA(isA<FormatException>()),
    );

    layout['blocks'] = [
      {'type': 'table', 'source': 'sale.sale_products'},
    ];
    expect(
      () => ReceiptTemplate.standardA6.applyLayoutJson(layout),
      throwsA(isA<FormatException>()),
    );
  });

  test('parses and serializes recursively nested layout blocks', () {
    final layout = ReceiptTemplate.standardA6.toLayoutJson();
    layout['blocks'] = [
      {
        'id': 'header_row',
        'type': 'row',
        'gap_mm': 2,
        'margin': '0 10 10 0',
        'padding': '1 2 3 4',
        'children': [
          {
            'id': 'left_column',
            'type': 'column',
            'flex': 2,
            'child': {
              'id': 'customer',
              'type': 'text',
              'text': '{{customer_name}}',
            },
          },
          {'id': 'seller', 'type': 'text', 'text': '{{seller}}'},
        ],
      },
    ];

    final template = ReceiptTemplate.standardA6.applyLayoutJson(layout);
    final row = template.blocks.single;
    expect(row.type, ReceiptBlockType.row);
    expect(row.resolvedMargin.top, 10);
    expect(row.resolvedMargin.right, 10);
    expect(row.resolvedPadding.left, 1);
    expect(row.resolvedPadding.bottom, 4);
    expect(row.children, hasLength(2));
    expect(row.children.first.type, ReceiptBlockType.column);
    expect(row.children.first.child?.text, '{{customer_name}}');
    expect(
      ((template.toLayoutJson()['blocks'] as List).single as Map)['children'],
      isA<List<dynamic>>(),
    );
    expect(
      ((template.toLayoutJson()['blocks'] as List).single as Map)['margin'],
      '0 10 10 0',
    );
  });
}
