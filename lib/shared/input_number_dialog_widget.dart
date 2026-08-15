import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

Future<double?> showInputNumberDialog(
  BuildContext context, {
  double? initialValue,
  bool allowZero = false,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => InputNumberDialogWidget(
      initialValue: initialValue,
      allowZero: allowZero,
    ),
  );
}

class InputNumberDialogWidget extends StatefulWidget {
  const InputNumberDialogWidget({
    super.key,
    this.initialValue,
    this.allowZero = false,
    this.predefinedValues = const [
      10,
      20,
      25,
      30,
      40,
      50,
      100,
      150,
      200,
      250,
      300,
      350,
      400,
      500,
      1000,
      2000,
      3000,
      4000,
    ],
  });

  final double? initialValue;
  final bool allowZero;
  final List<int> predefinedValues;

  @override
  State<InputNumberDialogWidget> createState() =>
      _InputNumberDialogWidgetState();
}

class _InputNumberDialogWidgetState extends State<InputNumberDialogWidget> {
  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    '00',
    '.',
  ];

  late String _input;

  double? get _quantity {
    final value = double.tryParse(_input);
    return value != null && (value > 0 || (widget.allowZero && value == 0))
        ? value
        : null;
  }

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue;
    _input =
        initialValue != null &&
            (initialValue > 0 || (widget.allowZero && initialValue == 0))
        ? _formatInputValue(initialValue)
        : '';
  }

  void _append(String value) {
    setState(() {
      if (_input == '0') {
        _input = value.replaceFirst(RegExp(r'^0+'), '');
      } else {
        _input += value;
      }
      if (_input.isEmpty && value.contains(RegExp('[^0]'))) _input = value;
    });
  }

  void _clear() => setState(() => _input = '');

  void _appendDecimal() {
    if (_input.contains('.')) return;
    setState(() => _input = _input.isEmpty ? '0.' : '$_input.');
  }

  void _accept() {
    final quantity = _quantity;
    if (quantity != null) Navigator.of(context).pop(quantity);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    final screen = MediaQuery.sizeOf(context);
    final width = math.min(740.0, screen.width - 48);
    final height = math.min(560.0, screen.height - 48);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.only(left: 20),
              color: colors.inverseSurface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'បញ្ចូលចំនួន',
                      style: TextStyle(
                        color: colors.onInverseSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: IconButton(
                      key: const ValueKey('close-number-dialog'),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildKeypad(colors)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildPredefinedValues(colors, semanticColors),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('quantity-input'),
          height: 54,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: Text(
                  _input,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: 5,
                child: IconButton(
                  key: const ValueKey('clear-number'),
                  tooltip: 'សម្អាត',
                  onPressed: _input.isEmpty ? null : _clear,
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: colors.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.55,
            ),
            itemCount: _keys.length,
            itemBuilder: (context, index) {
              final value = _keys[index];
              final isDecimal = value == '.';
              return FilledButton(
                key: isDecimal
                    ? const ValueKey('decimal-number')
                    : ValueKey('number-key-$value'),
                onPressed: isDecimal && _input.contains('.')
                    ? null
                    : () => isDecimal ? _appendDecimal() : _append(value),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(value, style: const TextStyle(fontSize: 17)),
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 64,
          child: FilledButton(
            key: const ValueKey('accept-number'),
            onPressed: _quantity == null ? null : _accept,
            child: const Text(
              'យល់ព្រម',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredefinedValues(
    ColorScheme colors,
    AppSemanticColors semanticColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ជ្រើសរើសចំនួនរហ័ស',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 2,
            ),
            itemCount: widget.predefinedValues.length,
            itemBuilder: (context, index) {
              final value = widget.predefinedValues[index];
              return FilledButton(
                key: ValueKey('preset-$value'),
                onPressed: () => Navigator.of(context).pop(value.toDouble()),
                style: FilledButton.styleFrom(
                  backgroundColor: semanticColors.success,
                  foregroundColor: semanticColors.onSuccess,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text('$value', style: const TextStyle(fontSize: 15)),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _formatInputValue(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
