import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/helpers.dart';

class FrappeServerMessage {
  const FrappeServerMessage({
    required this.message,
    this.indicator = '',
    this.raiseException = false,
  });

  final String message;
  final String indicator;
  final bool raiseException;
}

class FrappeServerMessageException implements Exception {
  const FrappeServerMessageException(this.messages);

  final List<FrappeServerMessage> messages;

  @override
  String toString() => messages.map((item) => item.message).join('\n');
}

abstract final class FrappeResponseHandler {
  static String plainText(String value) {
    var text = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(?:p|div|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');
    text = text.replaceAllMapped(RegExp(r'&(?:#x[0-9a-f]+|#[0-9]+|\w+);'), (
      match,
    ) {
      final entity = match.group(0)!;
      final lower = entity.toLowerCase();
      const named = {
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
        '&quot;': '"',
        '&apos;': "'",
        '&#39;': "'",
        '&nbsp;': ' ',
      };
      final namedValue = named[lower];
      if (namedValue != null) return namedValue;
      if (!lower.startsWith('&#')) return entity;
      final isHex = lower.startsWith('&#x');
      final digits = lower.substring(isHex ? 3 : 2, lower.length - 1);
      final codePoint = int.tryParse(digits, radix: isHex ? 16 : 10);
      if (codePoint == null || codePoint > 0x10ffff) return entity;
      return String.fromCharCode(codePoint);
    });
    return text
        .replaceAll(RegExp(r'[ \t\f\v]+'), ' ')
        .replaceAll(RegExp(r' *\n *'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static List<FrappeServerMessage> parse(String responseBody) {
    try {
      final response = jsonDecode(responseBody);
      if (response is! Map || !response.containsKey('_server_messages')) {
        return const [];
      }

      dynamic rawMessages = response['_server_messages'];
      if (rawMessages is String) {
        try {
          rawMessages = jsonDecode(rawMessages);
        } on FormatException {
          return [FrappeServerMessage(message: plainText(rawMessages))];
        }
      }

      final rows = rawMessages is List ? rawMessages : [rawMessages];
      final messages = <FrappeServerMessage>[];
      for (var row in rows) {
        if (row is String) {
          try {
            row = jsonDecode(row);
          } on FormatException {
            final message = plainText(row);
            if (message.isNotEmpty) {
              messages.add(FrappeServerMessage(message: message));
            }
            continue;
          }
        }
        if (row is! Map) continue;
        final message = plainText(row['message']?.toString() ?? '');
        if (message.isEmpty) continue;
        messages.add(
          FrappeServerMessage(
            message: message,
            indicator: row['indicator']?.toString().trim().toLowerCase() ?? '',
            raiseException: _flag(row['raise_exception']),
          ),
        );
      }
      return messages;
    } on FormatException {
      return const [];
    }
  }

  static bool _flag(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true';
  }

  static void show(FrappeServerMessage serverMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = plainText(serverMessage.message);
      switch (serverMessage.indicator.trim().toLowerCase()) {
        case 'green':
          showSuccess(message);
        case 'red':
          showError(message);
        default:
          showWarning(message);
      }
    });
  }
}
