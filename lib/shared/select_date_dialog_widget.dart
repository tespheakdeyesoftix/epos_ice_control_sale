import 'package:flutter/material.dart';

Future<DateTime?> showSelectDateDialog(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => SelectDateDialogWidget(initialDate: initialDate),
  );
}

class SelectDateDialogWidget extends StatefulWidget {
  const SelectDateDialogWidget({
    super.key,
    required this.initialDate,
    this.today,
  });

  final DateTime initialDate;

  /// Optional fixed current date for deterministic tests.
  final DateTime? today;

  @override
  State<SelectDateDialogWidget> createState() => _SelectDateDialogWidgetState();
}

class _SelectDateDialogWidgetState extends State<SelectDateDialogWidget> {
  late final DateTime _today;
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    _firstDate = DateTime(1900, 1, 1);
    _lastDate = _today.add(const Duration(days: 1));
    final initialDate = DateUtils.dateOnly(widget.initialDate);
    _selectedDate = initialDate.isBefore(_firstDate)
        ? _firstDate
        : initialDate.isAfter(_lastDate)
        ? _lastDate
        : initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.only(left: 18),
              color: colors.inverseSurface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ជ្រើសរើសកាលបរិច្ឆេទ',
                      style: TextStyle(
                        color: colors.onInverseSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton(
                      key: const ValueKey('close-date-dialog'),
                      tooltip: 'បិទ',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: colors.onError,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.error,
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatDate(_selectedDate),
                      key: const ValueKey('selected-posting-date'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    currentDate: _today,
                    onDateChanged: (date) {
                      setState(() => _selectedDate = DateUtils.dateOnly(date));
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('បោះបង់'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('confirm-posting-date'),
                          onPressed: () =>
                              Navigator.of(context).pop(_selectedDate),
                          child: const Text('យល់ព្រម'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day / $month / ${date.year}';
}
