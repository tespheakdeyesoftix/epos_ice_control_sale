import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';
import '../sale_detail_controller.dart';

class SaleTimelineCard extends StatelessWidget {
  const SaleTimelineCard({
    super.key,
    required this.entries,
    required this.textController,
    required this.isPosting,
    required this.onPost,
    required this.canEditComment,
    required this.editingCommentNames,
    required this.onEditComment,
  });

  final List<SaleTimelineEntry> entries;
  final TextEditingController textController;
  final bool isPosting;
  final VoidCallback? onPost;
  final bool Function(SaleTimelineEntry entry) canEditComment;
  final Set<String> editingCommentNames;
  final ValueChanged<SaleTimelineEntry> onEditComment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final comments = entries
        .where((entry) => entry.kind == SaleTimelineKind.comment)
        .toList(growable: false);
    final activity = entries
        .where((entry) => entry.kind != SaleTimelineKind.comment)
        .toList(growable: false);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: colors.primary),
                const SizedBox(width: 9),
                Text(
                  'មតិយោបល់',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _CountBadge(count: comments.length),
              ],
            ),
            const SizedBox(height: 13),
            TextField(
              key: const ValueKey('sale-timeline-composer'),
              controller: textController,
              enabled: !isPosting,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'សរសេរមតិយោបល់...',
                prefixIcon: const Icon(Icons.account_circle_outlined),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(7),
                  child: IconButton.filled(
                    tooltip: 'បង្ហោះមតិយោបល់',
                    onPressed: onPost,
                    icon: isPosting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 19),
                  ),
                ),
              ),
              onSubmitted: (_) => onPost?.call(),
            ),
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...comments.map(
                (entry) => _CommentTile(
                  entry: entry,
                  canEdit: canEditComment(entry),
                  isEditing: editingCommentNames.contains(entry.name),
                  onEdit: () => onEditComment(entry),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.history_rounded, color: colors.tertiary),
                const SizedBox(width: 9),
                Text(
                  'សកម្មភាព',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _CountBadge(count: activity.length),
              ],
            ),
            const SizedBox(height: 14),
            if (activity.isEmpty)
              Text(
                'មិនទាន់មានសកម្មភាពទេ',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else
              ...activity.map((entry) => _ActivityTile(entry: entry)),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count'),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.entry,
    required this.canEdit,
    required this.isEditing,
    required this.onEdit,
  });

  final SaleTimelineEntry entry;
  final bool canEdit;
  final bool isEditing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primary.withValues(alpha: .1),
            foregroundColor: colors.primary,
            child: const Icon(Icons.person_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.author,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (canEdit)
                        IconButton(
                          key: ValueKey('edit-sale-comment-${entry.name}'),
                          tooltip: 'កែប្រែមតិយោបល់',
                          visualDensity: VisualDensity.compact,
                          onPressed: isEditing ? null : onEdit,
                          icon: isEditing
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.edit_outlined, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatExactDateTime(entry.createdAt),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(entry.content, style: const TextStyle(height: 1.45)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final SaleTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, tint) = switch (entry.kind) {
      SaleTimelineKind.created => (
        Icons.add_circle_outline_rounded,
        colors.primary,
      ),
      SaleTimelineKind.modified => (Icons.edit_outlined, colors.tertiary),
      SaleTimelineKind.change => (
        Icons.change_circle_outlined,
        colors.tertiary,
      ),
      SaleTimelineKind.comment => (
        Icons.chat_bubble_outline_rounded,
        colors.primary,
      ),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: tint),
                ),
                Expanded(
                  child: Container(width: 1, color: colors.outlineVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: entry.author,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' ${entry.content}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatExactDateTime(entry.createdAt),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (entry.changes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ExpandableChangeList(changes: entry.changes),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableChangeList extends StatefulWidget {
  const _ExpandableChangeList({required this.changes});

  final List<String> changes;

  @override
  State<_ExpandableChangeList> createState() => _ExpandableChangeListState();
}

class _ExpandableChangeListState extends State<_ExpandableChangeList> {
  static const _collapsedLineCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasMore = widget.changes.length > _collapsedLineCount;
    final visibleChanges = _expanded
        ? widget.changes
        : widget.changes.take(_collapsedLineCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in visibleChanges)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '• $change',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        if (hasMore)
          TextButton.icon(
            key: ValueKey(
              _expanded
                  ? 'collapse-activity-changes'
                  : 'expand-activity-changes',
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(top: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
            ),
            label: Text(
              _expanded
                  ? 'បង្ហាញតិច'
                  : 'មើលបន្ថែម ${widget.changes.length - _collapsedLineCount} ចំណុច',
            ),
          ),
      ],
    );
  }
}
