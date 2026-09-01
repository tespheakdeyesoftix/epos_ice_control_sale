import 'package:flutter/material.dart';

import '../../services/note_service.dart';
import '../../utils/helpers.dart';
import 'note_html.dart';
import 'note_record.dart';

class NoteReminderLauncher extends StatefulWidget {
  const NoteReminderLauncher({
    super.key,
    required this.service,
    required this.outlet,
    this.today,
  });

  final NoteService service;
  final String outlet;
  final DateTime? today;

  @override
  State<NoteReminderLauncher> createState() => _NoteReminderLauncherState();
}

class _NoteReminderLauncherState extends State<NoteReminderLauncher> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_started || widget.outlet.trim().isEmpty || !mounted) return;
    _started = true;
    try {
      final notes = await widget.service.dueToday(
        outlet: widget.outlet,
        today: DateUtils.dateOnly(widget.today ?? DateTime.now()),
      );
      if (!mounted || notes.isEmpty) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _DueNoteDialog(notes: notes),
      );
    } on Exception {
      if (!mounted) return;
      showError('មិនអាចពិនិត្យការជូនដំណឹងកំណត់ចំណាំបានទេ។');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DueNoteDialog extends StatelessWidget {
  const _DueNoteDialog({required this.notes});

  final List<NoteRecord> notes;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('due-note-dialog'),
    icon: const Icon(Icons.notifications_active_outlined, size: 34),
    title: const Text('កំណត់ចំណាំសម្រាប់ថ្ងៃនេះ'),
    content: SizedBox(
      width: 520,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 430),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: notes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final note = notes[index];
            final background = colorFromHex(
              note.color,
              fallback: Theme.of(context).colorScheme.surfaceContainerLow,
            );
            final foreground = background.computeLuminance() > 0.45
                ? const Color(0xFF172033)
                : Colors.white;
            return Container(
              key: ValueKey('due-note-${note.name}'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notePlainText(note.content),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: foreground.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    actions: [
      FilledButton(
        key: const ValueKey('dismiss-due-notes'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('យល់ព្រម'),
      ),
    ],
  );
}
