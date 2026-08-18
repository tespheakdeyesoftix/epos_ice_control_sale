import 'package:flutter/material.dart';

Future<String?> showSelectOutletDialog(
  BuildContext context, {
  required List<String> outlets,
  required String selectedOutlet,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => SelectOutletDialogWidget(
      outlets: outlets,
      selectedOutlet: selectedOutlet,
    ),
  );
}

class SelectOutletDialogWidget extends StatelessWidget {
  const SelectOutletDialogWidget({
    super.key,
    required this.outlets,
    required this.selectedOutlet,
  });

  final List<String> outlets;
  final String selectedOutlet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SimpleDialog(
      key: const ValueKey('select-outlet-dialog'),
      title: const Text('ជ្រើសរើសកន្លែងលក់'),
      children: outlets
          .map(
            (outlet) => SimpleDialogOption(
              key: ValueKey('outlet-option-$outlet'),
              onPressed: outlet == selectedOutlet
                  ? null
                  : () => Navigator.of(context).pop(outlet),
              child: Row(
                children: [
                  Icon(
                    outlet == selectedOutlet
                        ? Icons.check_circle_rounded
                        : Icons.storefront_outlined,
                    color: outlet == selectedOutlet
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      outlet,
                      style: TextStyle(
                        fontWeight: outlet == selectedOutlet
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
