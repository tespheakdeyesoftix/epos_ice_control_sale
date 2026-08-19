import 'dart:convert';

import 'package:pdf/pdf.dart';

enum ReceiptPageSize {
  a6('A6'),
  a5('A5'),
  a4('A4');

  const ReceiptPageSize(this.label);

  final String label;

  PdfPageFormat get format => switch (this) {
    ReceiptPageSize.a6 => PdfPageFormat.a6,
    ReceiptPageSize.a5 => PdfPageFormat.a5,
    ReceiptPageSize.a4 => PdfPageFormat.a4,
  };

  static ReceiptPageSize parse(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return values.firstWhere(
      (item) => item.label == normalized,
      orElse: () => ReceiptPageSize.a6,
    );
  }
}

enum ReceiptOrientation {
  portrait('Portrait'),
  landscape('Landscape');

  const ReceiptOrientation(this.label);

  final String label;

  static ReceiptOrientation parse(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'landscape' ? landscape : portrait;
  }
}

enum ReceiptPositionMode {
  flow('flow'),
  absolute('absolute');

  const ReceiptPositionMode(this.key);
  final String key;

  static ReceiptPositionMode parse(Object? value) =>
      value?.toString().trim().toLowerCase() == absolute.key ? absolute : flow;
}

enum ReceiptPageRepeat {
  firstPage('first_page'),
  everyPage('every_page'),
  lastPage('last_page');

  const ReceiptPageRepeat(this.key);
  final String key;

  static ReceiptPageRepeat parse(Object? value) {
    final key = value?.toString().trim().toLowerCase();
    return values.firstWhere(
      (item) => item.key == key,
      orElse: () => firstPage,
    );
  }
}

enum ReceiptBlockOverflow {
  clip('clip'),
  shrink('shrink'),
  wrap('wrap');

  const ReceiptBlockOverflow(this.key);
  final String key;

  static ReceiptBlockOverflow parse(Object? value) {
    final key = value?.toString().trim().toLowerCase();
    return values.firstWhere((item) => item.key == key, orElse: () => clip);
  }
}

class ReceiptInsetsMm {
  const ReceiptInsetsMm(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  static ReceiptInsetsMm? tryParse(Object? value) {
    if (value == null) return null;
    if (value is num) {
      final amount = value.toDouble();
      return ReceiptInsetsMm(amount, amount, amount, amount);
    }
    final parts = value is List
        ? value
        : value
              .toString()
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .toList();
    final numbers = parts.map(_nullableDouble).toList();
    if (numbers.any((number) => number == null)) return null;
    if (numbers.length == 1) {
      final amount = numbers.single!;
      return ReceiptInsetsMm(amount, amount, amount, amount);
    }
    if (numbers.length != 4) return null;
    return ReceiptInsetsMm(numbers[0]!, numbers[1]!, numbers[2]!, numbers[3]!);
  }

  bool get isNegative => left < 0 || top < 0 || right < 0 || bottom < 0;

  String toJsonValue() => [left, top, right, bottom].map(_number).join(' ');
}

enum ReceiptBlockType {
  row('row', 'Row'),
  column('column', 'Column'),
  container('container', 'Container'),
  image('image', 'Image'),
  text('text', 'Text'),
  date('date', 'Date'),
  customerInfo('customer_info', 'Customer information'),
  table('table', 'Table'),
  productTable('product_table', 'Product table'),
  totals('totals', 'Summary totals'),
  barcode('barcode', 'Barcode'),
  notes('notes', 'Reference and notes'),
  signatures('signatures', 'Signatures'),
  divider('divider', 'Divider'),
  spacer('spacer', 'Spacer');

  const ReceiptBlockType(this.key, this.label);

  final String key;
  final String label;

  static ReceiptBlockType parse(Object? value) {
    final key = value?.toString().trim();
    return values.firstWhere((item) => item.key == key, orElse: () => text);
  }
}

class ReceiptBlock {
  const ReceiptBlock({
    required this.id,
    required this.type,
    this.visible = true,
    this.alignment = 'left',
    this.fontSize = 9,
    this.bold = false,
    this.position = ReceiptPositionMode.flow,
    this.xMm,
    this.yMm,
    this.widthMm,
    this.heightMm,
    this.zIndex = 0,
    this.repeat = ReceiptPageRepeat.firstPage,
    this.overflow = ReceiptBlockOverflow.clip,
    this.flex = 1,
    this.gapMm = 0,
    this.paddingMm = 0,
    this.margin,
    this.padding,
    this.spacingBefore = 0,
    this.spacingAfter = 4,
    this.showIf = '',
    this.fieldname = '',
    this.label = '',
    this.text = '',
    this.properties = const <String, dynamic>{},
    this.child,
    this.children = const <ReceiptBlock>[],
  });

  factory ReceiptBlock.fromJson(Map<String, dynamic> json) {
    return ReceiptBlock(
      id: _text(json['id']).isEmpty
          ? '${_text(json['type'])}_${DateTime.now().microsecondsSinceEpoch}'
          : _text(json['id']),
      type: ReceiptBlockType.parse(json['type']),
      visible: _bool(json['visible'], fallback: true),
      alignment: _text(json['alignment']).isEmpty
          ? 'left'
          : _text(json['alignment']),
      fontSize: _double(json['font_size'], fallback: 9),
      bold: _bool(json['bold']),
      position: ReceiptPositionMode.parse(json['position']),
      xMm: _nullableDouble(json['x_mm']),
      yMm: _nullableDouble(json['y_mm']),
      widthMm: _nullableDouble(json['width_mm']),
      heightMm: _nullableDouble(json['height_mm']),
      zIndex: _int(json['z_index'], fallback: 0),
      repeat: ReceiptPageRepeat.parse(json['repeat']),
      overflow: ReceiptBlockOverflow.parse(json['overflow']),
      flex: _double(json['flex'], fallback: 1),
      gapMm: _double(json['gap_mm'], fallback: 0),
      paddingMm: _double(json['padding_mm'], fallback: 0),
      margin: ReceiptInsetsMm.tryParse(json['margin']),
      padding: ReceiptInsetsMm.tryParse(json['padding']),
      spacingBefore: _double(json['spacing_before'], fallback: 0),
      spacingAfter: _double(json['spacing_after'], fallback: 4),
      showIf: _text(json['show_if']),
      fieldname: _text(json['fieldname']),
      label: _text(json['label']),
      text: _text(json['text']),
      properties: Map<String, dynamic>.unmodifiable(
        json['properties'] is Map
            ? Map<String, dynamic>.from(json['properties'] as Map)
            : const <String, dynamic>{},
      ),
      child: json['child'] is Map
          ? ReceiptBlock.fromJson(
              Map<String, dynamic>.from(json['child'] as Map),
            )
          : null,
      children: json['children'] is List
          ? List<ReceiptBlock>.unmodifiable(
              (json['children'] as List).whereType<Map>().map(
                (item) =>
                    ReceiptBlock.fromJson(Map<String, dynamic>.from(item)),
              ),
            )
          : const <ReceiptBlock>[],
    );
  }

  final String id;
  final ReceiptBlockType type;
  final bool visible;
  final String alignment;
  final double fontSize;
  final bool bold;
  final ReceiptPositionMode position;
  final double? xMm;
  final double? yMm;
  final double? widthMm;
  final double? heightMm;
  final int zIndex;
  final ReceiptPageRepeat repeat;
  final ReceiptBlockOverflow overflow;
  final double flex;
  final double gapMm;
  final double paddingMm;
  final ReceiptInsetsMm? margin;
  final ReceiptInsetsMm? padding;
  final double spacingBefore;
  final double spacingAfter;
  final String showIf;
  final String fieldname;
  final String label;
  final String text;
  final Map<String, dynamic> properties;
  final ReceiptBlock? child;
  final List<ReceiptBlock> children;

  ReceiptInsetsMm get resolvedMargin =>
      margin ?? const ReceiptInsetsMm(0, 0, 0, 0);

  ReceiptInsetsMm get resolvedPadding =>
      padding ?? ReceiptInsetsMm(paddingMm, paddingMm, paddingMm, paddingMm);

  ReceiptBlock copyWith({
    String? id,
    ReceiptBlockType? type,
    bool? visible,
    String? alignment,
    double? fontSize,
    bool? bold,
    ReceiptPositionMode? position,
    double? xMm,
    double? yMm,
    double? widthMm,
    double? heightMm,
    int? zIndex,
    ReceiptPageRepeat? repeat,
    ReceiptBlockOverflow? overflow,
    double? flex,
    double? gapMm,
    double? paddingMm,
    ReceiptInsetsMm? margin,
    ReceiptInsetsMm? padding,
    double? spacingBefore,
    double? spacingAfter,
    String? showIf,
    String? fieldname,
    String? label,
    String? text,
    Map<String, dynamic>? properties,
    ReceiptBlock? child,
    List<ReceiptBlock>? children,
  }) {
    return ReceiptBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      visible: visible ?? this.visible,
      alignment: alignment ?? this.alignment,
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      position: position ?? this.position,
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      zIndex: zIndex ?? this.zIndex,
      repeat: repeat ?? this.repeat,
      overflow: overflow ?? this.overflow,
      flex: flex ?? this.flex,
      gapMm: gapMm ?? this.gapMm,
      paddingMm: paddingMm ?? this.paddingMm,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      spacingBefore: spacingBefore ?? this.spacingBefore,
      spacingAfter: spacingAfter ?? this.spacingAfter,
      showIf: showIf ?? this.showIf,
      fieldname: fieldname ?? this.fieldname,
      label: label ?? this.label,
      text: text ?? this.text,
      properties: properties ?? this.properties,
      child: child ?? this.child,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.key,
    'visible': visible,
    'alignment': alignment,
    'font_size': fontSize,
    'bold': bold,
    'position': position.key,
    if (xMm != null) 'x_mm': xMm,
    if (yMm != null) 'y_mm': yMm,
    if (widthMm != null) 'width_mm': widthMm,
    if (heightMm != null) 'height_mm': heightMm,
    if (position == ReceiptPositionMode.absolute) 'z_index': zIndex,
    if (position == ReceiptPositionMode.absolute) 'repeat': repeat.key,
    if (position == ReceiptPositionMode.absolute) 'overflow': overflow.key,
    if (flex != 1) 'flex': flex,
    if (gapMm != 0) 'gap_mm': gapMm,
    if (paddingMm != 0) 'padding_mm': paddingMm,
    if (margin != null) 'margin': margin!.toJsonValue(),
    if (padding != null) 'padding': padding!.toJsonValue(),
    if (spacingBefore != 0) 'spacing_before': spacingBefore,
    'spacing_after': spacingAfter,
    if (showIf.isNotEmpty) 'show_if': showIf,
    if (fieldname.isNotEmpty) 'fieldname': fieldname,
    if (label.isNotEmpty) 'label': label,
    if (text.isNotEmpty) 'text': text,
    if (properties.isNotEmpty) 'properties': properties,
    if (child != null) 'child': child!.toJson(),
    if (children.isNotEmpty)
      'children': children.map((item) => item.toJson()).toList(growable: false),
  };
}

class ReceiptTemplate {
  const ReceiptTemplate({
    required this.name,
    required this.templateName,
    required this.pageSize,
    required this.orientation,
    required this.blocks,
    this.description = '',
    this.templateLogo = '',
    this.schemaVersion = 1,
    this.marginMm = 5,
    this.enabled = true,
    this.isBuiltIn = false,
    this.raw = const <String, dynamic>{},
  });

  factory ReceiptTemplate.fromJson(Map<String, dynamic> json) {
    dynamic layout = json['layout_json'];
    if (layout is String && layout.trim().isNotEmpty) {
      try {
        layout = jsonDecode(layout);
      } on FormatException {
        layout = const <String, dynamic>{};
      }
    }
    final layoutMap = layout is Map
        ? Map<String, dynamic>.from(layout)
        : const <String, dynamic>{};
    final rawBlocks = layoutMap['blocks'];
    final blocks = <ReceiptBlock>[];
    if (rawBlocks is List) {
      for (var index = 0; index < rawBlocks.length; index++) {
        final item = rawBlocks[index];
        if (item is! Map) {
          throw FormatException('blocks[$index] must be a JSON object.');
        }
        final blockJson = _normalizeBlockJson(Map<String, dynamic>.from(item));
        _validateBlockJson(blockJson, 'blocks[$index]', 0);
        blocks.add(ReceiptBlock.fromJson(blockJson));
      }
    }
    final templateName = _text(json['template_name']);
    final page = layoutMap['page'] is Map
        ? Map<String, dynamic>.from(layoutMap['page'] as Map)
        : const <String, dynamic>{};
    final pageSize = ReceiptPageSize.parse(page['size'] ?? json['paper_size']);
    return ReceiptTemplate(
      name: _text(json['name']).isEmpty ? templateName : _text(json['name']),
      templateName: templateName,
      description: _text(json['description']),
      pageSize: pageSize,
      orientation: ReceiptOrientation.parse(
        page['orientation'] ?? json['orientation'],
      ),
      templateLogo: _text(json['template_logo']),
      schemaVersion: _int(json['schema_version'], fallback: 1),
      marginMm: _double(
        page['margin_mm'],
        fallback: pageSize == ReceiptPageSize.a6 ? 5 : 10,
      ),
      enabled: _bool(json['enabled'], fallback: true),
      blocks: blocks.isEmpty ? standardA6.blocks : List.unmodifiable(blocks),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  final String name;
  final String templateName;
  final String description;
  final ReceiptPageSize pageSize;
  final ReceiptOrientation orientation;
  final String templateLogo;
  final int schemaVersion;
  final double marginMm;
  final bool enabled;
  final bool isBuiltIn;
  final List<ReceiptBlock> blocks;
  final Map<String, dynamic> raw;

  PdfPageFormat get pageFormat {
    final format = pageSize.format;
    return orientation == ReceiptOrientation.landscape
        ? format.landscape
        : format;
  }

  ReceiptTemplate copyWith({
    String? name,
    String? templateName,
    String? description,
    ReceiptPageSize? pageSize,
    ReceiptOrientation? orientation,
    String? templateLogo,
    int? schemaVersion,
    double? marginMm,
    bool? enabled,
    bool? isBuiltIn,
    List<ReceiptBlock>? blocks,
    Map<String, dynamic>? raw,
  }) {
    return ReceiptTemplate(
      name: name ?? this.name,
      templateName: templateName ?? this.templateName,
      description: description ?? this.description,
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      templateLogo: templateLogo ?? this.templateLogo,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      marginMm: marginMm ?? this.marginMm,
      enabled: enabled ?? this.enabled,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      blocks: blocks ?? this.blocks,
      raw: raw ?? this.raw,
    );
  }

  Map<String, dynamic> toFrappeJson() => {
    'doctype': 'POS Print Template',
    'template_name': templateName,
    'description': description,
    'paper_size': pageSize.label,
    'orientation': orientation.label,
    'template_logo': templateLogo,
    'schema_version': schemaVersion,
    'enabled': enabled ? 1 : 0,
    'layout_json': toLayoutJson(),
  };

  Map<String, dynamic> toLayoutJson() => {
    'version': schemaVersion,
    'page': {
      'size': pageSize.label,
      'orientation': orientation.label,
      'margin_mm': marginMm,
    },
    'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
  };

  ReceiptTemplate applyLayoutJson(Map<String, dynamic> layout) {
    final rawBlocks = layout['blocks'];
    if (rawBlocks is! List) {
      throw const FormatException('"blocks" must be a JSON array.');
    }
    if (rawBlocks.isEmpty) {
      throw const FormatException('"blocks" must contain at least one block.');
    }
    final page = layout['page'];
    if (page != null && page is! Map) {
      throw const FormatException('"page" must be a JSON object.');
    }
    final pageMap = page is Map
        ? Map<String, dynamic>.from(page)
        : const <String, dynamic>{};
    final sizeValue = pageMap['size']?.toString().trim().toUpperCase();
    if (sizeValue != null &&
        !ReceiptPageSize.values.any((size) => size.label == sizeValue)) {
      throw const FormatException('page.size must be A6, A5 or A4.');
    }
    final orientationValue = pageMap['orientation']
        ?.toString()
        .trim()
        .toLowerCase();
    if (orientationValue != null &&
        orientationValue != 'portrait' &&
        orientationValue != 'landscape') {
      throw const FormatException(
        'page.orientation must be Portrait or Landscape.',
      );
    }
    if (pageMap.containsKey('margin_mm') &&
        _nullableDouble(pageMap['margin_mm']) == null) {
      throw const FormatException('page.margin_mm must be a number.');
    }
    final parsedBlocks = <ReceiptBlock>[];
    for (var index = 0; index < rawBlocks.length; index++) {
      final item = rawBlocks[index];
      if (item is! Map) {
        throw FormatException('blocks[$index] must be a JSON object.');
      }
      final json = _normalizeBlockJson(Map<String, dynamic>.from(item));
      _validateBlockJson(json, 'blocks[$index]', 0);
      parsedBlocks.add(ReceiptBlock.fromJson(json));
    }
    final result = copyWith(
      schemaVersion: _int(layout['version'], fallback: schemaVersion),
      pageSize: ReceiptPageSize.parse(pageMap['size'] ?? pageSize.label),
      orientation: ReceiptOrientation.parse(
        pageMap['orientation'] ?? orientation.label,
      ),
      marginMm: _double(pageMap['margin_mm'], fallback: marginMm),
      blocks: parsedBlocks,
    );
    final errors = result.layoutErrors();
    if (errors.isNotEmpty) throw FormatException(errors.first);
    return result;
  }

  List<String> layoutErrors() {
    final errors = <String>[];
    if (marginMm < 0) errors.add('page.margin_mm cannot be negative.');
    final printableWidth = pageFormat.width / PdfPageFormat.mm - marginMm * 2;
    final printableHeight = pageFormat.height / PdfPageFormat.mm - marginMm * 2;
    if (printableWidth <= 0 || printableHeight <= 0) {
      errors.add('The page margin leaves no printable area.');
      return errors;
    }
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      _validateBlockLayout(
        block,
        'blocks[$index]',
        isTopLevel: true,
        printableWidth: printableWidth,
        printableHeight: printableHeight,
        errors: errors,
      );
    }
    return errors;
  }

  List<String> layoutWarnings() {
    final warnings = <String>[];
    final absolute = blocks
        .where(
          (block) =>
              block.visible &&
              block.position == ReceiptPositionMode.absolute &&
              block.xMm != null &&
              block.yMm != null &&
              block.widthMm != null &&
              block.heightMm != null,
        )
        .toList();
    for (var i = 0; i < absolute.length; i++) {
      for (var j = i + 1; j < absolute.length; j++) {
        final a = absolute[i];
        final b = absolute[j];
        final repeatsCanMeet =
            a.repeat == b.repeat ||
            a.repeat == ReceiptPageRepeat.everyPage ||
            b.repeat == ReceiptPageRepeat.everyPage;
        if (repeatsCanMeet && _overlaps(a, b)) {
          warnings.add(
            '${a.id} overlaps ${b.id}; z_index controls which one is on top.',
          );
        }
      }
    }
    return warnings;
  }

  static const standardA6 = ReceiptTemplate(
    name: 'Standard A6',
    templateName: 'Standard A6',
    pageSize: ReceiptPageSize.a6,
    orientation: ReceiptOrientation.portrait,
    isBuiltIn: true,
    blocks: [
      ReceiptBlock(
        id: 'business_name_kh',
        type: ReceiptBlockType.text,
        fieldname: 'business_name_kh',
        alignment: 'center',
        fontSize: 15,
        bold: true,
        spacingAfter: 2,
      ),
      ReceiptBlock(
        id: 'business_name_en',
        type: ReceiptBlockType.text,
        fieldname: 'business_name_en',
        alignment: 'center',
        fontSize: 13,
        bold: true,
        spacingAfter: 2,
      ),
      ReceiptBlock(
        id: 'title',
        type: ReceiptBlockType.text,
        text: 'INVOICE',
        alignment: 'center',
        fontSize: 16,
        bold: true,
      ),
      ReceiptBlock(
        id: 'address',
        type: ReceiptBlockType.text,
        fieldname: 'address',
      ),
      ReceiptBlock(
        id: 'sale_info_row',
        type: ReceiptBlockType.row,
        children: [
          ReceiptBlock(
            id: 'invoice_number',
            type: ReceiptBlockType.text,
            fieldname: 'name',
            label: 'Invoice: ',
          ),
          ReceiptBlock(
            id: 'posting_date',
            type: ReceiptBlockType.text,
            fieldname: 'posting_date',
            label: 'Date: ',
            alignment: 'right',
          ),
        ],
      ),
      ReceiptBlock(
        id: 'customer',
        type: ReceiptBlockType.text,
        fieldname: 'customer_name',
        label: 'Customer: ',
      ),
      ReceiptBlock(id: 'product_table', type: ReceiptBlockType.productTable),
      ReceiptBlock(id: 'barcode', type: ReceiptBlockType.barcode),
      ReceiptBlock(id: 'totals', type: ReceiptBlockType.totals),
      ReceiptBlock(id: 'notes', type: ReceiptBlockType.notes),
      ReceiptBlock(id: 'signatures', type: ReceiptBlockType.signatures),
    ],
  );
}

Map<String, dynamic> _normalizeBlockJson(Map<String, dynamic> source) {
  final json = Map<String, dynamic>.from(source);
  switch (_text(json['type'])) {
    case 'template_logo':
      json['type'] = 'image';
      json['fieldname'] = _text(json['fieldname']).isEmpty
          ? 'template_logo'
          : json['fieldname'];
    case 'business_name':
      json['type'] = 'text';
      json['text'] = _text(json['text']).isEmpty
          ? '{{business_name_kh}}\n{{business_name_en}}'
          : json['text'];
    case 'invoice_title':
      json['type'] = 'text';
      json['text'] = _text(json['text']).isEmpty ? 'INVOICE' : json['text'];
    case 'business_contact':
      json['type'] = 'text';
      json['text'] = _text(json['text']).isEmpty
          ? '{{address}}  {{phone_number_1}}'
          : json['text'];
    case 'sale_info':
      json['type'] = 'text';
      json['text'] = _text(json['text']).isEmpty
          ? '{{name}}  {{posting_date}}  {{seller}}  {{station}}'
          : json['text'];
    case 'token_text':
      json['type'] = 'text';
  }
  if (_text(json['type']) == 'table') {
    final properties = json['properties'] is Map
        ? Map<String, dynamic>.from(json['properties'] as Map)
        : <String, dynamic>{};
    for (final key in const [
      'source',
      'header',
      'border',
      'header_bold',
      'repeat_header',
      'cell_padding',
      'border_width',
      'column_widths',
      'rows',
      'columns',
    ]) {
      if (json.containsKey(key)) properties[key] = json.remove(key);
    }
    if (properties.isNotEmpty) json['properties'] = properties;
  }
  final child = json['child'];
  if (child is Map) {
    json['child'] = _normalizeBlockJson(Map<String, dynamic>.from(child));
  }
  final children = json['children'];
  if (children is List) {
    json['children'] = [
      for (final item in children)
        if (item is Map)
          _normalizeBlockJson(Map<String, dynamic>.from(item))
        else
          item,
    ];
  }
  return json;
}

void _validateBlockJson(Map<String, dynamic> json, String path, int depth) {
  if (depth > 12) {
    throw FormatException('$path exceeds the maximum nesting depth of 12.');
  }
  final knownTypes = ReceiptBlockType.values.map((type) => type.key).toSet();
  if (!knownTypes.contains(_text(json['type']))) {
    throw FormatException('$path has an unknown type.');
  }
  if (_text(json['type']) == ReceiptBlockType.table.key) {
    final properties = json['properties'];
    if (properties is! Map) {
      throw FormatException('$path.table requires rows or source/columns.');
    }
    final source = _text(properties['source']);
    final rows = properties['rows'];
    final columns = properties['columns'];
    if (source.isEmpty && rows is! List) {
      throw FormatException('$path.table requires rows or source.');
    }
    if (source.isNotEmpty && columns is! List) {
      throw FormatException('$path.table with source requires columns.');
    }
    if (rows != null && rows is! List) {
      throw FormatException('$path.table rows must be a JSON array.');
    }
    if (columns != null && columns is! List) {
      throw FormatException('$path.table columns must be a JSON array.');
    }
    if (columns is List) {
      for (var index = 0; index < columns.length; index++) {
        if (columns[index] is! Map) {
          throw FormatException(
            '$path.table columns[$index] must be a JSON object.',
          );
        }
      }
    }
    if (rows is List) {
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        if (row is! Map) {
          throw FormatException(
            '$path.table rows[$rowIndex] must be a JSON object.',
          );
        }
        final cells = row['cells'];
        if (cells is! List) {
          throw FormatException(
            '$path.table rows[$rowIndex].cells must be a JSON array.',
          );
        }
        for (var cellIndex = 0; cellIndex < cells.length; cellIndex++) {
          if (cells[cellIndex] is! Map) {
            throw FormatException(
              '$path.table rows[$rowIndex].cells[$cellIndex] must be a JSON object.',
            );
          }
        }
      }
    }
  }
  for (final property in const ['margin', 'padding']) {
    if (json.containsKey(property) &&
        ReceiptInsetsMm.tryParse(json[property]) == null) {
      throw FormatException(
        '$path.$property must contain 1 value or 4 values in left top right bottom order.',
      );
    }
  }
  final child = json['child'];
  if (child != null && child is! Map) {
    throw FormatException('$path.child must be a JSON object.');
  }
  if (child is Map) {
    _validateBlockJson(
      Map<String, dynamic>.from(child),
      '$path.child',
      depth + 1,
    );
  }
  final children = json['children'];
  if (children != null && children is! List) {
    throw FormatException('$path.children must be a JSON array.');
  }
  if (children is List) {
    for (var index = 0; index < children.length; index++) {
      final item = children[index];
      if (item is! Map) {
        throw FormatException('$path.children[$index] must be a JSON object.');
      }
      _validateBlockJson(
        Map<String, dynamic>.from(item),
        '$path.children[$index]',
        depth + 1,
      );
    }
  }
}

void _validateBlockLayout(
  ReceiptBlock block,
  String path, {
  required bool isTopLevel,
  required double printableWidth,
  required double printableHeight,
  required List<String> errors,
}) {
  final nested = [if (block.child != null) block.child!, ...block.children];
  final isLayout =
      block.type == ReceiptBlockType.row ||
      block.type == ReceiptBlockType.column ||
      block.type == ReceiptBlockType.container;
  if (isLayout && nested.isEmpty) {
    errors.add('$path: ${block.type.key} requires child or children.');
  }
  if (!isLayout && nested.isNotEmpty) {
    errors.add('$path: ${block.type.key} cannot contain child or children.');
  }
  if (block.type == ReceiptBlockType.image && block.fieldname.isEmpty) {
    errors.add('$path: image requires fieldname.');
  }
  if (block.type == ReceiptBlockType.text &&
      block.fieldname.isEmpty &&
      block.text.isEmpty) {
    errors.add('$path: text requires fieldname or text.');
  }
  if (block.type == ReceiptBlockType.date && block.fieldname.isEmpty) {
    errors.add('$path: date requires fieldname.');
  }
  if (!isTopLevel && block.position == ReceiptPositionMode.absolute) {
    errors.add('$path: only top-level blocks can use absolute positioning.');
  }
  final isDynamicTable =
      block.type == ReceiptBlockType.table &&
      _text(block.properties['source']).isNotEmpty;
  if ((block.type == ReceiptBlockType.productTable || isDynamicTable) &&
      (!isTopLevel || block.position != ReceiptPositionMode.flow)) {
    errors.add(
      '$path: dynamic table and product_table must be top-level flow blocks.',
    );
  }
  if (block.flex <= 0) errors.add('$path: flex must be positive.');
  if (block.gapMm < 0) errors.add('$path: gap_mm cannot be negative.');
  if (block.paddingMm < 0) errors.add('$path: padding_mm cannot be negative.');
  if (block.resolvedMargin.isNegative) {
    errors.add('$path: margin values cannot be negative.');
  }
  if (block.resolvedPadding.isNegative) {
    errors.add('$path: padding values cannot be negative.');
  }
  if (isTopLevel && block.position == ReceiptPositionMode.absolute) {
    if (block.xMm == null ||
        block.yMm == null ||
        block.widthMm == null ||
        block.heightMm == null) {
      errors.add(
        '$path: absolute blocks require x_mm, y_mm, width_mm and height_mm.',
      );
    } else {
      if (block.xMm! < 0 || block.yMm! < 0) {
        errors.add('$path: x_mm and y_mm cannot be negative.');
      }
      if (block.widthMm! <= 0 || block.heightMm! <= 0) {
        errors.add('$path: width_mm and height_mm must be positive.');
      }
      if (block.xMm! + block.widthMm! > printableWidth + 0.001 ||
          block.yMm! + block.heightMm! > printableHeight + 0.001) {
        errors.add('$path: absolute block is outside the printable area.');
      }
    }
  }
  for (var index = 0; index < nested.length; index++) {
    _validateBlockLayout(
      nested[index],
      block.child != null && index == 0
          ? '$path.child'
          : '$path.children[${index - (block.child == null ? 0 : 1)}]',
      isTopLevel: false,
      printableWidth: printableWidth,
      printableHeight: printableHeight,
      errors: errors,
    );
  }
}

bool _overlaps(ReceiptBlock a, ReceiptBlock b) =>
    a.xMm! < b.xMm! + b.widthMm! &&
    a.xMm! + a.widthMm! > b.xMm! &&
    a.yMm! < b.yMm! + b.heightMm! &&
    a.yMm! + a.heightMm! > b.yMm!;

String _text(Object? value) => value?.toString().trim() ?? '';

bool _bool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == 'yes') return true;
  if (normalized == 'false' || normalized == 'no') return false;
  final number = int.tryParse(normalized);
  return number == null ? fallback : number != 0;
}

double _double(Object? value, {required double fallback}) =>
    _nullableDouble(value) ?? fallback;

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int _int(Object? value, {required int fallback}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
