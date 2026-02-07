import 'package:flutter/material.dart';

enum SnackBarType { info, success, warning, error }

class AppSnackBar {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(
    String title,
    String message, {
    SnackBarType? type,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    Object? snackPosition,
  }) {
    final _ = snackPosition;
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final context = messenger.context;
    final scheme = Theme.of(context).colorScheme;
    final resolvedType = type ?? _inferType(title);
    final bg = backgroundColor ?? _typeBackground(resolvedType, scheme);
    final fg = colorText ?? _typeForeground(resolvedType, scheme);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: bg,
        duration: duration ?? const Duration(seconds: 3),
        showCloseIcon: true,
        closeIconColor: fg,
        dismissDirection: DismissDirection.horizontal,
        content: _buildContent(title, message, fg),
      ),
    );
  }

  static SnackBarType _inferType(String title) {
    final t = title.toLowerCase();
    if (t.contains('خطأ') || t.contains('error')) return SnackBarType.error;
    if (t.contains('تنبيه') || t.contains('warning') || t.contains('alert')) {
      return SnackBarType.warning;
    }
    if (t.contains('تم') || t.contains('success') || t.contains('نجاح')) {
      return SnackBarType.success;
    }
    return SnackBarType.info;
  }

  static Color _typeBackground(SnackBarType type, ColorScheme scheme) {
    switch (type) {
      case SnackBarType.error:
        return scheme.error;
      case SnackBarType.success:
        return Colors.green.shade600;
      case SnackBarType.warning:
        return Colors.orange.shade700;
      case SnackBarType.info:
        return scheme.inverseSurface;
    }
  }

  static Color _typeForeground(SnackBarType type, ColorScheme scheme) {
    switch (type) {
      case SnackBarType.error:
        return scheme.onError;
      case SnackBarType.success:
      case SnackBarType.warning:
        return Colors.white;
      case SnackBarType.info:
        return scheme.onInverseSurface;
    }
  }

  static Widget _buildContent(String title, String message, Color color) {
    final hasTitle = title.trim().isNotEmpty;
    final hasMessage = message.trim().isNotEmpty;

    if (hasTitle && hasMessage) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(color: color),
          ),
        ],
      );
    }

    return Text(
      hasTitle ? title : message,
      style: TextStyle(color: color),
    );
  }
}
