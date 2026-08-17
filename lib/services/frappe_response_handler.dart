import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';

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
          return [FrappeServerMessage(message: rawMessages)];
        }
      }

      final rows = rawMessages is List ? rawMessages : [rawMessages];
      final messages = <FrappeServerMessage>[];
      for (var row in rows) {
        if (row is String) {
          try {
            row = jsonDecode(row);
          } on FormatException {
            final message = row.trim();
            if (message.isNotEmpty) {
              messages.add(FrappeServerMessage(message: message));
            }
            continue;
          }
        }
        if (row is! Map) continue;
        final message = row['message']?.toString().trim() ?? '';
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
      final context = Get.context;
      if (context == null) return;
      final colors = Theme.of(context).colorScheme;
      final semanticColors = AppSemanticColors.of(context);
      final presentation = _presentation(
        serverMessage.indicator,
        colors,
        semanticColors,
      );

      Get.rawSnackbar(
        messageText: Text(
          serverMessage.message,
          style: TextStyle(
            color: presentation.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(presentation.icon, color: presentation.foreground),
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        maxWidth: 560,
        margin: const EdgeInsets.only(top: 18),
        borderRadius: 12,
        backgroundColor: presentation.background,
        duration: const Duration(seconds: 4),
      );
    });
  }

  static _ToastPresentation _presentation(
    String indicator,
    ColorScheme colors,
    AppSemanticColors semanticColors,
  ) {
    return switch (indicator) {
      'red' => _ToastPresentation(
        background: colors.error,
        foreground: colors.onError,
        icon: Icons.error_outline_rounded,
      ),
      'green' => _ToastPresentation(
        background: semanticColors.success,
        foreground: semanticColors.onSuccess,
        icon: Icons.check_circle_outline_rounded,
      ),
      'orange' => const _ToastPresentation(
        background: Color(0xFFF79009),
        foreground: Colors.white,
        icon: Icons.warning_amber_rounded,
      ),
      'yellow' => const _ToastPresentation(
        background: Color(0xFFFDB022),
        foreground: Color(0xFF3B2A00),
        icon: Icons.info_outline_rounded,
      ),
      'blue' => _ToastPresentation(
        background: colors.primary,
        foreground: colors.onPrimary,
        icon: Icons.info_outline_rounded,
      ),
      'gray' || 'grey' => _ToastPresentation(
        background: colors.onSurfaceVariant,
        foreground: colors.surface,
        icon: Icons.info_outline_rounded,
      ),
      _ => _ToastPresentation(
        background: colors.inverseSurface,
        foreground: colors.onInverseSurface,
        icon: Icons.info_outline_rounded,
      ),
    };
  }
}

class _ToastPresentation {
  const _ToastPresentation({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
