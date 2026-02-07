import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/chat/views/image_viewer_page.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanAcceptRequestView extends StatefulWidget {
  const ArtisanAcceptRequestView({super.key});

  @override
  State<ArtisanAcceptRequestView> createState() =>
      _ArtisanAcceptRequestViewState();
}

class _ArtisanAcceptRequestViewState extends State<ArtisanAcceptRequestView> {
  final priceCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  late final String requestId;
  Map<String, dynamic>? requestData;

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;

    // دعم أكتر من شكل للـ arguments
    if (args is Map) {
      final map = args.map((k, v) => MapEntry(k.toString(), v));
      requestId = (map['requestId'] ?? map['_id'] ?? map['id'] ?? '')
          .toString();

      final reqArg = map['request'];
      if (reqArg is Map) {
        requestData = reqArg.cast<String, dynamic>();
      } else {
        // أحيانًا بيبعت request نفسه
        requestData = map.cast<String, dynamic>();
      }
    } else {
      requestId = '';
      requestData = null;
    }
  }

  @override
  void dispose() {
    priceCtrl.dispose();
    timeCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  String get customerName {
    final customer = requestData?['customer'];
    if (customer is Map) return (customer['name'] ?? 'عميل').toString();
    return (requestData?['customerName'] ?? 'عميل').toString();
  }

  String get customerPhone {
    final customer = requestData?['customer'];
    if (customer is Map) return (customer['phone'] ?? '--').toString();
    return (requestData?['customerPhone'] ?? '--').toString();
  }

  String get address {
    final addr =
        requestData?['address'] ??
        requestData?['location'] ??
        (requestData?['customer'] is Map
            ? (requestData?['customer'] as Map)['address']
            : null);
    return (addr ?? 'غير متوفر').toString();
  }

  String get serviceName {
    final service = requestData?['service'];
    if (service is Map) return (service['name'] ?? 'غير محدد').toString();
    return (requestData?['serviceName'] ??
            requestData?['serviceType'] ??
            'غير محدد')
        .toString();
  }

  String get scheduledAt => (requestData?['scheduledAt'] ?? '').toString();

  String get description =>
      (requestData?['description'] ?? requestData?['notes'] ?? '').toString();

  String get code =>
      (requestData?['code'] ??
              requestData?['_id'] ??
              requestData?['id'] ??
              '--')
          .toString();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = _collectImages();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // backgroundColor: scheme.background,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title:  Text("تفاصيل الطلب", style: AppTextStyles.title(context)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header mini card
            _headerMini(context),

            const SizedBox(height: 12),

            _card(context, "بيانات العميل", [
              _row(Icons.person, customerName),
              _row(Icons.phone, customerPhone),
              _row(Icons.location_on, address),
            ]),

            _card(context, "تفاصيل الطلب", [
              _row(Icons.home_repair_service, serviceName),
              _row(Icons.image, "${images.length} مرفق"),
              _row(Icons.qr_code_2, "كود الطلب: $code"),
              _row(Icons.schedule, scheduledAt.isEmpty ? "--" : scheduledAt),
              if (description.isNotEmpty) _row(Icons.notes, description),
            ]),

            if (images.isNotEmpty) _imagesSection(context, images),

            const SizedBox(height: 6),

            _formField(
              context,
              controller: priceCtrl,
              label: "السعر (اختياري)",
              prefix: const Icon(Icons.payments_outlined),
              suffix: TextButton(
                onPressed: () => setState(() => priceCtrl.text = "350"),
                child: Text(
                  "مثال 350",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            _formField(
              context,
              controller: timeCtrl,
              label: "مدة الوصول (بالدقائق)",
              prefix: const Icon(Icons.timer_outlined),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            _formField(
              context,
              controller: noteCtrl,
              label: "ملاحظة للعميل",
              maxLines: 3,
              prefix: const Icon(Icons.edit_note_outlined),
            ),

            const SizedBox(height: 16),

            _noticeBox(context),

            const SizedBox(height: 12),

            Obx(() {
              final busy = controller.submitting.value;

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => controller.fetchNewRequests(),
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: scheme.onSurface,
                      ),
                      label: Text(
                        "تحديث",
                        style: TextStyle(
                          fontFamily: "Cairo",
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 21),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: scheme.outline.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : _submit,
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        "قبول الطلب",
                        style: TextStyle(
                          fontFamily: "Cairo",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await _confirmReject(context);
                  if (!ok) return;

                  controller.rejectRequest(requestId);
                  Get.back();
                },
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  "رفض الطلب",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerMini(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: primaryBlue.withOpacity(0.12),
              border: Border.all(color: primaryBlue.withOpacity(0.25)),
            ),
            child: Icon(Icons.assignment_outlined, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "طلب جديد",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "الخدمة: $serviceName",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.orange.withOpacity(0.35)),
            ),
            child: const Text(
              "بانتظار قرار",
              style: TextStyle(
                fontFamily: "Cairo",
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryBlue.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "تأكد من مراجعة كل التفاصيل قبل الضغط على قبول الطلب.",
              style: AppTextStyles.small(context).copyWith(
                fontSize: 13, color: scheme.onSurface.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (requestId.isEmpty) {
      _showSnack(AppStrings.requestIdMissing.tr, Colors.redAccent);
      return;
    }

    final price = int.tryParse(priceCtrl.text.trim());
    final eta = int.tryParse(timeCtrl.text.trim());
    final note = noteCtrl.text.trim();

    // 👇 علشان ما نكسرش signature بتاع controller.acceptRequest
    // هنضيف مدة الوصول داخل note لو المستخدم كتبها
    final composedNote = [
      if (note.isNotEmpty) note,
      if (eta != null) 'مدة الوصول: $eta دقيقة',
    ].join(' | ');

    await controller.acceptRequest(
      requestId,
      price: price,
      note: composedNote.trim().isEmpty ? null : composedNote.trim(),
    );

    if (!controller.submitting.value) {
      Get.back();
    }
  }

  Widget _card(BuildContext context, String title, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(context))),
        ],
      ),
    );
  }

  Widget _imagesSection(BuildContext context, List<String> images) {
    final scheme = Theme.of(context).colorScheme;
    return _card(context, "صور المشكلة", [
      SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: images.length,
          itemBuilder: (_, i) {
            final url = _resolveImageUrl(images[i]);
            final heroTag = 'req_img_${requestId}_$i';
            return GestureDetector(
              onTap: () => Get.to(
                () => ImageViewerPage(url: url, heroTag: heroTag),
              ),
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    color: scheme.surfaceVariant.withOpacity(0.25),
                    child: _imageWidget(url),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _imageWidget(String url) {
    if (url.startsWith('data:image')) {
      final data = Uri.parse(url).data;
      if (data != null) {
        return Image.memory(
          data.contentAsBytes(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }

  List<String> _collectImages() {
    final urls = <String>{};
    if (requestData == null) return const [];

    void add(dynamic raw) {
      for (final item in _normalizeImages(raw)) {
        final value = item.trim();
        if (value.isEmpty) continue;
        urls.add(_resolveImageUrl(value));
      }
    }

    add(requestData?['attachments']);
    add(requestData?['images']);
    add(requestData?['photos']);

    return urls.toList();
  }

  List<String> _normalizeImages(dynamic raw) {
    if (raw == null) return const [];
    final list = <String>[];
    if (raw is List) {
      for (final e in raw) {
        list.addAll(_normalizeImages(e));
      }
      return list;
    }
    if (raw is Map) {
      final url =
          raw['url'] ?? raw['path'] ?? raw['image'] ?? raw['secure_url'];
      if (url != null) {
        list.add(url.toString());
      }
      return list;
    }
    list.add(raw.toString());
    return list;
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http') || url.startsWith('data:image')) return url;

    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;

    final baseNoApi =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;

    if (url.startsWith('/')) return '$baseNoApi$url';
    return '$baseNoApi/$url';
  }

  Widget _formField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    Widget? prefix,
    Widget? suffix,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix,
        suffix: suffix, // ✅ بدل suffixIcon عشان TextButton ما يعملش مشاكل
        labelStyle: AppTextStyles.body(context).copyWith(
          color: scheme.onSurface.withOpacity(0.75),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.30)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: primaryBlue.withOpacity(0.9),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    final type =
        color == Colors.redAccent ? SnackBarType.error : SnackBarType.info;
    final title = type == SnackBarType.error
        ? AppStrings.error.tr
        : AppStrings.info.tr;
    AppSnackBar.show(
      title,
      message,
      type: type,
    );
  }

  Future<bool> _confirmReject(BuildContext context) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              "تأكيد الرفض",
              style: TextStyle(
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            content: const Text(
              "هل أنت متأكد إنك عايز ترفض الطلب؟",
              style: TextStyle(fontFamily: "Cairo"),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "إلغاء",
                  style: TextStyle(fontFamily: "Cairo"),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "رفض",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }
}

