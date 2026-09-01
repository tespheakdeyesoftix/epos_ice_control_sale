import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:get/get.dart';

import '../../utils/helpers.dart';
import 'note_controller.dart';
import 'note_html.dart';
import 'note_record.dart';

const notePalette = <Color>[
  Color(0xFFFFFDF7),
  Color(0xFFFFF2B2),
  Color(0xFFFFD8A8),
  Color(0xFFCDECCF),
  Color(0xFFCDEFE8),
  Color(0xFFD8E8FF),
  Color(0xFFE7D9FF),
  Color(0xFFFFD9E5),
];

class NoteAppScreen extends GetView<NoteController> {
  const NoteAppScreen({super.key});

  Future<void> _openEditor(BuildContext context, [NoteRecord? note]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NoteEditorDialog(controller: controller, note: note),
    );
    if (saved != true || !context.mounted) return;
    showSuccess(
      note == null ? 'បានបង្កើតកំណត់ចំណាំ។' : 'បានរក្សាទុកកំណត់ចំណាំ។',
    );
  }

  Future<void> _confirmDelete(BuildContext context, NoteRecord note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('លុបកំណត់ចំណាំ?'),
        content: Text('តើអ្នកចង់លុប “${note.title}” មែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('បោះបង់'),
          ),
          FilledButton.tonal(
            key: const ValueKey('confirm-delete-note'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('លុប'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.deleteNote(note);
    if (!context.mounted || success) return;
    showError('មិនអាចលុបកំណត់ចំណាំបានទេ។');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('note-app-screen'),
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'កំណត់ចំណាំ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Obx(
              () => Text(
                'កន្លែងលក់៖ ${controller.outlet}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                key: const ValueKey('note-search-input'),
                onChanged: controller.updateSearch,
                decoration: const InputDecoration(
                  hintText: 'ស្វែងរកកំណត់ចំណាំ',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('refresh-notes'),
            tooltip: 'ទាញយកឡើងវិញ',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 20),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-note'),
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('បន្ថែមកំណត់ចំណាំ'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = controller.errorMessage.value;
        if (error != null && controller.notes.isEmpty) {
          return _NoteStatus(
            icon: Icons.cloud_off_rounded,
            title: error,
            actionLabel: 'ព្យាយាមម្ដងទៀត',
            onAction: controller.load,
          );
        }
        if (controller.visibleNotes.isEmpty) {
          return _NoteStatus(
            icon: controller.search.value.trim().isEmpty
                ? Icons.note_add_outlined
                : Icons.search_off_rounded,
            title: controller.search.value.trim().isEmpty
                ? 'មិនទាន់មានកំណត់ចំណាំទេ'
                : 'រកមិនឃើញកំណត់ចំណាំទេ',
            actionLabel: controller.search.value.trim().isEmpty
                ? 'បង្កើតកំណត់ចំណាំ'
                : null,
            onAction: controller.search.value.trim().isEmpty
                ? () => _openEditor(context)
                : null,
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 400) {
              controller.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 104),
              children: [
                if (controller.visiblePinnedNotes.isNotEmpty)
                  _NoteSection(
                    title: 'បានខ្ទាស់',
                    icon: Icons.push_pin_rounded,
                    notes: controller.visiblePinnedNotes,
                    controller: controller,
                    onEdit: (note) => _openEditor(context, note),
                    onDelete: (note) => _confirmDelete(context, note),
                    onFailure: showError,
                  ),
                if (controller.visiblePinnedNotes.isNotEmpty &&
                    controller.visibleRegularNotes.isNotEmpty)
                  const SizedBox(height: 28),
                if (controller.visibleRegularNotes.isNotEmpty)
                  _NoteSection(
                    title: 'កំណត់ចំណាំទាំងអស់',
                    icon: Icons.notes_rounded,
                    notes: controller.visibleRegularNotes,
                    controller: controller,
                    onEdit: (note) => _openEditor(context, note),
                    onDelete: (note) => _confirmDelete(context, note),
                    onFailure: showError,
                  ),
                if (controller.isLoadingMore.value)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _NoteStatus extends StatelessWidget {
  const _NoteStatus({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 58, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({
    required this.title,
    required this.icon,
    required this.notes,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
    required this.onFailure,
  });

  final String title;
  final IconData icon;
  final List<NoteRecord> notes;
  final NoteController controller;
  final ValueChanged<NoteRecord> onEdit;
  final ValueChanged<NoteRecord> onDelete;
  final ValueChanged<String> onFailure;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text(
            '${notes.length}',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 1240
              ? 4
              : constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 590
              ? 2
              : 1;
          const spacing = 16.0;
          final width = (constraints.maxWidth - spacing * (count - 1)) / count;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final note in notes)
                SizedBox(
                  width: width,
                  child: _NoteCard(
                    note: note,
                    busy: controller.savingNames.contains(note.name),
                    onEdit: () => onEdit(note),
                    onDelete: () => onDelete(note),
                    onPin: () async {
                      final success = await controller.togglePinned(note);
                      if (!success) {
                        onFailure(
                          controller.lastMutationError.value ??
                              'មិនអាចប្ដូរស្ថានភាពខ្ទាស់បានទេ។',
                        );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

enum _NoteMenuAction { edit, delete }

class _NoteCard extends StatefulWidget {
  const _NoteCard({
    required this.note,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  });

  final NoteRecord note;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final busy = widget.busy;
    final fallback = Theme.of(context).colorScheme.surface;
    final background = colorFromHex(note.color, fallback: fallback);
    final foreground = background.computeLuminance() > 0.45
        ? const Color(0xFF172033)
        : Colors.white;
    return Material(
      key: ValueKey('note-card-${note.name}'),
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: foreground.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        onTap: busy ? null : widget.onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'គ្មានចំណងជើង' : note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('pin-note-${note.name}'),
                    tooltip: note.isPinned ? 'ដោះខ្ទាស់' : 'ខ្ទាស់',
                    onPressed: busy ? null : widget.onPin,
                    icon: Icon(
                      note.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: foreground,
                      size: 20,
                    ),
                  ),
                  PopupMenuButton<_NoteMenuAction>(
                    enabled: !busy,
                    iconColor: foreground,
                    onSelected: (action) {
                      if (action == _NoteMenuAction.edit) widget.onEdit();
                      if (action == _NoteMenuAction.delete) widget.onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _NoteMenuAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('កែប្រែ'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _NoteMenuAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('លុប'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final content = notePlainText(note.content);
                  final style = TextStyle(
                    color: foreground.withValues(alpha: 0.82),
                    height: 1.45,
                  );
                  final painter = TextPainter(
                    text: TextSpan(text: content, style: style),
                    maxLines: 3,
                    textDirection: Directionality.of(context),
                  )..layout(maxWidth: constraints.maxWidth);
                  final canExpand = painter.didExceedMaxLines;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: style,
                      ),
                      if (canExpand || _expanded)
                        TextButton(
                          key: ValueKey('read-more-note-${note.name}'),
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.only(top: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _expanded ? 'បង្ហាញតិច' : 'អានបន្ថែម',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    for (final tag in note.tags.take(3))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (note.tags.length > 3)
                      Text(
                        '+${note.tags.length - 3}',
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  if (note.notifyOn != null) ...[
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 16,
                      color: foreground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(note.notifyOn),
                      style: TextStyle(color: foreground, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  if (busy)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  else
                    Text(
                      formatTimeAgo(note.modified ?? note.creation),
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditorDialog extends StatefulWidget {
  const NoteEditorDialog({super.key, required this.controller, this.note});

  final NoteController controller;
  final NoteRecord? note;

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _tagController;
  late final quill.QuillController _contentController;
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  late Color _color;
  late bool _isPinned;
  late final List<String> _tags;
  DateTime? _notifyOn;
  bool _saving = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _tagController = TextEditingController();
    _contentController = quill.QuillController(
      document: noteDocumentFromHtml(note?.content ?? ''),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _color = colorFromHex(note?.color ?? '', fallback: notePalette.first);
    _isPinned = note?.isPinned ?? false;
    _tags = [...?note?.tags];
    _notifyOn = note?.notifyOn;
  }

  void _addTags([String? source]) {
    final value = source ?? _tagController.text;
    final additions = parseNoteTags(value);
    if (additions.isEmpty) return;
    setState(() {
      for (final tag in additions) {
        if (_tags.any((item) => item.toLowerCase() == tag.toLowerCase())) {
          continue;
        }
        _tags.add(tag);
      }
      _tagController.clear();
    });
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final existing = _notifyOn;
    final initialDate = existing == null || existing.isBefore(today)
        ? today
        : existing;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 10, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _notifyOn = DateUtils.dateOnly(selected));
    }
  }

  Future<void> _save() async {
    if (_tagController.text.trim().isNotEmpty) _addTags();
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'សូមបញ្ចូលចំណងជើង។');
      return;
    }
    setState(() {
      _saving = true;
      _titleError = null;
    });
    final html = noteDocumentToHtml(_contentController.document);
    final color = _colorToHex(_color);
    final note = widget.note;
    final success = note == null
        ? await widget.controller.create(
            title: title,
            content: html,
            color: color,
            isPinned: _isPinned,
            tags: _tags,
            notifyOn: _notifyOn,
          )
        : await widget.controller.updateNote(
            note: note,
            title: title,
            content: html,
            color: color,
            isPinned: _isPinned,
            tags: _tags,
            notifyOn: _notifyOn,
          );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
      showError(
        widget.controller.lastMutationError.value ??
            'មិនអាចរក្សាទុកកំណត់ចំណាំបានទេ។',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [...notePalette];
    if (!palette.any((color) => color.toARGB32() == _color.toARGB32())) {
      palette.insert(0, _color);
    }
    return Dialog(
      key: const ValueKey('note-editor-dialog'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 780,
        height: 680,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 12, 16),
              color: colors.surfaceContainerLow,
              child: Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.note == null
                          ? 'បង្កើតកំណត់ចំណាំ'
                          : 'កែប្រែកំណត់ចំណាំ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'បិទ',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('note-title-input'),
                      controller: _titleController,
                      autofocus: true,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: 'ចំណងជើង',
                        errorText: _titleError,
                      ),
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: quill.QuillSimpleToolbar(
                        controller: _contentController,
                        config: const quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showFontFamily: false,
                          showFontSize: false,
                          showSmallButton: false,
                          showInlineCode: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showClearFormat: true,
                          showAlignmentButtons: true,
                          showListCheck: false,
                          showCodeBlock: false,
                          showQuote: false,
                          showIndent: false,
                          showSearchButton: false,
                          showSubscript: false,
                          showSuperscript: false,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _color,
                          border: Border.all(color: colors.outlineVariant),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: quill.QuillEditor(
                          controller: _contentController,
                          focusNode: _editorFocusNode,
                          scrollController: _editorScrollController,
                          config: const quill.QuillEditorConfig(
                            placeholder: 'សរសេរកំណត់ចំណាំរបស់អ្នក…',
                            padding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 11),
                          child: Text(
                            'ស្លាក៖',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 76,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          for (final tag in _tags)
                                            InputChip(
                                              key: ValueKey(
                                                'note-editor-tag-$tag',
                                              ),
                                              label: Text('#$tag'),
                                              onDeleted: _saving
                                                  ? null
                                                  : () => setState(
                                                      () => _tags.remove(tag),
                                                    ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: 42,
                                child: TextField(
                                  key: const ValueKey('note-tag-input'),
                                  controller: _tagController,
                                  enabled: !_saving,
                                  onSubmitted: _addTags,
                                  decoration: InputDecoration(
                                    hintText: 'បន្ថែមស្លាក',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    suffixIcon: IconButton(
                                      key: const ValueKey('add-note-tag'),
                                      tooltip: 'បន្ថែមស្លាក',
                                      onPressed: _saving ? null : _addTags,
                                      icon: const Icon(Icons.add_rounded),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('ពណ៌៖'),
                        const SizedBox(width: 8),
                        for (final color in palette)
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: InkWell(
                              key: ValueKey('note-color-${color.toARGB32()}'),
                              borderRadius: BorderRadius.circular(20),
                              onTap: _saving
                                  ? null
                                  : () => setState(() => _color = color),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color.toARGB32() == color.toARGB32()
                                        ? colors.primary
                                        : colors.outline,
                                    width: _color.toARGB32() == color.toARGB32()
                                        ? 3
                                        : 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        FilterChip(
                          key: const ValueKey('note-pin-toggle'),
                          selected: _isPinned,
                          onSelected: _saving
                              ? null
                              : (value) => setState(() => _isPinned = value),
                          avatar: const Icon(Icons.push_pin_outlined, size: 18),
                          label: const Text('ខ្ទាស់'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          key: const ValueKey('note-reminder-date'),
                          onPressed: _saving ? null : _selectDate,
                          icon: const Icon(Icons.notifications_none_rounded),
                          label: Text(
                            _notifyOn == null
                                ? 'កំណត់ថ្ងៃជូនដំណឹង'
                                : formatDate(_notifyOn),
                          ),
                        ),
                        if (_notifyOn != null) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            key: const ValueKey('clear-note-reminder'),
                            tooltip: 'លុបថ្ងៃជូនដំណឹង',
                            onPressed: _saving
                                ? null
                                : () => setState(() => _notifyOn = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('បោះបង់'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    key: const ValueKey('save-note'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('រក្សាទុក'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _contentController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }
}

String _colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
