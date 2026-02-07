import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/price_request/views/customer_request_price_confirm_view.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_request_details_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_status_chip.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class ActiveRequestCard extends StatefulWidget {
  const ActiveRequestCard({
    super.key,
    required this.request,
    required this.controller,
  });

  final Map<String, dynamic> request;
  final CustomerRequestsController controller;

  @override
  State<ActiveRequestCard> createState() => _ActiveRequestCardState();
}

class _ActiveRequestCardState extends State<ActiveRequestCard> {
  bool _cancelLoading = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final status = (widget.request['status'] ?? '').toString().toLowerCase();
    final serviceType =
        widget.request['serviceType'] ??
        widget.request['category'] ??
        widget.request['service'] ??
        'خدمة'.tr;
    final address = widget.request['address'] ?? 'عنوان غير متوفر'.tr;
    final createdAt =
        widget.request['createdAt'] ?? widget.request['updatedAt'];
    final requestId =
        (widget.request['_id'] ?? widget.request['id'])?.toString() ?? '';

    final dateText = _formatDate(createdAt);

    final canCancel = status == 'new' || status == 'accepted';
    final needsPriceConfirm =
        status == 'priced' || status == 'awaiting_customer_price_confirm';

    return InkWell(
      onTap: () {
        if (requestId.isNotEmpty) {
          Get.to(() => CustomerRequestDetailsView(requestId: requestId));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    serviceType.toString(),
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      RequestStatusChip(status: status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1.5, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: scheme.onSurface.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.toString(),
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                      height: 1.5,
                      color: scheme.onSurface.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (dateText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: scheme.onSurface.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "يمكنك متابعة تفاصيل الطلب من هنا".tr,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
                if (needsPriceConfirm && requestId.isNotEmpty)
                  _priceConfirmButton(
                    context: context,
                    controller: widget.controller,
                    requestId: requestId,
                  ),
                if (canCancel && requestId.isNotEmpty)
                  _cancelButton(
                    context: context,
                    controller: widget.controller,
                    requestId: requestId,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceConfirmButton({
    required BuildContext context,
    required CustomerRequestsController controller,
    required String requestId,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Colors.amber;

    return TextButton.icon(
      onPressed: () async {
        final reqId = requestId;
        final details = await controller.fetchRequestDetails(reqId);
        final price = _extractProposedPrice(details ?? {});
        if (price == null || price <= 0) {
          AppSnackBar.show('تنبيه'.tr, 'السعر غير متاح'.tr);
          return;
        }

        await Get.to(
          () => CustomerRequestPriceConfirmView(
            price: price,
            requestId: reqId,
            onAccept: ({
              required double price,
              required String notes,
              String? requestId,
            }) async {
              await controller.decidePrice(
                id: requestId ?? reqId,
                action: 'accept',
                notes: notes,
                price: price,
              );
              await controller.fetchActiveRequests(force: true);
            },
            onReject: ({
              required double price,
              required String notes,
              String? requestId,
            }) async {
              await controller.decidePrice(
                id: requestId ?? reqId,
                action: 'reject',
                notes: notes,
                price: price,
              );
              await controller.fetchActiveRequests(force: true);
            },
          ),
        );
      },
      icon: Icon(Icons.price_check, color: accent.shade700, size: 18),
      label: Text(
        'تأكيد السعر'.tr,
        style: TextStyle(
          color: accent.shade700,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurface,
      ),
    );
  }

  Widget _cancelButton({
    required BuildContext context,
    required CustomerRequestsController controller,
    required String requestId,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final danger = scheme.error;

    return TextButton.icon(
      onPressed: _cancelLoading
          ? null
          : () async {
              final ok = await _confirmCancel(context);
              if (!ok) return;

              setState(() => _cancelLoading = true);
              try {
                await controller.cancelRequest(requestId);
                await controller.fetchActiveRequests(force: true);
              } finally {
                if (mounted) {
                  setState(() => _cancelLoading = false);
                }
              }
            },
      icon: _cancelLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.close, color: danger, size: 18),
      label: Text(
        _cancelLoading ? 'جارٍ...'.tr : 'إلغاء'.tr,
        style: TextStyle(
          color: danger,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;

    final res = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إلغاء الطلب'.tr,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد إلغاء هذا الطلب؟'.tr,
          style: TextStyle(fontFamily: 'Cairo', color: scheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'رجوع'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              'إلغاء الطلب'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    return res ?? false;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y  $h:$min';
    } catch (_) {
      return '';
    }
  }

  double? _extractProposedPrice(Map<String, dynamic> details) {
    final pricing = details["pricing"];
    if (pricing is Map && pricing["proposedPrice"] != null) {
      return _toDouble(pricing["proposedPrice"]);
    }
    final price = details["price"] ?? details["agreedPrice"];
    return _toDouble(price);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}


