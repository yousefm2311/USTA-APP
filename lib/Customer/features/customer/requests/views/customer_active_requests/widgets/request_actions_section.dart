import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestActionsSection extends StatelessWidget {
  const RequestActionsSection({
    super.key,
    required this.canCancel,
    required this.canConfirm,
    required this.canPriceConfirm,
    required this.isClosed,
    required this.confirmColor,
    required this.cancelColor,
    required this.onPriceConfirm,
    required this.onConfirmCompletion,
    required this.onCancel,
    required this.onWriteReview,
  });

  final bool canCancel;
  final bool canConfirm;
  final bool canPriceConfirm;
  final bool isClosed;
  final Color confirmColor;
  final Color cancelColor;
  final VoidCallback onPriceConfirm;
  final Future<void> Function() onConfirmCompletion;
  final Future<void> Function() onCancel;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (canPriceConfirm) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPriceConfirm,
              child: Text(
                'تأكيد السعر'.tr,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: canConfirm ? () => onConfirmCompletion() : null,
                child: Text(
                  'تأكيد اكتمال الطلب'.tr,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ),
            if (canCancel) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cancelColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => onCancel(),
                  child: Text(
                    'إلغاء الطلب'.tr,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (isClosed) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.primary),
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onWriteReview,
              icon: const Icon(Icons.star_border),
              label: Text(
                'تقييم الحرفي'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
