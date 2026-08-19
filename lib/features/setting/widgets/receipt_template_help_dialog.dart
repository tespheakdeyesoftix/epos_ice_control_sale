import 'package:flutter/material.dart';

class ReceiptTemplateHelpDialog extends StatelessWidget {
  const ReceiptTemplateHelpDialog({super.key});

  static const sampleReceipt = '''{
  "version": 1,
  "page": {
    "size": "A6",
    "orientation": "Portrait",
    "margin_mm": 5
  },
  "blocks": [
    {
      "type": "image",
      "fieldname": "print_template.template_logo",
      "position": "absolute",
      "x_mm": 0,
      "y_mm": 0,
      "width_mm": 25,
      "height_mm": 18,
      "overflow": "shrink"
    },
    {
      "type": "text",
      "text": "{{setting.business_name_kh}}\n{{setting.business_name_en}}",
      "alignment": "center",
      "font_size": 15,
      "bold": true,
      "margin": "25 0 0 0",
      "spacing_after": 2
    },
    {
      "type": "text",
      "text": "វិក្កយបត្រ",
      "alignment": "center",
      "font_size": 18,
      "bold": true
    },
    {
      "type": "row",
      "gap_mm": 3,
      "children": [
        {
          "type": "text",
          "text": "{{setting.address}}\n{{setting.phone_number_1}}",
          "flex": 1,
          "spacing_after": 0
        },
        {
          "type": "column",
          "flex": 1,
          "gap_mm": 1,
          "children": [
            {
              "type": "row",
              "gap_mm": 2,
              "spacing_after": 0,
              "children": [
                {"type": "text", "text": "Invoice:", "bold": true, "spacing_after": 0},
                {"type": "text", "fieldname": "sale.name", "spacing_after": 0}
              ]
            },
            {
              "type": "row",
              "gap_mm": 2,
              "spacing_after": 0,
              "children": [
                {"type": "text", "text": "Date:", "bold": true, "spacing_after": 0},
                {"type": "date", "fieldname": "sale.posting_date", "spacing_after": 0}
              ]
            }
          ]
        }
      ]
    },
    {
      "type": "text",
      "fieldname": "sale.customer_name",
      "label": "Customer: ",
      "show_if": "sale.customer_name",
      "bold": true
    },
    {
      "type": "product_table",
      "properties": {
        "columns": [
          {"key": "index", "label": "No.", "width": 0.5, "alignment": "center"},
          {"key": "product_name", "label": "Product", "width": 2.5},
          {"key": "quantity", "label": "Qty", "width": 1, "alignment": "center"},
          {"key": "amount", "label": "Amount", "width": 1.3, "alignment": "right"}
        ]
      }
    },
    {
      "type": "row",
      "gap_mm": 4,
      "children": [
        {
          "type": "column",
          "gap_mm": 2,
          "children": [
            {"type": "barcode", "height_mm": 10, "spacing_after": 0},
            {"type": "notes", "spacing_after": 0}
          ]
        },
        {"type": "totals", "alignment": "right", "spacing_after": 0}
      ]
    }
  ]
}''';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(24),
      title: const Text('Receipt layout JSON reference'),
      content: SizedBox(
        width: 920,
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: ListView(
          children: [
            const Text(
              'The receipt format is declarative JSON. It does not execute Flutter or Dart code. Dimensions ending in _mm use millimetres. Absolute coordinates start at the top-left of the printable area, inside page.margin_mm.',
            ),
            const SizedBox(height: 8),
            const _HelpSection(
              title: 'Page properties',
              initiallyExpanded: true,
              child: _ReferenceTable(
                rows: [
                  _ReferenceRow(
                    'version',
                    'Integer; default 1',
                    'Layout schema version.',
                  ),
                  _ReferenceRow(
                    'page.size',
                    'A6, A5, A4',
                    'Paper size. The POS Print Template paper_size field is the fallback.',
                  ),
                  _ReferenceRow(
                    'page.orientation',
                    'Portrait, Landscape',
                    'Paper orientation. The template document value is the fallback.',
                  ),
                  _ReferenceRow(
                    'page.margin_mm',
                    'Number >= 0',
                    'Equal printable margin on all four page edges.',
                  ),
                  _ReferenceRow(
                    'blocks',
                    'Non-empty array',
                    'Top-level receipt blocks in flow/paint order.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Properties available on every block',
              initiallyExpanded: true,
              child: _ReferenceTable(
                rows: [
                  _ReferenceRow(
                    'type',
                    'Required',
                    'Widget type. See the complete type list below.',
                  ),
                  _ReferenceRow(
                    'id',
                    'Optional string',
                    'Stable developer identifier. One is generated when omitted.',
                  ),
                  _ReferenceRow(
                    'visible',
                    'true | false; default true',
                    'Static visibility.',
                  ),
                  _ReferenceRow(
                    'show_if',
                    'Field path',
                    'Shows the complete block only when the field is non-empty/truthy. Prefix with ! to invert.',
                  ),
                  _ReferenceRow(
                    'alignment',
                    'left | center | right; default left',
                    'Horizontal alignment of supported content.',
                  ),
                  _ReferenceRow(
                    'font_size',
                    'Number; default 9',
                    'Text size in PDF points.',
                  ),
                  _ReferenceRow(
                    'bold',
                    'true | false; default false',
                    'Uses bold text when supported.',
                  ),
                  _ReferenceRow(
                    'position',
                    'flow | absolute; default flow',
                    'Flow follows previous content. Absolute uses fixed printable-area coordinates.',
                  ),
                  _ReferenceRow(
                    'x_mm, y_mm',
                    'Numbers >= 0',
                    'Required for top-level absolute blocks.',
                  ),
                  _ReferenceRow(
                    'width_mm, height_mm',
                    'Numbers > 0',
                    'Required for absolute blocks; optional for supported flow blocks.',
                  ),
                  _ReferenceRow(
                    'z_index',
                    'Integer; default 0',
                    'Paint order among overlapping absolute blocks. Larger values paint later.',
                  ),
                  _ReferenceRow(
                    'repeat',
                    'first_page | every_page | last_page',
                    'Absolute-block page visibility; default first_page.',
                  ),
                  _ReferenceRow(
                    'overflow',
                    'clip | shrink | wrap',
                    'Absolute-block overflow behavior; default clip.',
                  ),
                  _ReferenceRow(
                    'flex',
                    'Number > 0; default 1',
                    'Relative width when this block is a row child.',
                  ),
                  _ReferenceRow(
                    'gap_mm',
                    'Number >= 0',
                    'Space between row/column children. Also controls signature-line gaps.',
                  ),
                  _ReferenceRow(
                    'margin',
                    '"left top right bottom"',
                    'External spacing in millimetres. A single value applies to all sides.',
                  ),
                  _ReferenceRow(
                    'padding',
                    '"left top right bottom"',
                    'Internal spacing in millimetres. A single value applies to all sides.',
                  ),
                  _ReferenceRow(
                    'padding_mm',
                    'Number >= 0',
                    'Legacy equal padding shorthand. padding takes precedence.',
                  ),
                  _ReferenceRow(
                    'spacing_before',
                    'Number; default 0',
                    'Extra vertical spacing before the block in PDF points.',
                  ),
                  _ReferenceRow(
                    'spacing_after',
                    'Number; default 4',
                    'Extra vertical spacing after the block in PDF points.',
                  ),
                  _ReferenceRow(
                    'fieldname',
                    'Field path',
                    'Data source for image, text, or date.',
                  ),
                  _ReferenceRow(
                    'label',
                    'String',
                    'Prefix placed before a resolved text/date value.',
                  ),
                  _ReferenceRow(
                    'text',
                    'String with optional {{tokens}}',
                    'Static or token-formatted text.',
                  ),
                  _ReferenceRow(
                    'properties',
                    'JSON object',
                    'Type-specific configuration such as fields or product columns.',
                  ),
                  _ReferenceRow(
                    'child',
                    'Block object',
                    'One recursively nested block for row, column, or container.',
                  ),
                  _ReferenceRow(
                    'children',
                    'Block array',
                    'Recursively nested blocks; maximum nesting depth is 12.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'All supported block types',
              initiallyExpanded: true,
              child: _ReferenceTable(
                rows: [
                  _ReferenceRow(
                    'row',
                    'child / children, flex, gap_mm, padding',
                    'Places visible children horizontally. Child flex values divide available width.',
                  ),
                  _ReferenceRow(
                    'column',
                    'child / children, gap_mm, padding',
                    'Places visible children vertically.',
                  ),
                  _ReferenceRow(
                    'container',
                    'child / children, padding, width_mm, height_mm',
                    'Sizes, pads, and groups one or more nested blocks.',
                  ),
                  _ReferenceRow(
                    'image',
                    'fieldname required',
                    'Loads an image path from sale, setting, or print_template. width_mm/height_mm default to 30/20.',
                  ),
                  _ReferenceRow(
                    'text',
                    'fieldname or text required',
                    'Renders a resolved field, optional label, or a string containing tokens.',
                  ),
                  _ReferenceRow(
                    'date',
                    'fieldname required',
                    'Parses an ISO date and displays dd/MM/yyyy; otherwise displays the original value.',
                  ),
                  _ReferenceRow(
                    'customer_info',
                    'properties.fields',
                    'Legacy combined customer block. fields values: customer, phone.',
                  ),
                  _ReferenceRow(
                    'table',
                    'rows, or source + columns',
                    'Generic static or dynamic table. A dynamic table must be a top-level flow block.',
                  ),
                  _ReferenceRow(
                    'product_table',
                    'properties.columns',
                    'Backward-compatible specialized Sale Product table. New templates may use table with source sale.sale_products.',
                  ),
                  _ReferenceRow(
                    'totals',
                    'width_mm, alignment',
                    'Two-column total quantity/amount table. Amount uses setting.currency_symbol.',
                  ),
                  _ReferenceRow(
                    'barcode',
                    'width_mm, height_mm',
                    'Code 128 barcode using sale.name, with invoice number underneath.',
                  ),
                  _ReferenceRow(
                    'notes',
                    'properties.fields',
                    'Reference and note output. fields values: reference_number, note.',
                  ),
                  _ReferenceRow(
                    'signatures',
                    'properties.fields, gap_mm',
                    'Legacy signature renderer. fields values: seller, driver, customer. Generic row/column/text is preferred for full control.',
                  ),
                  _ReferenceRow(
                    'divider',
                    'No required value',
                    'Thin horizontal rule.',
                  ),
                  _ReferenceRow(
                    'spacer',
                    'height_mm',
                    'Empty vertical space; falls back to spacing_after when height_mm is omitted.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Available data objects',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReferenceTable(
                    rows: [
                      _ReferenceRow(
                        'sale.<field>',
                        'Sale / invoice',
                        'Available in text, date, image, show_if, and {{tokens}}.',
                      ),
                      _ReferenceRow(
                        'setting.<field>',
                        'Get Setting API',
                        'Includes every key returned by get_setting, plus the documented aliases below.',
                      ),
                      _ReferenceRow(
                        'print_template.<field>',
                        'POS Print Template',
                        'Includes every field returned for the selected template. template.<field> is an alias.',
                      ),
                      _ReferenceRow(
                        'sale_product key',
                        'Sale Products row',
                        'Available only as key inside product_table properties.columns.',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use an explicit prefix to avoid name conflicts. A plain field name searches sale, then setting, then print_template.',
                  ),
                  SizedBox(height: 6),
                  SelectableText(
                    '{{sale.customer_name}}\n{{setting.business_name_en}}\n{{print_template.template_name}}',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  SizedBox(height: 8),
                  SelectableText(
                    'Token example: "Customer: {{sale.customer_name}} - {{sale.phone_number}}"',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'show_if accepts one field, for example "sale.driver_name". Prefix it with ! to show when empty/false: "!sale.driver_name".',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Sale object: all fields',
              child: _ReferenceTable(
                rows: [
                  _ReferenceRow(
                    'sale.name',
                    'Text',
                    'Invoice/document number.',
                  ),
                  _ReferenceRow(
                    'sale.invoice_number',
                    'Text',
                    'Alias of sale.name.',
                  ),
                  _ReferenceRow(
                    'sale.doctype',
                    'Text',
                    'Document type; normally Sale.',
                  ),
                  _ReferenceRow(
                    'sale.naming_series',
                    'Text',
                    'Numbering series.',
                  ),
                  _ReferenceRow(
                    'sale.posting_date',
                    'Date',
                    'Posting date. Use type=date for friendly formatting.',
                  ),
                  _ReferenceRow(
                    'sale.reference_number',
                    'Text',
                    'External/reference number.',
                  ),
                  _ReferenceRow('sale.outlet', 'Text', 'Outlet.'),
                  _ReferenceRow(
                    'sale.stock_location',
                    'Text',
                    'Stock location.',
                  ),
                  _ReferenceRow(
                    'sale.seller',
                    'Text',
                    'Seller/cashier. The print-flow seller is used as fallback.',
                  ),
                  _ReferenceRow('sale.customer', 'Text', 'Customer ID/code.'),
                  _ReferenceRow(
                    'sale.customer_name',
                    'Text',
                    'Customer display name.',
                  ),
                  _ReferenceRow(
                    'sale.phone_number',
                    'Text',
                    'Customer phone number.',
                  ),
                  _ReferenceRow(
                    'sale.customer_group',
                    'Text',
                    'Customer group.',
                  ),
                  _ReferenceRow(
                    'sale.customer_photo',
                    'Image path',
                    'Customer image path.',
                  ),
                  _ReferenceRow(
                    'sale.can_show_price',
                    '0 or 1',
                    'Whether prices may be printed.',
                  ),
                  _ReferenceRow(
                    'sale.can_split_bill',
                    '0 or 1',
                    'Whether bill splitting is allowed.',
                  ),
                  _ReferenceRow(
                    'sale.can_edit_bill',
                    '0 or 1',
                    'Whether bill editing is allowed.',
                  ),
                  _ReferenceRow('sale.driver', 'Text', 'Driver ID/code.'),
                  _ReferenceRow(
                    'sale.driver_name',
                    'Text',
                    'Driver display name; useful with show_if.',
                  ),
                  _ReferenceRow(
                    'sale.driver_phone_number',
                    'Text',
                    'Driver phone number.',
                  ),
                  _ReferenceRow(
                    'sale.plate_number',
                    'Text',
                    'Vehicle plate number.',
                  ),
                  _ReferenceRow(
                    'sale.driver_photo',
                    'Image path',
                    'Driver image path.',
                  ),
                  _ReferenceRow(
                    'sale.sale_status',
                    'Text',
                    'Sale workflow status.',
                  ),
                  _ReferenceRow(
                    'sale.parent_bill_number',
                    'Text',
                    'Parent bill number for a related/split bill.',
                  ),
                  _ReferenceRow(
                    'sale.sale_products',
                    'List',
                    'Product rows. Render with product_table; do not use directly as text.',
                  ),
                  _ReferenceRow('sale.note', 'Text', 'Sale note.'),
                  _ReferenceRow(
                    'sale.total_quantity',
                    'Number',
                    'Printable total sale quantity; alias of total_sale_quantity.',
                  ),
                  _ReferenceRow(
                    'sale.total_free',
                    'Number',
                    'Total free quantity.',
                  ),
                  _ReferenceRow(
                    'sale.total_quantity_return',
                    'Number',
                    'Total returned quantity.',
                  ),
                  _ReferenceRow(
                    'sale.total_split_quantity',
                    'Number',
                    'Total split quantity.',
                  ),
                  _ReferenceRow(
                    'sale.total_sale_quantity',
                    'Number',
                    'Net sale quantity.',
                  ),
                  _ReferenceRow(
                    'sale.total_payment',
                    'Number',
                    'Total payment received.',
                  ),
                  _ReferenceRow(
                    'sale.total_amount',
                    'Number',
                    'Invoice total amount.',
                  ),
                  _ReferenceRow(
                    'sale.total_write_off',
                    'Number',
                    'Write-off amount.',
                  ),
                  _ReferenceRow(
                    'sale.total_split_bill',
                    'Number',
                    'Number/value recorded for split bills.',
                  ),
                  _ReferenceRow(
                    'sale.balance',
                    'Number',
                    'total_amount - total_payment - total_write_off.',
                  ),
                  _ReferenceRow(
                    'sale.status',
                    'Text',
                    'Payment/document status.',
                  ),
                  _ReferenceRow(
                    'sale.id',
                    'Text',
                    'Local/backend ID when supplied.',
                  ),
                  _ReferenceRow(
                    'sale.enable_edit_mode',
                    '0 or 1',
                    'Whether edit mode is enabled.',
                  ),
                  _ReferenceRow('sale.station', 'Text', 'POS station.'),
                  _ReferenceRow(
                    'sale.last_update_station',
                    'Text',
                    'Station that last updated the sale.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Setting object: known fields',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'These fields are mapped by the app. Any additional top-level key returned by get_setting is also available as setting.<key>.',
                  ),
                  SizedBox(height: 8),
                  _ReferenceTable(
                    rows: [
                      _ReferenceRow(
                        'setting.business_name_en',
                        'Text',
                        'English business name.',
                      ),
                      _ReferenceRow(
                        'setting.business_name_kh',
                        'Text',
                        'Khmer business name.',
                      ),
                      _ReferenceRow(
                        'setting.address',
                        'Text',
                        'Business address.',
                      ),
                      _ReferenceRow(
                        'setting.business_address',
                        'Text',
                        'Alias of setting.address.',
                      ),
                      _ReferenceRow(
                        'setting.phone_number_1',
                        'Text',
                        'Primary business phone.',
                      ),
                      _ReferenceRow(
                        'setting.business_phone',
                        'Text',
                        'Alias of setting.phone_number_1.',
                      ),
                      _ReferenceRow(
                        'setting.photo',
                        'Image path',
                        'Business image/logo returned by Get Setting.',
                      ),
                      _ReferenceRow(
                        'setting.property_code',
                        'Text',
                        'Property/company code.',
                      ),
                      _ReferenceRow(
                        'setting.outlet',
                        'Text',
                        'Default/current outlet.',
                      ),
                      _ReferenceRow(
                        'setting.default_unit',
                        'Text',
                        'Default unit.',
                      ),
                      _ReferenceRow(
                        'setting.default_stock_location',
                        'Text',
                        'Default stock location.',
                      ),
                      _ReferenceRow(
                        'setting.default_currency',
                        'Text',
                        'Primary currency code.',
                      ),
                      _ReferenceRow(
                        'setting.currency_symbol',
                        'Text',
                        'Primary currency symbol used by totals.',
                      ),
                      _ReferenceRow(
                        'setting.currency_format',
                        'Text',
                        'Currency display format from backend.',
                      ),
                      _ReferenceRow(
                        'setting.second_currency',
                        'Text',
                        'Secondary currency code.',
                      ),
                      _ReferenceRow(
                        'setting.second_currency_symbol',
                        'Text',
                        'Secondary currency symbol.',
                      ),
                      _ReferenceRow(
                        'setting.exchange_rate',
                        'Number',
                        'Currency exchange rate.',
                      ),
                      _ReferenceRow(
                        'setting.default_print_template',
                        'Text',
                        'Configured default print template.',
                      ),
                      _ReferenceRow(
                        'setting.payment_types',
                        'List',
                        'Payment type rows; not currently an iterable receipt block.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'POS Print Template object: all fields',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReferenceTable(
                    rows: [
                      _ReferenceRow(
                        'print_template.name',
                        'Text',
                        'Frappe document name; normally the template name.',
                      ),
                      _ReferenceRow(
                        'print_template.template_name',
                        'Text',
                        'Template display/name field.',
                      ),
                      _ReferenceRow(
                        'print_template.description',
                        'Text',
                        'Template description.',
                      ),
                      _ReferenceRow(
                        'print_template.enabled',
                        '0 or 1',
                        'Whether the backend template is enabled.',
                      ),
                      _ReferenceRow(
                        'print_template.paper_size',
                        'A6, A5, A4',
                        'Configured paper size.',
                      ),
                      _ReferenceRow(
                        'print_template.orientation',
                        'Portrait or Landscape',
                        'Configured page orientation.',
                      ),
                      _ReferenceRow(
                        'print_template.number_of_copies',
                        'Integer',
                        'Default print-copy count.',
                      ),
                      _ReferenceRow(
                        'print_template.template_logo',
                        'Image path',
                        'Uploaded logo. Use with type=image.',
                      ),
                      _ReferenceRow(
                        'print_template.schema_version',
                        'Integer',
                        'Template schema version.',
                      ),
                      _ReferenceRow(
                        'print_template.layout_json',
                        'JSON text',
                        'Layout source itself; normally not printed.',
                      ),
                      _ReferenceRow(
                        'print_template.owner',
                        'Text',
                        'Frappe owner, when returned by the API.',
                      ),
                      _ReferenceRow(
                        'print_template.creation',
                        'Date/time',
                        'Frappe creation timestamp, when returned.',
                      ),
                      _ReferenceRow(
                        'print_template.modified',
                        'Date/time',
                        'Frappe modified timestamp, when returned.',
                      ),
                      _ReferenceRow(
                        'print_template.modified_by',
                        'Text',
                        'Frappe last editor, when returned.',
                      ),
                      _ReferenceRow(
                        'print_template.docstatus',
                        'Integer',
                        'Frappe document status, when returned.',
                      ),
                      _ReferenceRow(
                        'print_template.idx',
                        'Integer',
                        'Frappe row index, when returned.',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The API requests fields=["*"], so custom top-level fields added to POS Print Template are also available automatically as print_template.<fieldname>.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Generic table: properties and examples',
              initiallyExpanded: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table options may be written directly on the table block as shown below, or inside properties. Direct options are normalized into properties when parsed.',
                  ),
                  SizedBox(height: 8),
                  _ReferenceTable(
                    rows: [
                      _ReferenceRow(
                        'source',
                        'List field, optional',
                        'When present, creates one row for every item. Example: sale.sale_products or setting.payment_types.',
                      ),
                      _ReferenceRow(
                        'columns',
                        'Array; dynamic table',
                        'Column definitions using fieldname (or key), label, flex/width, type, alignment, visible, and show_if.',
                      ),
                      _ReferenceRow(
                        'rows',
                        'Array; static table',
                        'Fixed rows. Each row contains cells and may use visible, show_if, header, and background_color.',
                      ),
                      _ReferenceRow(
                        'cells',
                        'Array; static row',
                        'Cell definitions using text or fieldname, label, type, alignment, font_size, bold, visible, show_if, padding, and background_color.',
                      ),
                      _ReferenceRow(
                        'column_widths',
                        'Number array',
                        'Static-table relative widths, for example [1, 2]. Dynamic columns use flex or width individually.',
                      ),
                      _ReferenceRow(
                        'header',
                        'Boolean; dynamic default true',
                        'Shows column labels for a dynamic table. For a static table, treats the first row as a header.',
                      ),
                      _ReferenceRow(
                        'header_bold',
                        'Boolean; default true',
                        'Controls dynamic header font weight.',
                      ),
                      _ReferenceRow(
                        'repeat_header',
                        'Boolean; default true',
                        'Repeats the header when a top-level table continues on another page.',
                      ),
                      _ReferenceRow(
                        'border',
                        'Boolean; default true',
                        'Shows or hides all table borders.',
                      ),
                      _ReferenceRow(
                        'border_width',
                        'Number; default 0.4',
                        'Border thickness in PDF points.',
                      ),
                      _ReferenceRow(
                        'cell_padding',
                        'Number or "L T R B"',
                        'Default cell padding in millimetres. A cell padding value overrides it.',
                      ),
                      _ReferenceRow(
                        'type',
                        'text, date, number, quantity, currency',
                        'Formats a static cell or dynamic column value. currency automatically appends setting.currency_symbol. Unknown/omitted types render text.',
                      ),
                      _ReferenceRow(
                        'mask',
                        'true, false, field, or comparison',
                        'Currency only. true masks the value; false always shows it. A field/expression masks when it evaluates true, for example sale.can_show_price != 1.',
                      ),
                      _ReferenceRow(
                        'mask_text',
                        'Text; default ***',
                        'Replacement displayed when mask is true. The currency symbol is still appended.',
                      ),
                      _ReferenceRow(
                        'background_color',
                        '#RRGGBB',
                        'Optional row or cell background. Cell color overrides row color.',
                      ),
                      _ReferenceRow(
                        'show_if',
                        'Field or !field',
                        'Hides a static row/cell or dynamic column based on receipt data.',
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('Static label/value table:'),
                  SizedBox(height: 6),
                  SelectableText('''{
  "type": "table",
  "border": false,
  "column_widths": [1, 2],
  "cell_padding": "1 1 1 1",
  "rows": [
    {
      "cells": [
        {"text": "Invoice No:", "bold": true},
        {"fieldname": "sale.name", "alignment": "right"}
      ]
    },
    {
      "cells": [
        {"text": "Posting Date:", "bold": true},
        {"type": "date", "fieldname": "sale.posting_date", "alignment": "right"}
      ]
    },
    {
      "show_if": "sale.driver_name",
      "cells": [
        {"text": "Driver:", "bold": true},
        {"fieldname": "sale.driver_name", "alignment": "right"}
      ]
    },
    {
      "cells": [
        {"text": "Customer:", "bold": true},
        {"text": "{{sale.customer_name}} {{sale.phone_number}}", "alignment": "right"}
      ]
    }
  ]
}''', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 12),
                  Text('Dynamic Sale Product table:'),
                  SizedBox(height: 6),
                  SelectableText('''{
  "type": "table",
  "source": "sale.sale_products",
  "header": true,
  "repeat_header": true,
  "border": true,
  "cell_padding": 1,
  "columns": [
    {"fieldname": "index", "label": "No.", "flex": 0.5, "alignment": "center"},
    {"fieldname": "product_name", "label": "Product", "flex": 2.5},
    {"fieldname": "total_sale_quantity", "label": "Qty", "type": "quantity", "flex": 1, "alignment": "center"},
    {"fieldname": "price", "label": "Price", "type": "currency", "mask": false, "flex": 1.2, "alignment": "right"},
    {"fieldname": "total_amount", "label": "Amount", "type": "currency", "mask": "sale.can_show_price != 1", "mask_text": "HIDDEN", "flex": 1.4, "alignment": "right"}
  ]
}''', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 8),
                  Text(
                    'For sale.sale_products, price/amount/cost fields automatically mask when sale.can_show_price is false if mask is omitted. Set mask=false to override, mask=true to always mask, or use a condition such as "sale.can_show_price == 1" or "sale.can_show_price != 1". The condition result directly controls masking.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Sale Product object and product_table columns',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Each properties.columns item supports key, label, width, alignment (left/center/right), and visible. All fields below can be used as key.',
                  ),
                  SizedBox(height: 8),
                  _ReferenceTable(
                    rows: [
                      _ReferenceRow(
                        'index',
                        'Generated integer',
                        'One-based printed row number.',
                      ),
                      _ReferenceRow(
                        'name',
                        'Text',
                        'Sale Product child-row document name.',
                      ),
                      _ReferenceRow('product_code', 'Text', 'Product code.'),
                      _ReferenceRow('product_name', 'Text', 'Product name.'),
                      _ReferenceRow(
                        'product_category',
                        'Text',
                        'Product category.',
                      ),
                      _ReferenceRow('outlet', 'Text', 'Product-row outlet.'),
                      _ReferenceRow(
                        'photo',
                        'Image path as text',
                        'Product image path; table cells currently render text only.',
                      ),
                      _ReferenceRow('base_unit', 'Text', 'Base unit.'),
                      _ReferenceRow(
                        'allow_split_bill',
                        '0 or 1',
                        'Split-bill permission.',
                      ),
                      _ReferenceRow(
                        'allow_change_sale_type',
                        '0 or 1',
                        'Sale-type change permission.',
                      ),
                      _ReferenceRow(
                        'sale_transaction_type',
                        'Text',
                        'Sale, Borrow, Return, or backend value.',
                      ),
                      _ReferenceRow('unit', 'Text', 'Selected sale unit.'),
                      _ReferenceRow('multiplier', 'Number', 'Unit multiplier.'),
                      _ReferenceRow('revenue_group', 'Text', 'Revenue group.'),
                      _ReferenceRow(
                        'allow_sum_qty',
                        '0 or 1',
                        'Whether quantity contributes to totals.',
                      ),
                      _ReferenceRow(
                        'is_inventory_product',
                        '0 or 1',
                        'Inventory-product flag.',
                      ),
                      _ReferenceRow(
                        'quantity',
                        'Number + unit',
                        'Net sale quantity followed by unit (special display).',
                      ),
                      _ReferenceRow('price', 'Money', 'Sale unit price.'),
                      _ReferenceRow(
                        'product_price',
                        'Money',
                        'Original/product price.',
                      ),
                      _ReferenceRow(
                        'free_quantity',
                        'Number',
                        'Free quantity.',
                      ),
                      _ReferenceRow(
                        'return_quantity',
                        'Number',
                        'Returned quantity.',
                      ),
                      _ReferenceRow(
                        'split_quantity',
                        'Number',
                        'Split quantity.',
                      ),
                      _ReferenceRow(
                        'total_sale_quantity',
                        'Number',
                        'Net quantity after free/return/split.',
                      ),
                      _ReferenceRow('sub_total', 'Money', 'quantity × price.'),
                      _ReferenceRow(
                        'amount',
                        'Money',
                        'Alias of total_amount.',
                      ),
                      _ReferenceRow(
                        'total_amount',
                        'Money',
                        'Net sale quantity × price.',
                      ),
                      _ReferenceRow('cost', 'Money', 'Unit cost.'),
                      _ReferenceRow(
                        'total_cost',
                        'Money',
                        'Net sale quantity × cost.',
                      ),
                      _ReferenceRow(
                        'stock_location',
                        'Text',
                        'Product-row stock location.',
                      ),
                      _ReferenceRow(
                        'allow_free',
                        '0 or 1',
                        'Free-quantity permission.',
                      ),
                      _ReferenceRow(
                        'allow_change_price',
                        '0 or 1',
                        'Price-change permission.',
                      ),
                      _ReferenceRow(
                        'allow_return',
                        '0 or 1',
                        'Return permission.',
                      ),
                      _ReferenceRow('note', 'Text', 'Product-row note.'),
                    ],
                  ),
                  SizedBox(height: 8),
                  SelectableText('''"properties": {
  "columns": [
    {"key":"product_name","label":"Product","width":2.5},
    {"key":"quantity","label":"Qty","width":1,"alignment":"center"},
    {"key":"amount","label":"Amount","width":1.3,"alignment":"right"}
  ]
}''', style: TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Important layout rules',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• A dynamic table and product_table must remain top-level flow blocks so rows can continue across pages.',
                  ),
                  Text('• Only top-level blocks may use absolute positioning.'),
                  Text(
                    '• Absolute coordinates are relative to the printable area, not the physical paper edge.',
                  ),
                  Text(
                    '• Absolute footers can overlap flow content because they do not reserve bottom space.',
                  ),
                  Text(
                    '• Invalid JSON or out-of-page absolute blocks do not update the preview or API.',
                  ),
                  Text(
                    '• Editing refreshes the preview after 3 seconds of inactivity. Only Save updates the API.',
                  ),
                  Text(
                    '• Empty resolved text/date values hide that leaf block. Use show_if on a parent row/column to hide the whole group.',
                  ),
                ],
              ),
            ),
            const _HelpSection(
              title: 'Complete A6 sample receipt',
              child: SelectableText(
                sampleReceipt,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
    );
  }
}

class _ReferenceRow {
  const _ReferenceRow(this.property, this.values, this.description);

  final String property;
  final String values;
  final String description;
}

class _ReferenceTable extends StatelessWidget {
  const _ReferenceTable({required this.rows});

  final List<_ReferenceRow> rows;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    return Table(
      border: TableBorder.all(color: borderColor),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(3.5),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          children: [
            _TableCell('Property / type', bold: true),
            _TableCell('Values / default', bold: true),
            _TableCell('Explanation', bold: true),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _TableCell(row.property, code: true),
              _TableCell(row.values, code: true),
              _TableCell(row.description),
            ],
          ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.value, {this.bold = false, this.code = false});

  final String value;
  final bool bold;
  final bool code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SelectableText(
        value,
        style: TextStyle(
          fontFamily: code ? 'monospace' : null,
          fontWeight: bold ? FontWeight.bold : null,
          fontSize: 12,
        ),
      ),
    );
  }
}
