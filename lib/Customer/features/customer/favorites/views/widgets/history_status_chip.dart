import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryStatusChip extends StatelessWidget {
  final String status;

  const HistoryStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    StatusStyle styleFor(MaterialColor base, String text) {
      final background = isDark
          ? base.withOpacity(0.22)
          : base.withOpacity(0.10);
      final foreground = isDark ? base.shade300 : base.shade700;
      return StatusStyle(background, foreground, text);
    }

    late StatusStyle s;
    switch (status) {
      case 'new':
        s = styleFor(Colors.blue, 'جديد'.tr);
        break;
      case 'accepted':
        s = styleFor(Colors.green, 'مقبول'.tr);
        break;
      case 'assigned':
        s = styleFor(Colors.teal, 'تم التعيين'.tr);
        break;
      case 'on_the_way':
        s = styleFor(Colors.indigo, 'في الطريق'.tr);
        break;
      case 'arrived':
        s = styleFor(Colors.cyan, 'تم الوصول'.tr);
        break;
      case 'in_progress':
        s = styleFor(Colors.orange, 'قيد التنفيذ'.tr);
        break;
      case 'work_started':
        s = styleFor(Colors.orange, 'بدأ العمل'.tr);
        break;
      case 'price_rejected':
        s = styleFor(Colors.red, 'السعر مرفوض'.tr);
        break;
      case 'awaiting_customer_price_confirm':
        s = styleFor(Colors.amber, 'انتظار تأكيد السعر'.tr);
        break;
      case 'awaiting_confirmation':
        s = styleFor(Colors.amber, 'انتظار التأكيد'.tr);
        break;
      case 'completed':
        s = styleFor(Colors.green, 'مكتمل'.tr);
        break;
      case 'cancelled':
      case 'rejected':
        s = styleFor(Colors.red, 'ملغي'.tr);
        break;
      default:
        final bg = scheme.onSurface.withOpacity(isDark ? 0.14 : 0.08);
        final fg = scheme.onSurface.withOpacity(0.85);
        final label = status.isEmpty ? 'غير معروف'.tr : status;
        return _chip(
          bg: bg,
          fg: fg,
          label: label,
          border: scheme.outlineVariant,
        );
    }

    return _chip(
      bg: s.bg,
      fg: s.fg,
      label: s.label,
      border: scheme.outlineVariant,
    );
  }

  Widget _chip({
    required Color bg,
    required Color fg,
    required String label,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: "Cairo",
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StatusStyle {
  final Color bg;
  final Color fg;
  final String label;
  StatusStyle(this.bg, this.fg, this.label);
}
