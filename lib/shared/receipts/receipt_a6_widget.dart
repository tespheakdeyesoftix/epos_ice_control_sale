import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/app_setting.dart';
import '../../features/sell/sale.dart';
import '../../features/sell/sale_product.dart';
import '../../utils/helpers.dart';
import 'receipt_raster_text.dart';

class ReceiptA6Widget {
  const ReceiptA6Widget._();

  static const pageFormat = PdfPageFormat.a6;
  static const _margin = 5 * PdfPageFormat.mm;

  static Future<Uint8List> buildPdf({
    required Sale sale,
    required AppSetting business,
    String sellerFallback = '',
    int copies = 1,
  }) async {
    final document = pw.Document(
      title: sale.name.isEmpty ? 'Invoice' : sale.name,
      author: business.businessNameEn,
      creator: 'Ice Control Sale',
    );
    final contentWidth = pageFormat.width - (_margin * 2);
    final contentHeight = pageFormat.height - (_margin * 2);
    final seller = sale.seller.trim().isNotEmpty
        ? sale.seller.trim()
        : sellerFallback.trim();
    for (var copy = 0; copy < copies.clamp(1, 3); copy++) {
      final receipt = await _receipt(
        sale: sale,
        business: business,
        seller: seller,
      );
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(_margin),
          build: (_) => pw.SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: receipt,
          ),
        ),
      );
    }
    return document.save();
  }

  static Future<pw.Widget> _receipt({
    required Sale sale,
    required AppSetting business,
    required String seller,
  }) async {
    final contentWidth = pageFormat.width - (_margin * 2);
    final contentHeight = pageFormat.height - (_margin * 2);
    final phone2 = business.raw['phone_number_2']?.toString().trim() ?? '';
    final phones = [
      business.phoneNumber1.trim(),
      phone2,
    ].where((value) => value.isNotEmpty).join(' / ');
    final body = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (business.businessNameKh.trim().isNotEmpty)
          pw.Center(
            child: await ReceiptRasterText.create(
              business.businessNameKh,
              textAlign: pw.TextAlign.center,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              maxWidth: contentWidth,
            ),
          ),
        if (business.businessNameEn.trim().isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Center(
            child: await ReceiptRasterText.create(
              business.businessNameEn,
              textAlign: pw.TextAlign.center,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              maxWidth: contentWidth,
            ),
          ),
        ],
        pw.SizedBox(height: 2),
        pw.Center(
          child: await ReceiptRasterText.create(
            'វិក្កយបត្រ',
            textAlign: pw.TextAlign.center,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            maxWidth: contentWidth,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (business.address.trim().isNotEmpty)
                    await ReceiptRasterText.create(
                      business.address,
                      fontSize: 8,
                      maxWidth: contentWidth * 0.54,
                    ),
                  if (phones.isNotEmpty)
                    await ReceiptRasterText.create(
                      'ទូរស័ព្ទ៖ $phones',
                      fontSize: 8,
                      maxWidth: contentWidth * 0.54,
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                await _infoText('លេខ៖', sale.name),
                await _infoText('កាលបរិច្ឆេទ៖', _formatDate(sale.postingDate)),
                await _infoText('អ្នកលក់៖', seller),
                await _infoText('ម៉ាស៊ីនលក់៖', sale.station),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        await _customerLine(sale),
        pw.SizedBox(height: 5),
        await _productTable(sale),
        pw.SizedBox(height: 4),
        await _barcodeAndTotals(sale, business),
        if (sale.referenceNumber.trim().isNotEmpty ||
            sale.note.trim().isNotEmpty) ...[
          pw.SizedBox(height: 5),
          if (sale.referenceNumber.trim().isNotEmpty)
            await ReceiptRasterText.create(
              'លេខយោង៖ ${sale.referenceNumber.trim()}',
              fontSize: 8,
              maxWidth: contentWidth,
            ),
          if (sale.note.trim().isNotEmpty)
            await ReceiptRasterText.create(
              'ចំណាំ៖ ${sale.note.trim()}',
              fontSize: 8,
              maxWidth: contentWidth,
            ),
        ],
      ],
    );
    final signature = await _signatureBlock(sale);
    return pw.Stack(
      children: [
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 84,
          child: pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.topCenter,
            child: pw.SizedBox(width: contentWidth, child: body),
          ),
        ),
        pw.Positioned(
          left: 0,
          right: 0,
          top: contentHeight - 78,
          bottom: 0,
          child: signature,
        ),
      ],
    );
  }

  static Future<pw.Widget> _customerLine(Sale sale) async {
    final identity = [
      sale.customer.trim(),
      sale.customerName.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');
    return ReceiptRasterText.create(
      [
        'លក់ជូន៖ ${identity.isEmpty ? '-' : identity}',
        if (sale.phoneNumber.trim().isNotEmpty)
          'ទូរស័ព្ទ៖ ${sale.phoneNumber.trim()}',
      ].join('  '),
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      maxWidth: pageFormat.width - (_margin * 2),
    );
  }

  static Future<pw.Widget> _productTable(Sale sale) async {
    const border = pw.TableBorder(
      top: pw.BorderSide(width: 0.5),
      bottom: pw.BorderSide(width: 0.5),
      left: pw.BorderSide(width: 0.5),
      right: pw.BorderSide(width: 0.5),
      horizontalInside: pw.BorderSide(width: 0.35),
      verticalInside: pw.BorderSide(width: 0.35),
    );
    final rows = <pw.TableRow>[];
    for (var index = 0; index < sale.saleProducts.length; index++) {
      rows.add(
        await _productRow(index, sale.saleProducts[index], sale.canShowPrice),
      );
    }
    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(2.8),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.25),
        4: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            await _cell('ល.រ', bold: true, align: pw.TextAlign.center),
            await _cell('ឈ្មោះទំនិញ', bold: true),
            await _cell('ចំនួន', bold: true, align: pw.TextAlign.center),
            await _cell('តម្លៃ', bold: true, align: pw.TextAlign.right),
            await _cell('សរុប', bold: true, align: pw.TextAlign.right),
          ],
        ),
        ...rows,
      ],
    );
  }

  static Future<pw.TableRow> _productRow(
    int index,
    SaleProduct product,
    bool showPrice,
  ) async {
    final details = <String>[
      if (product.freeQuantity > 0)
        'ថែម/Free៖ ${formatQuantity(product.freeQuantity)}',
      if (product.returnQuantity > 0)
        'សល់មកវិញ៖ ${formatQuantity(product.returnQuantity)}',
      if (product.note.trim().isNotEmpty) product.note.trim(),
    ];
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        await _cell('${index + 1}', align: pw.TextAlign.center),
        pw.Padding(
          padding: const pw.EdgeInsets.all(2.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              await ReceiptRasterText.create(
                product.productName,
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                maxWidth: 100,
              ),
              if (details.isNotEmpty)
                await ReceiptRasterText.create(
                  details.join(' | '),
                  fontSize: 6.5,
                  maxWidth: 100,
                ),
            ],
          ),
        ),
        await _cell(
          '${formatQuantity(product.totalSaleQuantity)} ${product.unit}',
          align: pw.TextAlign.center,
        ),
        await _cell(
          showPrice ? formatMoney(product.price) : '***',
          align: pw.TextAlign.right,
        ),
        await _cell(
          showPrice ? formatMoney(product.totalAmount) : '***',
          align: pw.TextAlign.right,
        ),
      ],
    );
  }

  static Future<pw.Widget> _totals(Sale sale, AppSetting business) async {
    final currencySymbol = business.currencySymbol.trim();
    final amount = sale.canShowPrice
        ? [
            formatMoney(sale.totalAmount),
            if (currencySymbol.isNotEmpty) currencySymbol,
          ].join(' ')
        : '***';
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 145,
        child: pw.Table(
          border: const pw.TableBorder(
            top: pw.BorderSide(width: 0.5),
            bottom: pw.BorderSide(width: 0.5),
            left: pw.BorderSide(width: 0.5),
            right: pw.BorderSide(width: 0.5),
            horizontalInside: pw.BorderSide(width: 0.35),
            verticalInside: pw.BorderSide(width: 0.35),
          ),
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
    final fontSize = bold ? 10.0 : 9.0;
    final fontWeight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: await ReceiptRasterText.create(
              label,
              fontSize: fontSize,
              fontWeight: fontWeight,
              textAlign: pw.TextAlign.left,
              maxWidth: 64,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: await ReceiptRasterText.create(
              value,
              fontSize: fontSize,
              fontWeight: fontWeight,
              textAlign: pw.TextAlign.right,
              maxWidth: 64,
            ),
          ),
        ),
      ],
    );
  }

  static Future<pw.Widget> _barcodeAndTotals(
    Sale sale,
    AppSetting business,
  ) async {
    final saleName = sale.name.trim();
    final totals = await _totals(sale, business);
    if (saleName.isEmpty) return totals;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 108,
          child: pw.Column(
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: saleName,
                width: 108,
                height: 24,
                drawText: false,
              ),
              pw.SizedBox(height: 2),
              await ReceiptRasterText.create(
                saleName,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
                maxWidth: 108,
              ),
            ],
          ),
        ),
        totals,
      ],
    );
  }

  static Future<pw.Widget> _cell(
    String value, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) async {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2.5),
      child: pw.Align(
        alignment: _alignmentFor(align),
        child: await ReceiptRasterText.create(
          value,
          textAlign: align,
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          maxWidth: 90,
        ),
      ),
    );
  }

  static Future<pw.Widget> _infoText(String label, String value) async {
    if (value.trim().isEmpty) return pw.SizedBox();
    return ReceiptRasterText.create(
      '$label ${value.trim()}',
      fontSize: 8,
      maxWidth: 115,
      textAlign: pw.TextAlign.right,
    );
  }

  static Future<pw.Widget> _signatureBlock(Sale sale) async {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        await _signatureColumn('អ្នកលក់', sale.seller.trim()),
        await _signatureColumn('អ្នកបើកបរ', sale.driverName.trim()),
        await _signatureColumn('អតិថិជន', sale.customerName.trim()),
      ],
    );
  }

  static Future<pw.Widget> _signatureColumn(String label, String value) async {
    return pw.SizedBox(
      width: 82,
      height: 78,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            height: 32,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 0.45, color: PdfColors.grey600),
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          await ReceiptRasterText.create(
            label,
            textAlign: pw.TextAlign.center,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            maxWidth: 82,
          ),
          await ReceiptRasterText.create(
            value.isEmpty ? '-' : value,
            textAlign: pw.TextAlign.center,
            fontSize: 7.5,
            maxWidth: 82,
          ),
        ],
      ),
    );
  }

  static pw.Alignment _alignmentFor(pw.TextAlign alignment) {
    return switch (alignment) {
      pw.TextAlign.center => pw.Alignment.center,
      pw.TextAlign.right || pw.TextAlign.end => pw.Alignment.centerRight,
      _ => pw.Alignment.centerLeft,
    };
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
