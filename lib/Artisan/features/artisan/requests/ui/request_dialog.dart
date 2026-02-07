import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

Future<void> showRequestDialog(
  Map<String, dynamic> requestData, {
  required VoidCallback onClose,
}) async {
  final api = ArtisanApi();

  // Prevent duplicates if Get.isDialogOpen is true?
  // But RequestQueue handles that.
  // However, Get.dialog might stack if we are not careful, but RequestQueue ensures sequential.

  String firstNonEmpty(List values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString();
      if (s.trim().isNotEmpty) return s;
    }
    return '';
  }

  final requestId =
      requestData['requestId'] ?? requestData['_id'] ?? requestData['id'];
  final customerName = firstNonEmpty([
    requestData['customer']?['name'],
    requestData['customerName'],
    requestData['name'],
    requestData['user']?['name'],
  ]);
  final rawService = requestData['service'];
  final serviceType = firstNonEmpty([
    requestData['serviceType'],
    requestData['serviceName'],
    rawService is Map ? rawService['name'] : rawService,
  ]);
  final address = firstNonEmpty([
    requestData['address'],
    requestData['location']?['address'],
  ]);
  final description = requestData['description']?.toString() ?? '';
  final lat = firstNonEmpty([
    requestData['lat'],
    requestData['latitude'],
    requestData['location']?['lat'],
  ]);
  final lng = firstNonEmpty([
    requestData['lng'],
    requestData['longitude'],
    requestData['location']?['lng'],
  ]);

  // If key fields are missing, try to enrich from REST.
  Map<String, dynamic> enriched = requestData;
  final needsDetails = (customerName.isEmpty ||
          serviceType.isEmpty ||
          address.isEmpty ||
          description.isEmpty) &&
      (requestId != null && requestId.toString().isNotEmpty);
  if (needsDetails) {
    try {
      final details = await api.requestDetails(requestId.toString());
      final data = ApiClient.instance.unwrapData(details);
      Map<String, dynamic> merged = {};
      if (data is Map<String, dynamic>) {
        if (data['request'] is Map<String, dynamic>) {
          merged = {...(data['request'] as Map<String, dynamic>)};
        } else {
          merged = {...data};
        }
      } else if (details is Map<String, dynamic> &&
          details['data'] is Map<String, dynamic>) {
        merged = {...(details['data'] as Map<String, dynamic>)};
      }
      if (merged.isNotEmpty) {
        enriched = {...requestData, ...merged};
      }
    } catch (_) {
      // ignore; will fall back to what we have
    }
  }

  await Get.dialog(
    PopScope(
      canPop: false, // Force user to interact
      child: RequestDialogWidget(
        requestId: requestId.toString(),
        customerName: firstNonEmpty([
          enriched['customer']?['name'],
          enriched['customerName'],
          enriched['name'],
          enriched['user']?['name'],
          customerName,
        ]),
        serviceType: firstNonEmpty([
          enriched['serviceType'],
          enriched['serviceName'],
          if (enriched['service'] is Map)
            (enriched['service'] as Map?)?['name']
          else
            enriched['service'],
          serviceType,
        ]),
        address: firstNonEmpty([
          enriched['address'],
          enriched['location']?['address'],
          address,
        ]),
        description: firstNonEmpty([
          enriched['description'],
          description,
        ]),
        lat: firstNonEmpty([
          enriched['lat'],
          enriched['latitude'],
          enriched['location']?['lat'],
          lat,
        ]),
        lng: firstNonEmpty([
          enriched['lng'],
          enriched['longitude'],
          enriched['location']?['lng'],
          lng,
        ]),
        requestData: enriched,
      ),
    ),
    barrierDismissible: false,
  );

  onClose();
}

class RequestDialogWidget extends StatefulWidget {
  final String requestId;
  final String customerName;
  final String serviceType;
  final String address;
  final String description;
  final String lat;
  final String lng;
  final Map<String, dynamic> requestData;

  const RequestDialogWidget({
    super.key,
    required this.requestId,
    required this.customerName,
    required this.serviceType,
    required this.address,
    required this.description,
    required this.lat,
    required this.lng,
    required this.requestData,
  });

  @override
  State<RequestDialogWidget> createState() => _RequestDialogWidgetState();
}

class _RequestDialogWidgetState extends State<RequestDialogWidget> {
  final ArtisanApi _api = ArtisanApi();
  bool _isLoading = false;
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      int? price;
      final priceText = _priceCtrl.text.trim();
      if (priceText.isNotEmpty) {
        price = int.tryParse(priceText);
        if (price == null || price <= 0) {
          AppSnackBar.show(
            AppStrings.invalidPriceTitle.tr,
            AppStrings.invalidPriceMessage.tr,
            type: SnackBarType.error,
          );
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }
      final noteText = _noteCtrl.text.trim();
      await _api.acceptRequest(
        widget.requestId,
        price: price,
        note: noteText.isEmpty ? null : noteText,
      );
      Get.back(); // Close dialog
      AppSnackBar.show(
        AppStrings.requestAcceptedTitle.tr,
        AppStrings.requestAcceptedMessage.tr,
        type: SnackBarType.success,
      );
    } catch (e) {
      developer.log('Error accepting request: $e');
      AppSnackBar.show(
        AppStrings.error.tr,
        AppStrings.requestAcceptFailed.tr,
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    try {
      await _api.rejectRequest(widget.requestId);
      Get.back(); // Close dialog
      AppSnackBar.show(
        AppStrings.requestRejectedTitle.tr,
        AppStrings.requestRejectedMessage.tr,
        type: SnackBarType.warning,
      );
    } catch (e) {
      developer.log('Error rejecting request: $e');
      AppSnackBar.show(
        AppStrings.error.tr,
        AppStrings.requestRejectFailed.tr,
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================
  // UI helpers (لا تؤثر على الوظيفة)
  // =========================
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.primary.withOpacity(0.95),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'Cairo',
          color: scheme.onPrimary.withOpacity(0.7),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primaryContainer,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.onPrimary.withOpacity(0.28)),
            ),
            child: Icon(
              Icons.flash_on_rounded,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Service Request',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                SizedBox(height: 2),
                Text(
                  'Review details and respond',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withOpacity(0.16),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.onPrimary.withOpacity(0.28)),
              ),
              child: Icon(
                Icons.close_rounded,
                color: scheme.onPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(BuildContext context, {double height = 14}) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Center(
        child: Divider(
          height: 1,
          color: scheme.outline.withOpacity(0.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              _sectionDivider(context, height: 14),

              // Details card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outline.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    InfoTile(
                      icon: Icons.person_rounded,
                      label: 'Customer',
                      value: widget.customerName,
                    ),
                    const SizedBox(height: 10),
                    InfoTile(
                      icon: Icons.build_rounded,
                      label: 'Service',
                      value: widget.serviceType,
                    ),
                    const SizedBox(height: 10),
                    InfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: widget.address,
                    ),
                    if (widget.lat.isNotEmpty && widget.lng.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InfoTile(
                        icon: Icons.map_rounded,
                        label: 'Location',
                        value: 'Lat: ${widget.lat}, Lng: ${widget.lng}',
                        trailing: _MapsActionButton(
                          onPressed: () {},
                        ),
                      ),
                    ],
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InfoTile(
                        icon: Icons.description_rounded,
                        label: 'Description',
                        value: widget.description,
                      ),
                    ],
                  ],
                ),
              ),

              _sectionDivider(context, height: 14),

              // Inputs card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outline.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        context,
                        label: 'Proposed price',
                        suffixText: 'EGP',
                        prefixIcon: Icon(
                          Icons.payments_rounded,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        context,
                        label: 'Note (optional)',
                        prefixIcon: Icon(
                          Icons.sticky_note_2_rounded,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _sectionDivider(context, height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _reject,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 13),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.disabled)
                              ? scheme.error.withOpacity(0.5)
                              : scheme.error,
                        ),
                        side: MaterialStateProperty.resolveWith(
                          (states) => BorderSide(
                            color: states.contains(MaterialState.disabled)
                                ? scheme.error.withOpacity(0.4)
                                : scheme.error,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: _isLoading ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Accept',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'Cairo',
          color: scheme.onSurfaceVariant.withOpacity(0.75),
        );
    final valueStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: valueStyle,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Align(alignment: Alignment.topRight, child: trailing),
          ],
        ],
      ),
    );
  }
}

class _MapsActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MapsActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        side: BorderSide(color: scheme.outline.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(
        Icons.map_outlined,
        size: 16,
        color: scheme.primary,
      ),
      label: Text(
        'Open in Maps',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


