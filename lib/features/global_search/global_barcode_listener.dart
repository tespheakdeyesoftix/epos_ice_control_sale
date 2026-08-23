import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Collects the fast keyboard events emitted by a USB/Bluetooth barcode scanner.
/// A scan is complete when Enter follows a sufficiently long, fast character
/// sequence.
class BarcodeScanBuffer {
  BarcodeScanBuffer({
    this.maximumInterCharacterDelay = const Duration(milliseconds: 100),
    this.minimumLength = 3,
  });

  final Duration maximumInterCharacterDelay;
  final int minimumLength;

  String _value = '';
  DateTime? _lastCharacterAt;

  void addCharacter(String character, {DateTime? at}) {
    if (character.isEmpty ||
        character.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
      return;
    }
    final now = at ?? DateTime.now();
    final previous = _lastCharacterAt;
    if (previous != null &&
        now.difference(previous) > maximumInterCharacterDelay) {
      clear();
    }
    _value += character;
    _lastCharacterAt = now;
  }

  void removeLastCharacter() {
    if (_value.isEmpty) return;
    final runes = _value.runes.toList()..removeLast();
    _value = String.fromCharCodes(runes);
    if (_value.isEmpty) _lastCharacterAt = null;
  }

  String? submit({DateTime? at}) {
    final now = at ?? DateTime.now();
    final lastCharacterAt = _lastCharacterAt;
    final value = _value.trim();
    final isFresh =
        lastCharacterAt != null &&
        now.difference(lastCharacterAt) <= maximumInterCharacterDelay;
    clear();
    return isFresh && value.length >= minimumLength ? value : null;
  }

  void clear() {
    _value = '';
    _lastCharacterAt = null;
  }
}

class GlobalBarcodeListener extends StatefulWidget {
  const GlobalBarcodeListener({
    super.key,
    required this.child,
    required this.onScan,
    this.buffer,
    this.ignoreWhen,
  });

  final Widget child;
  final ValueChanged<String> onScan;
  final BarcodeScanBuffer? buffer;
  final bool Function()? ignoreWhen;

  @override
  State<GlobalBarcodeListener> createState() => _GlobalBarcodeListenerState();
}

class _GlobalBarcodeListenerState extends State<GlobalBarcodeListener> {
  late final BarcodeScanBuffer _buffer;
  late final bool Function(KeyEvent) _keyEventHandler;

  @override
  void initState() {
    super.initState();
    _buffer = widget.buffer ?? BarcodeScanBuffer();
    _keyEventHandler = _handleKeyEvent;
    HardwareKeyboard.instance.addHandler(_keyEventHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyEventHandler);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (widget.ignoreWhen?.call() ?? false) {
      _buffer.clear();
      return false;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final barcode = _buffer.submit();
      if (barcode == null) return false;
      widget.onScan(barcode);
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      _buffer.clear();
      return false;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _buffer.removeLastCharacter();
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      _buffer.clear();
      return false;
    }
    final character = event.character;
    if (character != null) _buffer.addCharacter(character);
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
