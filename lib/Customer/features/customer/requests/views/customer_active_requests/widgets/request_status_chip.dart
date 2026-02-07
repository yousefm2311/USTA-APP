import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestStatusStyle {
  final Color bg;
  final Color fg;
  final String label;

  const RequestStatusStyle(this.bg, this.fg, this.label);
}

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    RequestStatusStyle styleFor(MaterialColor base, String text) {
      final bg = isDark ? base.withOpacity(0.22) : base.withOpacity(0.10);
      final fg = isDark ? base.shade300 : base.shade700;
      return RequestStatusStyle(bg, fg, text);
    }

    final normalized = status.toLowerCase();
    late RequestStatusStyle s;

    switch (normalized) {
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
        s = RequestStatusStyle(
          scheme.onSurface.withOpacity(isDark ? 0.14 : 0.08),
          scheme.onSurface.withOpacity(0.85),
          normalized.isEmpty ? 'غير معروف'.tr : normalized,
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        s.label,
        style: TextStyle(
          fontFamily: "Cairo",
          color: s.fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
