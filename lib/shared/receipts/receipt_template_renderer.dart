import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/app_setting.dart';
import '../../features/sell/sale.dart';
import '../../features/sell/sale_product.dart';
import '../../utils/helpers.dart';
import 'receipt_raster_text.dart';
import 'receipt_template.dart';

class ReceiptTemplateRenderer {
  const ReceiptTemplateRenderer._();

  static Map<String, String> resolveImageSources({
    required Sale sale,
    required AppSetting business,
    required ReceiptTemplate template,
    required String sellerFallback,
  }) {
    final seller = sale.seller.trim().isNotEmpty
        ? sale.seller.trim()
        : sellerFallback.trim();
    final result = <String, String>{};
    void visit(ReceiptBlock block) {
      if (block.type == ReceiptBlockType.image && block.fieldname.isNotEmpty) {
        final source = _resolveRawField(
          block.fieldname,
          sale,
          business,
          seller,
          template: template,
        )?.toString().trim();
        if (source != null && source.isNotEmpty) {
          result[block.fieldname] = source;
        }
      }
      if (block.child != null) visit(block.child!);
      for (final child in block.children) {
        visit(child);
      }
    }

    for (final block in template.blocks) {
      visit(block);
    }
    return result;
  }

  static Future<Uint8List> buildPdf({
    required Sale sale,
    required AppSetting business,
    required String sellerFallback,
    required ReceiptTemplate template,
    int copies = 1,
    Map<String, Uint8List> imageBytes = const <String, Uint8List>{},
  }) async {
    final document = pw.Document(
      title: sale.name.isEmpty ? 'Invoice' : sale.name,
      author: business.businessNameEn,
      creator: 'Ice Control Sale',
    );
    final pageFormat = template.pageFormat;
    final margin = template.marginMm * PdfPageFormat.mm;
    final contentWidth = pageFormat.width - (margin * 2);
    final seller = sale.seller.trim().isNotEmpty
        ? sale.seller.trim()
        : sellerFallback.trim();
    final flowWidgets = await _buildFlowBlocks(
      sale: sale,
      business: business,
      seller: seller,
      template: template,
      imageBytes: imageBytes,
      contentWidth: contentWidth,
    );
    final absoluteWidgets = await _buildAbsoluteBlocks(
      sale: sale,
      business: business,
      seller: seller,
      template: template,
      imageBytes: imageBytes,
    );

    for (var copy = 0; copy < copies.clamp(1, 3); copy++) {
      final firstPageNumber = document.document.pdfPageList.pages.length + 1;
      late int lastPageNumber;
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.all(margin),
            clip: true,
            buildForeground: absoluteWidgets.isEmpty
                ? null
                : (context) => _absoluteLayer(
                    context,
                    absoluteWidgets,
                    firstPageNumber: firstPageNumber,
                    lastPageNumber: lastPageNumber,
                  ),
          ),
          build: (_) => flowWidgets,
        ),
      );
      lastPageNumber = document.document.pdfPageList.pages.length;
    }
    return document.save();
  }

  static Future<List<pw.Widget>> _buildFlowBlocks({
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
    required double contentWidth,
  }) async {
    final result = <pw.Widget>[];
    final blocks = template.blocks.where(
      (block) =>
          _isBlockVisible(block, sale, business, seller, template: template) &&
          (block.position == ReceiptPositionMode.flow ||
              block.type == ReceiptBlockType.productTable),
    );
    for (final block in blocks) {
      final margin = block.resolvedMargin;
      final padding = _leafPadding(block);
      final innerWidth =
          (contentWidth -
                  (margin.left + margin.right + padding.left + padding.right) *
                      PdfPageFormat.mm)
              .clamp(0.0, contentWidth);
      if (block.spacingBefore > 0) {
        result.add(pw.SizedBox(height: block.spacingBefore));
      }
      final child = await _buildBlock(
        block,
        sale: sale,
        business: business,
        seller: seller,
        template: template,
        imageBytes: imageBytes,
        contentWidth: innerWidth,
      );
      result.add(
        block.type == ReceiptBlockType.productTable
            ? child
            : pw.Padding(
                padding: _edgeInsets(margin),
                child: pw.Padding(padding: _edgeInsets(padding), child: child),
              ),
      );
      if (block.spacingAfter > 0) {
        result.add(pw.SizedBox(height: block.spacingAfter));
      }
    }
    return result;
  }

  static Future<List<_AbsoluteBlockRender>> _buildAbsoluteBlocks({
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
  }) async {
    final blocks =
        template.blocks
            .where(
              (block) =>
                  _isBlockVisible(
                    block,
                    sale,
                    business,
                    seller,
                    template: template,
                  ) &&
                  block.position == ReceiptPositionMode.absolute &&
                  block.type != ReceiptBlockType.productTable &&
                  block.xMm != null &&
                  block.yMm != null &&
                  block.widthMm != null &&
                  block.heightMm != null,
            )
            .toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final result = <_AbsoluteBlockRender>[];
    for (final block in blocks) {
      final width = block.widthMm! * PdfPageFormat.mm;
      final height = block.heightMm! * PdfPageFormat.mm;
      final margin = block.resolvedMargin;
      final padding = _leafPadding(block);
      final innerWidth =
          (width -
                  (margin.left + margin.right + padding.left + padding.right) *
                      PdfPageFormat.mm)
              .clamp(0.0, width);
      final child = await _buildBlock(
        block,
        sale: sale,
        business: business,
        seller: seller,
        template: template,
        imageBytes: imageBytes,
        contentWidth: innerWidth,
      );
      final positionedChild = pw.Padding(
        padding: _edgeInsets(margin),
        child: pw.Padding(padding: _edgeInsets(padding), child: child),
      );
      final constrained = switch (block.overflow) {
        ReceiptBlockOverflow.shrink => pw.SizedBox(
          width: width,
          height: height,
          child: pw.FittedBox(fit: pw.BoxFit.scaleDown, child: positionedChild),
        ),
        ReceiptBlockOverflow.clip => pw.SizedBox(
          width: width,
          height: height,
          child: pw.ClipRect(child: positionedChild),
        ),
        ReceiptBlockOverflow.wrap => pw.SizedBox(
          width: width,
          height: height,
          child: positionedChild,
        ),
      };
      result.add(_AbsoluteBlockRender(block, constrained));
    }
    return result;
  }

  static pw.Widget _absoluteLayer(
    pw.Context context,
    List<_AbsoluteBlockRender> blocks, {
    required int firstPageNumber,
    required int lastPageNumber,
  }) {
    final visible = blocks.where((item) {
      return switch (item.block.repeat) {
        ReceiptPageRepeat.firstPage => context.pageNumber == firstPageNumber,
        ReceiptPageRepeat.everyPage => true,
        ReceiptPageRepeat.lastPage => context.pageNumber == lastPageNumber,
      };
    });
    return pw.Stack(
      fit: pw.StackFit.expand,
      overflow: pw.Overflow.clip,
      children: [
        for (final item in visible)
          pw.Positioned(
            left: item.block.xMm! * PdfPageFormat.mm,
            top: item.block.yMm! * PdfPageFormat.mm,
            child: item.widget,
          ),
      ],
    );
  }

  static Future<pw.Widget> _buildBlock(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
    required double contentWidth,
  }) async {
    switch (block.type) {
      case ReceiptBlockType.row:
        return _buildRow(
          block,
          sale: sale,
          business: business,
          seller: seller,
          template: template,
          imageBytes: imageBytes,
          contentWidth: contentWidth,
        );
      case ReceiptBlockType.column:
        return _buildColumn(
          block,
          sale: sale,
          business: business,
          seller: seller,
          template: template,
          imageBytes: imageBytes,
          contentWidth: contentWidth,
        );
      case ReceiptBlockType.container:
        return _buildContainer(
          block,
          sale: sale,
          business: business,
          seller: seller,
          template: template,
          imageBytes: imageBytes,
          contentWidth: contentWidth,
        );
      case ReceiptBlockType.image:
        final bytes = imageBytes[block.fieldname];
        if (bytes == null || bytes.isEmpty) return pw.SizedBox();
        return pw.Align(
          alignment: _alignment(block.alignment),
          child: pw.SizedBox(
            width: (block.widthMm ?? 30) * PdfPageFormat.mm,
            height: (block.heightMm ?? 20) * PdfPageFormat.mm,
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
        );
      case ReceiptBlockType.text:
        final resolved = block.text.isNotEmpty
            ? _resolveTokens(
                block.text,
                sale,
                business,
                seller,
                template: template,
              )
            : _resolveField(
                block.fieldname,
                sale,
                business,
                seller,
                template: template,
              );
        if (resolved.trim().isEmpty) return pw.SizedBox();
        final value = '${block.label}$resolved';
        return _textWidget(value, block, contentWidth: contentWidth);
      case ReceiptBlockType.date:
        final value = _formatDateValue(
          _resolveRawField(
            block.fieldname,
            sale,
            business,
            seller,
            template: template,
          ),
        );
        if (value.isEmpty) return pw.SizedBox();
        return _textWidget(
          '${block.label}$value',
          block,
          contentWidth: contentWidth,
        );
      case ReceiptBlockType.customerInfo:
        final identity = [
          sale.customer.trim(),
          sale.customerName.trim(),
        ].where((value) => value.isNotEmpty).join(' - ');
        final value = [
          if (_fieldEnabled(block, 'customer'))
            'លក់ជូន៖ ${identity.isEmpty ? '-' : identity}',
          if (_fieldEnabled(block, 'phone') &&
              sale.phoneNumber.trim().isNotEmpty)
            'ទូរស័ព្ទ៖ ${sale.phoneNumber.trim()}',
        ].join('  ');
        return _textWidget(value, block, contentWidth: contentWidth);
      case ReceiptBlockType.table:
        return _genericTable(
          block,
          sale: sale,
          business: business,
          seller: seller,
          template: template,
          contentWidth: contentWidth,
        );
      case ReceiptBlockType.productTable:
        return _productTable(sale, block, contentWidth);
      case ReceiptBlockType.totals:
        return _totals(sale, business, block, contentWidth);
      case ReceiptBlockType.barcode:
        if (sale.name.trim().isEmpty) return pw.SizedBox();
        final width = block.widthMm == null
            ? contentWidth.clamp(80.0, 150.0)
            : block.widthMm! * PdfPageFormat.mm;
        return pw.Align(
          alignment: _alignment(block.alignment),
          child: pw.SizedBox(
            width: width,
            child: pw.Column(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: sale.name.trim(),
                  width: width,
                  height: (block.heightMm ?? 9) * PdfPageFormat.mm,
                  drawText: false,
                ),
                pw.SizedBox(height: 2),
                await ReceiptRasterText.create(
                  sale.name.trim(),
                  fontSize: block.fontSize,
                  fontWeight: block.bold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  textAlign: pw.TextAlign.center,
                  maxWidth: width,
                ),
              ],
            ),
          ),
        );
      case ReceiptBlockType.notes:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_fieldEnabled(block, 'reference_number') &&
                sale.referenceNumber.trim().isNotEmpty)
              await _textWidget(
                'លេខយោង៖ ${sale.referenceNumber.trim()}',
                block,
                contentWidth: contentWidth,
              ),
            if (_fieldEnabled(block, 'note') && sale.note.trim().isNotEmpty)
              await _textWidget(
                'ចំណាំ៖ ${sale.note.trim()}',
                block,
                contentWidth: contentWidth,
              ),
          ],
        );
      case ReceiptBlockType.signatures:
        final values = <(String, String)>[
          if (_fieldEnabled(block, 'seller')) ('អ្នកលក់', seller),
          if (_fieldEnabled(block, 'driver')) ('អ្នកបើកបរ', sale.driverName),
          if (_fieldEnabled(block, 'customer')) ('អតិថិជន', sale.customerName),
        ];
        if (values.isEmpty) return pw.SizedBox();
        final gap = (block.gapMm == 0 ? 3 : block.gapMm) * PdfPageFormat.mm;
        final signatureWidth = contentWidth / values.length;
        final children = <pw.Widget>[];
        for (var index = 0; index < values.length; index++) {
          children.add(
            await _signature(
              values[index].$1,
              values[index].$2,
              signatureWidth,
              lineInset: gap / 2,
            ),
          );
        }
        return pw.Row(children: children);
      case ReceiptBlockType.divider:
        return pw.Divider(thickness: 0.5, height: 1);
      case ReceiptBlockType.spacer:
        return pw.SizedBox(
          height: (block.heightMm ?? block.spacingAfter) * PdfPageFormat.mm,
        );
    }
  }

  static Future<pw.Widget> _buildRow(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
    required double contentWidth,
  }) async {
    final children = _nestedChildren(block)
        .where(
          (item) =>
              _isBlockVisible(item, sale, business, seller, template: template),
        )
        .toList();
    if (children.isEmpty) return pw.SizedBox();
    final padding = block.resolvedPadding;
    final gap = block.gapMm * PdfPageFormat.mm;
    final innerWidth =
        (contentWidth -
                (padding.left + padding.right) * PdfPageFormat.mm -
                gap * (children.length - 1))
            .clamp(0.0, contentWidth);
    final totalFlex = children.fold<double>(0, (sum, item) => sum + item.flex);
    final widgets = <pw.Widget>[];
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final width = totalFlex == 0 ? 0.0 : innerWidth * child.flex / totalFlex;
      widgets.add(
        pw.SizedBox(
          width: width,
          child: await _buildNestedChild(
            child,
            sale: sale,
            business: business,
            seller: seller,
            template: template,
            imageBytes: imageBytes,
            contentWidth: width,
          ),
        ),
      );
      if (index < children.length - 1 && gap > 0) {
        widgets.add(pw.SizedBox(width: gap));
      }
    }
    return pw.Padding(
      padding: _edgeInsets(padding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  static Future<pw.Widget> _buildColumn(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
    required double contentWidth,
  }) async {
    final children = _nestedChildren(block)
        .where(
          (item) =>
              _isBlockVisible(item, sale, business, seller, template: template),
        )
        .toList();
    if (children.isEmpty) return pw.SizedBox();
    final padding = block.resolvedPadding;
    final gap = block.gapMm * PdfPageFormat.mm;
    final innerWidth =
        (contentWidth - (padding.left + padding.right) * PdfPageFormat.mm)
            .clamp(0.0, contentWidth);
    final widgets = <pw.Widget>[];
    for (var index = 0; index < children.length; index++) {
      widgets.add(
        await _buildNestedChild(
          children[index],
          sale: sale,
          business: business,
          seller: seller,
          template: template,
          imageBytes: imageBytes,
          contentWidth: innerWidth,
        ),
      );
      if (index < children.length - 1 && gap > 0) {
        widgets.add(pw.SizedBox(height: gap));
      }
    }
    return pw.Padding(
      padding: _edgeInsets(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: widgets,
      ),
    );
  }

  static Future<pw.Widget> _buildContainer(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
    required double contentWidth,
  }) async {
    final width = block.widthMm == null
        ? contentWidth
        : block.widthMm! * PdfPageFormat.mm;
    final padding = block.resolvedPadding;
    final innerWidth =
        (width - (padding.left + padding.right) * PdfPageFormat.mm).clamp(
          0.0,
          width,
        );
    final children = _nestedChildren(block)
        .where(
          (item) =>
              _isBlockVisible(item, sale, business, seller, template: template),
        )
        .toList();
    final built = <pw.Widget>[];
    for (final child in children) {
      built.add(
        await _buildNestedChild(
          child,
          sale: sale,
          business: business,
          seller: seller,
          template: template,
          imageBytes: imageBytes,
          contentWidth: innerWidth,
        ),
      );
    }
    final child = built.length == 1 ? built.single : pw.Column(children: built);
    return pw.Container(
      width: width,
      height: block.heightMm == null
          ? null
          : block.heightMm! * PdfPageFormat.mm,
      padding: _edgeInsets(padding),
      child: child,
    );
  }

  static Future<pw.Widget> _buildNestedChild(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required Map<String, Uint8List> imageBytes,
    required double contentWidth,
  }) async {
    final margin = block.resolvedMargin;
    final padding = _leafPadding(block);
    final innerWidth =
        (contentWidth -
                (margin.left + margin.right + padding.left + padding.right) *
                    PdfPageFormat.mm)
            .clamp(0.0, contentWidth);
    final child = await _buildBlock(
      block,
      sale: sale,
      business: business,
      seller: seller,
      template: template,
      imageBytes: imageBytes,
      contentWidth: innerWidth,
    );
    return pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(
        margin.left * PdfPageFormat.mm,
        margin.top * PdfPageFormat.mm + block.spacingBefore,
        margin.right * PdfPageFormat.mm,
        margin.bottom * PdfPageFormat.mm + block.spacingAfter,
      ),
      child: pw.Padding(padding: _edgeInsets(padding), child: child),
    );
  }

  static List<ReceiptBlock> _nestedChildren(ReceiptBlock block) => [
    if (block.child != null) block.child!,
    ...block.children,
  ];

  static pw.EdgeInsets _edgeInsets(ReceiptInsetsMm value) =>
      pw.EdgeInsets.fromLTRB(
        value.left * PdfPageFormat.mm,
        value.top * PdfPageFormat.mm,
        value.right * PdfPageFormat.mm,
        value.bottom * PdfPageFormat.mm,
      );

  static ReceiptInsetsMm _leafPadding(ReceiptBlock block) =>
      block.type == ReceiptBlockType.row ||
          block.type == ReceiptBlockType.column ||
          block.type == ReceiptBlockType.container ||
          block.type == ReceiptBlockType.table ||
          block.type == ReceiptBlockType.productTable
      ? const ReceiptInsetsMm(0, 0, 0, 0)
      : block.resolvedPadding;

  static Future<pw.Widget> _textWidget(
    String value,
    ReceiptBlock block, {
    required double contentWidth,
  }) {
    return ReceiptRasterText.create(
      value,
      fontSize: block.fontSize,
      fontWeight: block.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      textAlign: _textAlign(block.alignment),
      maxWidth: contentWidth,
    ).then(
      (widget) =>
          pw.Align(alignment: _alignment(block.alignment), child: widget),
    );
  }

  static Future<pw.Widget> _productTable(
    Sale sale,
    ReceiptBlock block,
    double contentWidth,
  ) async {
    final columns = _productColumns(block);
    final header = <pw.Widget>[];
    for (final column in columns) {
      header.add(
        await _tableCell(column.label, column.align, true, column.width),
      );
    }
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: header,
      ),
    ];
    for (var index = 0; index < sale.saleProducts.length; index++) {
      final product = sale.saleProducts[index];
      final cells = <pw.Widget>[];
      final columnKeys = columns.map((column) => column.key).toSet();
      for (final column in columns) {
        if (column.key == 'product_name') {
          cells.add(
            await _productNameCell(
              product,
              column.width,
              showFree: !columnKeys.contains('free_quantity'),
              showReturn: !columnKeys.contains('return_quantity'),
              showSplit: !columnKeys.contains('split_quantity'),
            ),
          );
        } else {
          cells.add(
            await _tableCell(
              _productValue(column.key, index, product, sale.canShowPrice),
              column.align,
              false,
              column.width,
            ),
          );
        }
      }
      rows.add(pw.TableRow(children: cells));
    }
    return pw.Table(
      border: pw.TableBorder.all(width: 0.4),
      columnWidths: {
        for (var index = 0; index < columns.length; index++)
          index: pw.FlexColumnWidth(columns[index].width),
      },
      children: rows,
    );
  }

  static Future<pw.Widget> _genericTable(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required double contentWidth,
  }) async {
    final source = block.properties['source']?.toString().trim() ?? '';
    return source.isEmpty
        ? _staticTable(
            block,
            sale: sale,
            business: business,
            seller: seller,
            template: template,
            contentWidth: contentWidth,
          )
        : _dynamicTable(
            block,
            source: source,
            sale: sale,
            business: business,
            seller: seller,
            template: template,
            contentWidth: contentWidth,
          );
  }

  static Future<pw.Widget> _dynamicTable(
    ReceiptBlock block, {
    required String source,
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required double contentWidth,
  }) async {
    final rawRows = _resolveRawField(
      source,
      sale,
      business,
      seller,
      template: template,
    );
    final rows = rawRows is List
        ? rawRows
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final rawColumns = block.properties['columns'];
    final columns = rawColumns is List
        ? rawColumns
              .whereType<Map>()
              .map((column) => Map<String, dynamic>.from(column))
              .where((column) => _jsonBool(column['visible'], fallback: true))
              .where(
                (column) => _conditionMatches(
                  column['show_if'],
                  null,
                  sale,
                  business,
                  seller,
                  template,
                ),
              )
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    if (columns.isEmpty) return pw.SizedBox();

    final tableRows = <pw.TableRow>[];
    if (_jsonBool(block.properties['header'], fallback: true)) {
      final headerCells = <pw.Widget>[];
      for (final column in columns) {
        headerCells.add(
          await _genericTableCell(
            column['label']?.toString() ?? '',
            column,
            block,
            contentWidth,
            forceBold: _jsonBool(
              block.properties['header_bold'],
              fallback: true,
            ),
            fallbackBackground: '#eeeeee',
          ),
        );
      }
      tableRows.add(
        pw.TableRow(
          repeat: _jsonBool(block.properties['repeat_header'], fallback: true),
          children: headerCells,
        ),
      );
    }
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final cells = <pw.Widget>[];
      for (final column in columns) {
        final fieldname =
            column['fieldname']?.toString().trim().isNotEmpty == true
            ? column['fieldname'].toString().trim()
            : column['key']?.toString().trim() ?? '';
        const protectedPriceFields = {
          'price',
          'product_price',
          'sub_total',
          'amount',
          'total_amount',
          'cost',
          'total_cost',
        };
        final automaticMask =
            source == 'sale.sale_products' &&
            !sale.canShowPrice &&
            protectedPriceFields.contains(fieldname);
        final displayValue = _tableValue(
          column,
          row,
          rowIndex,
          fieldname,
          sale,
          business,
          seller,
          template,
          automaticMask: automaticMask,
        );
        cells.add(
          await _genericTableCell(displayValue, column, block, contentWidth),
        );
      }
      tableRows.add(pw.TableRow(children: cells));
    }
    return _tableWidget(block, columns, tableRows);
  }

  static Future<pw.Widget> _staticTable(
    ReceiptBlock block, {
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
    required double contentWidth,
  }) async {
    final rawRows = block.properties['rows'];
    if (rawRows is! List) return pw.SizedBox();
    final visibleRows = rawRows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where(
          (row) =>
              _jsonBool(row['visible'], fallback: true) &&
              _conditionMatches(
                row['show_if'],
                null,
                sale,
                business,
                seller,
                template,
              ),
        )
        .toList(growable: false);
    final columnCount = visibleRows.fold<int>(0, (maximum, row) {
      final cells = row['cells'];
      return cells is List && cells.length > maximum ? cells.length : maximum;
    });
    if (columnCount == 0) return pw.SizedBox();
    final widths = block.properties['column_widths'];
    final columns = List.generate(columnCount, (index) {
      final width = widths is List && index < widths.length
          ? _jsonDouble(widths[index], fallback: 1)
          : 1.0;
      return <String, dynamic>{'width': width};
    });
    final tableRows = <pw.TableRow>[];
    for (var rowIndex = 0; rowIndex < visibleRows.length; rowIndex++) {
      final row = visibleRows[rowIndex];
      final rawCells = row['cells'];
      if (rawCells is! List) continue;
      final cells = <pw.Widget>[];
      for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
        final cell =
            columnIndex < rawCells.length && rawCells[columnIndex] is Map
            ? Map<String, dynamic>.from(rawCells[columnIndex] as Map)
            : <String, dynamic>{};
        final visible =
            _jsonBool(cell['visible'], fallback: true) &&
            _conditionMatches(
              cell['show_if'],
              null,
              sale,
              business,
              seller,
              template,
            );
        final value = visible
            ? _tableValue(
                cell,
                null,
                rowIndex,
                cell['fieldname']?.toString().trim() ?? '',
                sale,
                business,
                seller,
                template,
              )
            : '';
        cells.add(
          await _genericTableCell(
            value,
            {...row, ...cell},
            block,
            contentWidth,
            forceBold: _jsonBool(
              row['header'],
              fallback:
                  rowIndex == 0 &&
                  _jsonBool(block.properties['header'], fallback: false),
            ),
          ),
        );
      }
      final isHeader = _jsonBool(
        row['header'],
        fallback:
            rowIndex == 0 &&
            _jsonBool(block.properties['header'], fallback: false),
      );
      tableRows.add(
        pw.TableRow(
          repeat:
              isHeader &&
              _jsonBool(block.properties['repeat_header'], fallback: true),
          children: cells,
        ),
      );
    }
    return _tableWidget(block, columns, tableRows);
  }

  static pw.Widget _tableWidget(
    ReceiptBlock block,
    List<Map<String, dynamic>> columns,
    List<pw.TableRow> rows,
  ) {
    final border = _jsonBool(block.properties['border'], fallback: true);
    final borderWidth = _jsonDouble(
      block.properties['border_width'],
      fallback: 0.4,
    ).clamp(0.0, double.infinity);
    return pw.Table(
      border: border ? pw.TableBorder.all(width: borderWidth) : null,
      columnWidths: {
        for (var index = 0; index < columns.length; index++)
          index: pw.FlexColumnWidth(
            _jsonDouble(
              columns[index]['flex'] ?? columns[index]['width'],
              fallback: 1,
            ).clamp(0.01, double.infinity),
          ),
      },
      children: rows,
    );
  }

  static Future<pw.Widget> _genericTableCell(
    String value,
    Map<String, dynamic> cell,
    ReceiptBlock block,
    double contentWidth, {
    bool forceBold = false,
    String? fallbackBackground,
  }) async {
    final parsedPadding = ReceiptInsetsMm.tryParse(
      cell['padding'] ?? block.properties['cell_padding'],
    );
    final padding = parsedPadding == null || parsedPadding.isNegative
        ? const ReceiptInsetsMm(1, 1, 1, 1)
        : parsedPadding;
    final alignment = cell['alignment']?.toString() ?? block.alignment;
    final background = _pdfColor(
      cell['background_color']?.toString() ?? fallbackBackground,
    );
    final child = pw.Padding(
      padding: _edgeInsets(padding),
      child: pw.Align(
        alignment: _alignment(alignment),
        child: await ReceiptRasterText.create(
          value,
          fontSize: _jsonDouble(cell['font_size'], fallback: block.fontSize),
          fontWeight: forceBold || _jsonBool(cell['bold'], fallback: block.bold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          textAlign: _textAlign(alignment),
          maxWidth: contentWidth,
        ),
      ),
    );
    return background == null
        ? child
        : pw.Container(color: background, child: child);
  }

  static String _tableValue(
    Map<String, dynamic> cell,
    Map<String, dynamic>? row,
    int rowIndex,
    String fieldname,
    Sale sale,
    AppSetting business,
    String seller,
    ReceiptTemplate template, {
    bool automaticMask = false,
  }) {
    final text = cell['text']?.toString() ?? '';
    Object? value;
    if (text.isNotEmpty) {
      value = text.replaceAllMapped(RegExp(r'\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}'), (
        match,
      ) {
        final key = match.group(1) ?? '';
        return (_mapValue(row, key) ??
                _resolveRawField(
                  key,
                  sale,
                  business,
                  seller,
                  template: template,
                ) ??
                '')
            .toString();
      });
    } else if (fieldname == 'index') {
      value = rowIndex + 1;
    } else {
      value =
          _mapValue(row, fieldname) ??
          _resolveRawField(
            fieldname,
            sale,
            business,
            seller,
            template: template,
          );
    }
    final type = cell['type']?.toString();
    final isCurrency = type?.trim().toLowerCase() == 'currency';
    final shouldMask =
        isCurrency &&
        _maskEnabled(
          cell['mask'],
          defaultValue: automaticMask,
          row: row,
          sale: sale,
          business: business,
          seller: seller,
          template: template,
        );
    final formatted = shouldMask
        ? (cell['mask_text']?.toString().trim().isNotEmpty == true
              ? cell['mask_text'].toString().trim()
              : '***')
        : _formatTableValue(value, type);
    final displayValue = _withCurrencySymbol(
      formatted,
      type,
      business.currencySymbol,
    );
    return '${cell['label']?.toString() ?? ''}$displayValue';
  }

  static bool _maskEnabled(
    Object? mask, {
    required bool defaultValue,
    required Map<String, dynamic>? row,
    required Sale sale,
    required AppSetting business,
    required String seller,
    required ReceiptTemplate template,
  }) {
    if (mask == null) return defaultValue;
    if (mask is bool) return mask;
    if (mask is num) return mask != 0;
    final expression = mask.toString().trim();
    if (expression.isEmpty) return defaultValue;
    final literal = expression.toLowerCase();
    if (const {'true', '1', 'yes'}.contains(literal)) return true;
    if (const {'false', '0', 'no'}.contains(literal)) return false;

    final comparison = RegExp(
      r'^(.+?)\s*(==|!=)\s*(.+)$',
    ).firstMatch(expression);
    if (comparison != null) {
      final actual = _tableConditionValue(
        comparison.group(1) ?? '',
        row,
        sale,
        business,
        seller,
        template,
      );
      final expected = _conditionLiteral(comparison.group(3) ?? '');
      final equals = _conditionValuesEqual(actual, expected);
      return comparison.group(2) == '!=' ? !equals : equals;
    }

    return _truthy(
      _tableConditionValue(expression, row, sale, business, seller, template),
    );
  }

  static Object? _tableConditionValue(
    String fieldname,
    Map<String, dynamic>? row,
    Sale sale,
    AppSetting business,
    String seller,
    ReceiptTemplate template,
  ) =>
      _mapValue(row, fieldname.trim()) ??
      _resolveRawField(
        fieldname.trim(),
        sale,
        business,
        seller,
        template: template,
      );

  static Object? _conditionLiteral(String source) {
    final value = source.trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    if (value.toLowerCase() == 'null') return null;
    return num.tryParse(value) ?? value;
  }

  static bool _conditionValuesEqual(Object? actual, Object? expected) {
    if (actual is num && expected is num) return actual == expected;
    if (actual is bool && expected is num) {
      return (actual ? 1 : 0) == expected;
    }
    if (actual is num && expected is bool) {
      return actual == (expected ? 1 : 0);
    }
    return actual?.toString().trim().toLowerCase() ==
        expected?.toString().trim().toLowerCase();
  }

  static String _withCurrencySymbol(
    String value,
    String? type,
    String currencySymbol,
  ) {
    final symbol = currencySymbol.trim();
    if (value.trim().isEmpty ||
        symbol.isEmpty ||
        type?.trim().toLowerCase() != 'currency') {
      return value;
    }
    return '${value.trim()} $symbol';
  }

  static Object? _mapValue(Map<String, dynamic>? row, String fieldname) {
    if (row == null || fieldname.isEmpty) return null;
    Object? value = row;
    for (final part in fieldname.split('.')) {
      if (value is! Map || !value.containsKey(part)) return null;
      value = value[part];
    }
    return value;
  }

  static String _formatTableValue(Object? value, String? type) {
    if (value == null) return '';
    final normalized = type?.trim().toLowerCase() ?? 'text';
    if (normalized == 'date') return _formatDateValue(value);
    if (normalized == 'currency') {
      final number = value is num ? value : num.tryParse(value.toString());
      return number == null ? value.toString() : formatMoney(number);
    }
    if (normalized == 'quantity' || normalized == 'number') {
      final number = value is num ? value : num.tryParse(value.toString());
      return number == null ? value.toString() : formatQuantity(number);
    }
    return value.toString().trim();
  }

  static bool _conditionMatches(
    Object? rawCondition,
    Map<String, dynamic>? row,
    Sale sale,
    AppSetting business,
    String seller,
    ReceiptTemplate template,
  ) {
    var condition = rawCondition?.toString().trim() ?? '';
    if (condition.isEmpty) return true;
    final inverted = condition.startsWith('!');
    if (inverted) condition = condition.substring(1).trim();
    final value =
        _mapValue(row, condition) ??
        _resolveRawField(condition, sale, business, seller, template: template);
    final matches = _truthy(value);
    return inverted ? !matches : matches;
  }

  static bool _jsonBool(Object? value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {
      'true',
      '1',
      'yes',
    }.contains(value.toString().trim().toLowerCase());
  }

  static double _jsonDouble(Object? value, {required double fallback}) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

  static bool _truthy(Object? value) => switch (value) {
    null => false,
    bool flag => flag,
    num number => number != 0,
    _ => !const {
      '',
      '0',
      'false',
      'no',
      'null',
    }.contains(value.toString().trim().toLowerCase()),
  };

  static PdfColor? _pdfColor(String? value) {
    final source = value?.trim().replaceFirst('#', '') ?? '';
    if (source.length != 6) return null;
    final color = int.tryParse(source, radix: 16);
    if (color == null) return null;
    return PdfColor(
      ((color >> 16) & 0xff) / 255,
      ((color >> 8) & 0xff) / 255,
      (color & 0xff) / 255,
    );
  }

  static Future<pw.Widget> _tableCell(
    String value,
    pw.TextAlign align,
    bool bold,
    double flex,
  ) async {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2.5),
      child: pw.Align(
        alignment: switch (align) {
          pw.TextAlign.right => pw.Alignment.centerRight,
          pw.TextAlign.center => pw.Alignment.center,
          _ => pw.Alignment.centerLeft,
        },
        child: await ReceiptRasterText.create(
          value,
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          textAlign: align,
          maxWidth: 75 * flex,
        ),
      ),
    );
  }

  static Future<pw.Widget> _productNameCell(
    SaleProduct product,
    double flex, {
    required bool showFree,
    required bool showReturn,
    required bool showSplit,
  }) async {
    final details = <String>[
      if (showFree && product.freeQuantity > 0)
        'ថែម ${_quantityWithUnit(product.freeQuantity, product.unit)}',
      if (showReturn && product.returnQuantity > 0)
        'សល់មកវិញ៖ ${_quantityWithUnit(product.returnQuantity, product.unit)}',
      if (showSplit && product.splitQuantity > 0)
        'ចំនួនបំបែក៖ ${_quantityWithUnit(product.splitQuantity, product.unit)}',
    ];
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2.5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          await ReceiptRasterText.create(
            product.productName,
            fontSize: 8,
            maxWidth: 75 * flex,
          ),
          if (details.isNotEmpty)
            await ReceiptRasterText.create(
              details.join('\n'),
              fontSize: 6.5,
              maxWidth: 75 * flex,
            ),
        ],
      ),
    );
  }

  static String _quantityWithUnit(double quantity, String unit) => [
    formatQuantity(quantity),
    if (unit.trim().isNotEmpty) unit.trim(),
  ].join(' ');

  static Future<pw.Widget> _totals(
    Sale sale,
    AppSetting business,
    ReceiptBlock block,
    double contentWidth,
  ) async {
    final symbol = business.currencySymbol.trim();
    final amount = sale.canShowPrice
        ? [
            formatMoney(sale.totalAmount),
            if (symbol.isNotEmpty) symbol,
          ].join(' ')
        : '***';
    final width = block.widthMm == null
        ? contentWidth.clamp(120.0, 190.0)
        : block.widthMm! * PdfPageFormat.mm;
    return pw.Align(
      alignment: _alignment(
        block.alignment == 'left' ? 'right' : block.alignment,
      ),
      child: pw.SizedBox(
        width: width,
        child: pw.Table(
          border: pw.TableBorder.all(width: 0.45),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            await _totalRow(
              'ចំនួនសរុប៖',
              formatQuantity(sale.totalSaleQuantity),
            ),
            await _totalRow('សរុប៖', amount, bold: true),
          ],
        ),
      ),
    );
  }

  static Future<pw.TableRow> _totalRow(
    String label,
    String value, {
    bool bold = false,
  }) async {
    final weight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: await ReceiptRasterText.create(
            label,
            fontSize: bold ? 10 : 9,
            fontWeight: weight,
            maxWidth: 85,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: await ReceiptRasterText.create(
              value,
              fontSize: bold ? 10 : 9,
              fontWeight: weight,
              textAlign: pw.TextAlign.right,
              maxWidth: 85,
            ),
          ),
        ),
      ],
    );
  }

  static Future<pw.Widget> _signature(
    String label,
    String value,
    double width, {
    required double lineInset,
  }) async {
    return pw.SizedBox(
      width: width,
      height: 62,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: lineInset),
            child: pw.Container(
              height: 30,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.45)),
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          await ReceiptRasterText.create(
            label,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.center,
            maxWidth: width,
          ),
          await ReceiptRasterText.create(
            value.trim().isEmpty ? '-' : value.trim(),
            fontSize: 7,
            textAlign: pw.TextAlign.center,
            maxWidth: width,
          ),
        ],
      ),
    );
  }

  static List<_ProductColumn> _productColumns(ReceiptBlock block) {
    final rawColumns = block.properties['columns'];
    if (rawColumns is List) {
      final parsed = rawColumns
          .whereType<Map>()
          .where((item) {
            final visible = item['visible'];
            return visible == null || visible == true || visible == 1;
          })
          .map((item) {
            final json = Map<String, dynamic>.from(item);
            return _ProductColumn(
              json['key']?.toString() ?? 'product_name',
              json['label']?.toString() ?? '',
              (json['width'] as num?)?.toDouble() ?? 1,
              _textAlign(json['alignment']?.toString() ?? 'left'),
            );
          })
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return const [
      _ProductColumn('index', 'ល.រ', 0.5, pw.TextAlign.center),
      _ProductColumn('product_name', 'ឈ្មោះទំនិញ', 2.8, pw.TextAlign.left),
      _ProductColumn('quantity', 'ចំនួន', 1.1, pw.TextAlign.center),
      _ProductColumn('price', 'តម្លៃ', 1.25, pw.TextAlign.right),
      _ProductColumn('amount', 'សរុប', 1.4, pw.TextAlign.right),
    ];
  }

  static String _productValue(
    String key,
    int index,
    SaleProduct product,
    bool showPrice,
  ) {
    if (key == 'index') return '${index + 1}';
    if (key == 'quantity') {
      return '${formatQuantity(product.totalSaleQuantity)} ${product.unit}';
    }

    const moneyFields = {
      'price',
      'product_price',
      'sub_total',
      'amount',
      'total_amount',
      'cost',
      'total_cost',
    };
    if (!showPrice && moneyFields.contains(key)) return '***';

    final data = product.toJson();
    final sourceKey = key == 'amount' ? 'total_amount' : key;
    final value = data[sourceKey];
    if (value == null) return '';
    if (moneyFields.contains(key)) return formatMoney(value);
    if (value is num) return formatQuantity(value.toDouble());
    return value.toString();
  }

  static bool _fieldEnabled(ReceiptBlock block, String field) {
    final fields = block.properties['fields'];
    if (fields is! List) return true;
    return fields.map((value) => value.toString()).contains(field);
  }

  static bool _isBlockVisible(
    ReceiptBlock block,
    Sale sale,
    AppSetting business,
    String seller, {
    ReceiptTemplate? template,
  }) {
    if (!block.visible) return false;
    var condition = block.showIf.trim();
    if (condition.isEmpty) return true;
    final inverted = condition.startsWith('!');
    if (inverted) condition = condition.substring(1).trim();
    final value = _resolveRawField(
      condition,
      sale,
      business,
      seller,
      template: template,
    );
    final truthy = switch (value) {
      null => false,
      bool flag => flag,
      num number => number != 0,
      _ => !const {
        '',
        '0',
        'false',
        'no',
        'null',
      }.contains(value.toString().trim().toLowerCase()),
    };
    return inverted ? !truthy : truthy;
  }

  static String _resolveTokens(
    String source,
    Sale sale,
    AppSetting business,
    String seller, {
    ReceiptTemplate? template,
  }) {
    return source.replaceAllMapped(
      RegExp(r'\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}'),
      (match) => _resolveField(
        match.group(1) ?? '',
        sale,
        business,
        seller,
        template: template,
      ),
    );
  }

  static String _resolveField(
    String fieldname,
    Sale sale,
    AppSetting business,
    String seller, {
    ReceiptTemplate? template,
  }) {
    final value = _resolveRawField(
      fieldname,
      sale,
      business,
      seller,
      template: template,
    );
    if (value == null) return '';
    final key = fieldname.split('.').last;
    if (key == 'posting_date') return _formatDate(sale.postingDate);
    if (key == 'total_amount' || key == 'balance') {
      return value is num ? formatMoney(value.toDouble()) : value.toString();
    }
    if (key.contains('quantity') && value is num) {
      return formatQuantity(value.toDouble());
    }
    return value.toString().trim();
  }

  static Object? _resolveRawField(
    String fieldname,
    Sale sale,
    AppSetting business,
    String seller, {
    ReceiptTemplate? template,
  }) {
    final key = fieldname.trim();
    if (key.isEmpty) return null;
    final saleData = <String, dynamic>{
      ...sale.toJson(),
      'invoice_number': sale.name,
      'total_quantity': sale.totalSaleQuantity,
    };
    final settingData = <String, dynamic>{
      ...business.raw,
      'business_name_en': business.businessNameEn,
      'business_name_kh': business.businessNameKh,
      'business_address': business.address,
      'business_phone': business.phoneNumber1,
      'address': business.address,
      'phone_number_1': business.phoneNumber1,
      'currency_symbol': business.currencySymbol,
    };
    if (key == 'seller') return seller;
    if (key.startsWith('sale.')) return saleData[key.substring(5)];
    if (key.startsWith('setting.')) return settingData[key.substring(8)];
    if (key.startsWith('business.')) return settingData[key.substring(9)];
    if (key.startsWith('print_template.')) {
      return template?.raw[key.substring('print_template.'.length)];
    }
    if (key.startsWith('template.')) {
      return template?.raw[key.substring(9)];
    }
    return saleData[key] ?? settingData[key] ?? template?.raw[key];
  }

  static pw.Alignment _alignment(String value) => switch (value.toLowerCase()) {
    'center' => pw.Alignment.center,
    'right' => pw.Alignment.centerRight,
    _ => pw.Alignment.centerLeft,
  };

  static pw.TextAlign _textAlign(String value) => switch (value.toLowerCase()) {
    'center' => pw.TextAlign.center,
    'right' => pw.TextAlign.right,
    _ => pw.TextAlign.left,
  };

  static String _formatDate(DateTime? value) {
    if (value == null) return '';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _formatDateValue(Object? value) {
    if (value == null) return '';
    if (value is DateTime) return _formatDate(value);
    final source = value.toString().trim();
    if (source.isEmpty) return '';
    final parsed = DateTime.tryParse(source);
    return parsed == null ? source : _formatDate(parsed);
  }
}

class _ProductColumn {
  const _ProductColumn(this.key, this.label, this.width, this.align);

  final String key;
  final String label;
  final double width;
  final pw.TextAlign align;
}

class _AbsoluteBlockRender {
  const _AbsoluteBlockRender(this.block, this.widget);

  final ReceiptBlock block;
  final pw.Widget widget;
}
