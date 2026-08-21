import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sale_service.dart';
import 'network_image.dart';

class SelectDataValue {
  const SelectDataValue({required this.name, required this.title});

  final String name;
  final String title;
}

Future<SelectDataValue?> showSelectDataDialog(
  BuildContext context, {
  required SaleService dataSource,
  required String doctype,
  String? label,
  List<List<dynamic>> filters = const [],
}) {
  return showDialog<SelectDataValue>(
    context: context,
    builder: (_) => SelectDataDialogWidget(
      dataSource: dataSource,
      doctype: doctype,
      label: label,
      filters: filters,
    ),
  );
}

class SelectDataDialogWidget extends StatefulWidget {
  const SelectDataDialogWidget({
    super.key,
    required this.dataSource,
    required this.doctype,
    this.label,
    this.filters = const [],
  });

  final SaleService dataSource;
  final String doctype;
  final String? label;
  final List<List<dynamic>> filters;

  @override
  State<SelectDataDialogWidget> createState() => _SelectDataDialogWidgetState();
}

class _SelectDataDialogWidgetState extends State<SelectDataDialogWidget> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _rows = <Map<String, dynamic>>[];
  Timer? _debounce;
  Map<String, dynamic>? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _reloadAfterLoad = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadMeta();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 180) _loadMore();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await widget.dataSource.getDoctypeMeta(widget.doctype);
      if (!mounted) return;
      _meta = _normalizeMeta(value);
      await _reload();
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'មិនអាចទាញទិន្នន័យបានទេ។';
      });
    }
  }

  Future<void> _reload() async {
    if (_loadingMore) {
      _reloadAfterLoad = true;
      return;
    }
    _rows.clear();
    _hasMore = true;
    _error = null;
    await _loadMore(initial: true);
  }

  Future<void> _loadMore({bool initial = false}) async {
    if (_meta == null || _loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      if (initial) _loading = true;
    });
    try {
      final titleField = _text(_meta!['title_field']);
      final imageField = _text(_meta!['image_field']);
      final searchFields = _searchFields(_meta!);
      final fields = <String>{
        'name',
        if (titleField.isNotEmpty) titleField,
        if (imageField.isNotEmpty) imageField,
        ...searchFields,
      }.toList(growable: false);
      final keyword = _searchController.text.trim();
      final rows = await widget.dataSource.getDoctypeRows(
        doctype: widget.doctype,
        fields: fields,
        filters: widget.filters,
        orFilters: keyword.isEmpty
            ? const []
            : [
                for (final field in <String>{
                  'name',
                  if (titleField.isNotEmpty) titleField,
                  ...searchFields,
                })
                  [field, 'like', '%$keyword%'],
              ],
        orderBy: '${titleField.isEmpty ? 'name' : titleField} asc',
        offset: _rows.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _rows.addAll(rows);
        _hasMore = rows.length == _pageSize;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _error = 'មិនអាចទាញទិន្នន័យបានទេ។');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
        if (_reloadAfterLoad) {
          _reloadAfterLoad = false;
          await _reload();
        }
      }
    }
  }

  void _searchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label ?? 'ជ្រើសរើស ${widget.doctype}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: TextField(
                key: const ValueKey('select-data-search'),
                controller: _searchController,
                autofocus: true,
                onChanged: _searchChanged,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរក...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _reload();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _loading && _rows.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _rows.isEmpty
                  ? _DataError(message: _error!, onRetry: _loadMeta)
                  : _rows.isEmpty
                  ? const Center(child: Text('រកមិនឃើញទិន្នន័យ'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _rows.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _rows.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final row = _rows[index];
                        final name = _text(row['name']);
                        final titleField = _text(_meta?['title_field']);
                        final title = _text(row[titleField]).isEmpty
                            ? name
                            : _text(row[titleField]);
                        final description = _searchFields(_meta!)
                            .where((field) => field != titleField)
                            .map((field) => _text(row[field]))
                            .where(
                              (value) => value.isNotEmpty && value != title,
                            )
                            .toSet()
                            .join(' • ');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _avatar(row, title, colors),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: description.isEmpty
                                ? (name == title ? null : Text(name))
                                : Text(description),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: name.isEmpty
                                ? null
                                : () => Navigator.pop(
                                    context,
                                    SelectDataValue(name: name, title: title),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> row, String title, ColorScheme colors) {
    final imageField = _text(_meta?['image_field']);
    final image = _text(row[imageField]);
    final imageUri = Uri.tryParse(image);
    final url = image.isEmpty
        ? ''
        : imageUri != null && imageUri.hasScheme
        ? image
        : widget.dataSource.baseUri.resolve(image).toString();
    return ClipOval(
      child: Container(
        width: 42,
        height: 42,
        color: colors.primaryContainer,
        child: url.isEmpty
            ? Center(
                child: Text(
                  title.isEmpty ? '?' : title.characters.first.toUpperCase(),
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : AppNetworkImage(
                imageUrl: url,
                width: 42,
                height: 42,
                errorWidget: Icon(
                  Icons.person_outline_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
      ),
    );
  }
}

Map<String, dynamic> _normalizeMeta(Map<String, dynamic> value) {
  dynamic meta = value;
  if (meta is Map && meta['meta'] is Map) meta = meta['meta'];
  if (meta is Map &&
      meta['docs'] is List &&
      (meta['docs'] as List).isNotEmpty) {
    meta = (meta['docs'] as List).first;
  }
  return meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
}

List<String> _searchFields(Map<String, dynamic> meta) {
  final raw = meta['search_fields'];
  if (raw is List) {
    return raw.map(_text).where((value) => value.isNotEmpty).toList();
  }
  return _text(raw)
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String _text(Object? value) => value?.toString().trim() ?? '';

class _DataError extends StatelessWidget {
  const _DataError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ព្យាយាមម្ដងទៀត'),
        ),
      ],
    ),
  );
}
