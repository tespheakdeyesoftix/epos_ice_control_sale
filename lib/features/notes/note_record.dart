import '../../utils/helpers.dart';

class NoteRecord {
  const NoteRecord({
    required this.name,
    required this.title,
    required this.content,
    required this.color,
    required this.outlet,
    required this.isPinned,
    required this.owner,
    this.tags = const [],
    this.notifyOn,
    this.creation,
    this.modified,
  });

  factory NoteRecord.fromJson(Map<String, dynamic> json) => NoteRecord(
    name: textValue(json['name']),
    title: textValue(json['title']),
    content: textValue(json['content']),
    color: textValue(json['custom_color']),
    outlet: textValue(json['custom_outlet']),
    isPinned: _flag(json['custom_is_pin']),
    notifyOn: _date(json['custom_notify_on']),
    owner: textValue(json['owner']),
    tags: parseNoteTags(json['_user_tags']),
    creation: _dateTime(json['creation']),
    modified: _dateTime(json['modified']),
  );

  final String name;
  final String title;
  final String content;
  final String color;
  final String outlet;
  final bool isPinned;
  final DateTime? notifyOn;
  final String owner;
  final List<String> tags;
  final DateTime? creation;
  final DateTime? modified;

  NoteRecord copyWithTags(List<String> value) => NoteRecord(
    name: name,
    title: title,
    content: content,
    color: color,
    outlet: outlet,
    isPinned: isPinned,
    owner: owner,
    tags: List.unmodifiable(value),
    notifyOn: notifyOn,
    creation: creation,
    modified: modified,
  );
}

List<String> parseNoteTags(Object? value) {
  final rawValues = value is List ? value : textValue(value).split(',');
  final tags = <String>[];
  final normalized = <String>{};
  for (final raw in rawValues) {
    final tag = textValue(raw).replaceFirst(RegExp(r'^#+'), '').trim();
    if (tag.isEmpty || !normalized.add(tag.toLowerCase())) continue;
    tags.add(tag);
  }
  return List.unmodifiable(tags);
}

bool _flag(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true';
}

DateTime? _date(Object? value) {
  final parsed = _dateTime(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _dateTime(Object? value) {
  final source = textValue(value);
  return source.isEmpty ? null : DateTime.tryParse(source);
}

String noteDateValue(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
