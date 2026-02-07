import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/customer/complaints/controllers/customer_complaints_controller.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';

class CustomerComplaintCreateView extends StatefulWidget {
  const CustomerComplaintCreateView({super.key});

  @override
  State<CustomerComplaintCreateView> createState() =>
      _CustomerComplaintCreateViewState();
}

class _CustomerComplaintCreateViewState
    extends State<CustomerComplaintCreateView> {
  final controller = Get.find<CustomerComplaintsController>();
  final requestsController = Get.find<CustomerRequestsController>();
  final formKey = GlobalKey<FormState>();

  final issueCtrl = TextEditingController();
  final artisanCtrl = TextEditingController();
  final artisanNameCtrl = TextEditingController();
  final requestCtrl = TextEditingController();
  final typeCtrl = TextEditingController();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  Map<String, dynamic>? _selectedArtisan;
  Map<String, dynamic>? _selectedRequest;
  String? _lastArtisanLookupId;
  bool _artisanLookupInFlight = false;

  @override
  void initState() {
    super.initState();
    requestsController.fetchHistoryRequests();
    requestsController.fetchActiveRequests();
  }

  @override
  void dispose() {
    issueCtrl.dispose();
    artisanCtrl.dispose();
    artisanNameCtrl.dispose();
    requestCtrl.dispose();
    typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "إنشاء شكوى".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field("موضوع الشكوى", issueCtrl,
                required: true, minLength: 3, maxLines: 3),
            _artisanSelector(),
            _field("اسم الفني", artisanNameCtrl, readOnly: true),
            _field(
              "معرف الفني (اختياري 24 رقم/حرف)",
              artisanCtrl,
              onChanged: _handleArtisanIdChanged,
            ),
            _requestSelector(),
            _field("معرف الطلب (اختياري 24 رقم/حرف)", requestCtrl),
            _field("النوع (اختياري)", typeCtrl),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: controller.sending.value ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  controller.sending.value
                      ? "جارٍ الإرسال...".tr
                      : "إرسال".tr,
                  style: const TextStyle(fontFamily: "Cairo", fontSize: 16,color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(String title, TextEditingController ctrl,
      {bool required = false,
      int? minLength,
      int maxLines = 1,
      bool readOnly = false,
      ValueChanged<String>? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            readOnly: readOnly,
            validator: required
                ? (v) {
                    if (v == null || v.trim().isEmpty) return 'حقل مطلوب'.tr;
                    if (minLength != null && v.trim().length < minLength) {
                      return 'الحد الأدنى @minLength أحرف'.trParams(
                        {'minLength': minLength.toString()},
                      );
                    }
                    return null;
                  }
                : null,
            onChanged: onChanged,
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }

  Widget _artisanSelector() {
    return Obx(() {
      final history = requestsController.historyRequests;
      final active = requestsController.activeRequests;
      final _ = history.length + active.length;
      final artisans = _recentArtisans(history, active);
      final selectedId = _selectedArtisan?['id']?.toString();
      final value = artisans.any((e) => e['id'] == selectedId)
          ? selectedId
          : null;
      return _dropdownField(
        title: "اختر الفني (آخر 10)",
        value: value,
        items: artisans,
        labelBuilder: (item) => _artisanLabel(item),
        onChanged: (id) {
          final artisan = _findById(artisans, id);
          setState(() {
            _selectedArtisan = artisan;
            _selectedRequest = null;
            artisanCtrl.text = artisan?['id']?.toString() ?? '';
            artisanNameCtrl.text = artisan?['name']?.toString() ?? '';
            requestCtrl.clear();
          });
          final artisanId = artisan?['id']?.toString() ?? '';
          if (artisanNameCtrl.text.trim().isEmpty && artisanId.isNotEmpty) {
            _fetchArtisanNameById(artisanId);
          }
        },
        emptyText: "لا يوجد فنيون مؤخرا.",
      );
    });
  }

  Widget _requestSelector() {
    return Obx(() {
      final history = requestsController.historyRequests;
      final active = requestsController.activeRequests;
      final _ = history.length + active.length;
      final artisanId = _selectedArtisan?['id']?.toString();
      final requests = artisanId == null || artisanId.isEmpty
          ? <Map<String, dynamic>>[]
          : _requestsForArtisan(artisanId, history, active);
      final selectedId = _selectedRequest?['id']?.toString();
      final value = requests.any((e) => e['id'] == selectedId)
          ? selectedId
          : null;
      return _dropdownField(
        title: "اختر الطلب الخاص بهذا الفني",
        value: value,
        items: requests,
        labelBuilder: (item) => _requestLabel(item),
        onChanged: (id) {
          final request = _findById(requests, id);
          setState(() {
            _selectedRequest = request;
            requestCtrl.text = request?['id']?.toString() ?? '';
            final artisan = request == null ? null : _extractArtisan(request);
            final artisanId = artisan?['id']?.toString() ?? '';
            final artisanName = artisan?['name']?.toString() ?? '';
            if (artisanId.isNotEmpty && artisanCtrl.text.trim().isEmpty) {
              artisanCtrl.text = artisanId;
            }
            if (artisanName.isNotEmpty) {
              artisanNameCtrl.text = artisanName;
            } else if (artisanId.isNotEmpty) {
              _fetchArtisanNameById(artisanId);
            }
          });
        },
        emptyText: artisanId == null || artisanId.isEmpty
            ? "اختر الفني أولا."
            : "لا توجد طلبات لهذا الفني.",
      );
    });
  }

  Widget _dropdownField({
    required String title,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) labelBuilder,
    required void Function(String?) onChanged,
    required String emptyText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.tr, style: const TextStyle(fontFamily: 'Cairo')),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item['id']?.toString(),
                    child: Text(
                      labelBuilder(item),
                      style: const TextStyle(fontFamily: 'Cairo'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: items.isEmpty ? null : onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              hintText: emptyText.tr,
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _recentArtisans(
    List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> active,
  ) {
    final requests = _collectRequests(history, active);
    final seen = <String>{};
    final artisans = <Map<String, dynamic>>[];

    for (final request in requests) {
      final artisan = _extractArtisan(request);
      final id = artisan['id']?.toString();
      if (id == null || id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      artisans.add(artisan);
      if (artisans.length >= 10) break;
    }

    return artisans;
  }

  List<Map<String, dynamic>> _requestsForArtisan(
    String artisanId,
    List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> active,
  ) {
    final requests = _collectRequests(history, active)
        .where((request) => _extractArtisanId(request) == artisanId)
        .map((request) => _extractRequestInfo(request))
        .where((request) => (request['id']?.toString() ?? '').isNotEmpty)
        .toList();
    return requests;
  }

  List<Map<String, dynamic>> _collectRequests(
    List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> active,
  ) {
    final items = <Map<String, dynamic>>[];
    items.addAll(history);
    items.addAll(active);
    items.sort((a, b) => _compareByDateDesc(a, b));
    return items;
  }

  int _compareByDateDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ta = _parseDate(a['createdAt']);
    final tb = _parseDate(b['createdAt']);
    return tb.compareTo(ta);
  }

  DateTime _parseDate(dynamic input) {
    if (input == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(input.toString());
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _handleArtisanIdChanged(String value) {
    final id = value.trim();
    if (id.length != 24) {
      if (_selectedArtisan == null) {
        artisanNameCtrl.clear();
      }
      return;
    }
    final name = _findArtisanNameById(id);
    if (name.isNotEmpty) {
      if (artisanNameCtrl.text.trim() != name) {
        artisanNameCtrl.text = name;
      }
      return;
    }
    _fetchArtisanNameById(id);
  }

  String _findArtisanNameById(String artisanId) {
    final history = requestsController.historyRequests;
    final active = requestsController.activeRequests;
    final _ = history.length + active.length;
    final requests = _collectRequests(history, active);
    for (final request in requests) {
      final artisan = _extractArtisan(request);
      if (artisan['id']?.toString() == artisanId) {
        final name = artisan['name']?.toString() ?? '';
        if (name.trim().isNotEmpty) return name.trim();
      }
    }
    return '';
  }

  Future<void> _fetchArtisanNameById(String artisanId) async {
    if (artisanId.isEmpty) return;
    if (_artisanLookupInFlight && _lastArtisanLookupId == artisanId) return;
    if (artisanNameCtrl.text.trim().isNotEmpty) return;

    _lastArtisanLookupId = artisanId;
    _artisanLookupInFlight = true;
    try {
      if (!Get.isRegistered<CustomerRepository>()) return;
      final repo = Get.find<CustomerRepository>();
      final res = await repo.api.artisanDetails(artisanId);
      final raw =
          res['artisan'] ??
          (res['data'] is Map ? (res['data'] as Map)['artisan'] : null) ??
          res['data'] ??
          res;
      if (raw is! Map) return;
      final name = _nameFromMap(Map<String, dynamic>.from(raw));
      if (name.isEmpty) return;
      if (artisanCtrl.text.trim() != artisanId) return;
      artisanNameCtrl.text = name;
    } catch (_) {
    } finally {
      _artisanLookupInFlight = false;
    }
  }

  String _nameFromRequest(Map<String, dynamic> request) {
    return _firstNonEmpty([
      request['artisanName'],
      request['artisan_name'],
      request['artisanFullName'],
      request['artisan_full_name'],
      request['artisanUsername'],
      request['artisan_username'],
      request['artisanDisplayName'],
      request['artisan_display_name'],
    ]);
  }

  String _nameFromMap(Map<String, dynamic> map, {String? fallback}) {
    final direct = _firstNonEmpty([
      map['name'],
      map['fullName'],
      map['full_name'],
      map['username'],
      map['artisanName'],
      map['artisan_name'],
      map['displayName'],
      map['display_name'],
      map['title'],
    ]);
    if (direct.isNotEmpty) return direct;

    final first = _firstNonEmpty([map['firstName'], map['first_name']]);
    final last = _firstNonEmpty([map['lastName'], map['last_name']]);
    final combined = [first, last].where((e) => e.isNotEmpty).join(' ');
    if (combined.isNotEmpty) return combined;

    final nested = map['user'] ?? map['account'] ?? map['profile'];
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      final nestedName = _nameFromMap(nestedMap);
      if (nestedName.isNotEmpty) return nestedName;
    }

    return (fallback ?? '').toString().trim();
  }

  String _firstNonEmpty(List<dynamic> candidates) {
    for (final item in candidates) {
      if (item == null) continue;
      final value = item.toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Map<String, dynamic> _extractArtisan(Map<String, dynamic> request) {
    final artisanRaw =
        request['artisan'] ?? request['artisanId'] ?? request['artisan_id'];
    if (artisanRaw is Map) {
      final map = Map<String, dynamic>.from(artisanRaw);
      return {
        'id': map['_id'] ?? map['id'] ?? map['artisanId'] ?? map['artisan_id'],
        'name': _nameFromMap(map, fallback: _nameFromRequest(request)),
      };
    }
    return {
      'id': artisanRaw?.toString(),
      'name': _nameFromRequest(request),
    };
  }

  String _extractArtisanId(Map<String, dynamic> request) {
    final artisan = _extractArtisan(request);
    return artisan['id']?.toString() ?? '';
  }

  Map<String, dynamic> _extractRequestInfo(Map<String, dynamic> request) {
    return {
      'id': request['_id'] ?? request['id'] ?? request['requestId'],
      'service': request['serviceType'] ??
          request['service'] ??
          request['category'] ??
          request['title'],
      'createdAt': request['createdAt'],
    };
  }

  String _artisanLabel(Map<String, dynamic> artisan) {
    final name = artisan['name']?.toString();
    final id = artisan['id']?.toString() ?? '';
    if (name == null || name.isEmpty) return id;
    return "$name - ${_shortId(id)}";
  }

  String _requestLabel(Map<String, dynamic> request) {
    final service = request['service']?.toString() ?? '';
    final id = request['id']?.toString() ?? '';
    final date = _parseDate(request['createdAt']);
    final dateText =
        date.year == 1970 ? '' : "${date.year}/${date.month}/${date.day}";
    if (service.isNotEmpty && dateText.isNotEmpty) {
      return "$service - $dateText - ${_shortId(id)}";
    }
    if (service.isNotEmpty) return "$service - ${_shortId(id)}";
    return _shortId(id);
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return "${id.substring(0, 4)}...${id.substring(id.length - 4)}";
  }

  Map<String, dynamic>? _findById(
      List<Map<String, dynamic>> items, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final item in items) {
      if (item['id']?.toString() == id) return item;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    final issue = issueCtrl.text.trim();
    final artisan = artisanCtrl.text.trim();
    final request = requestCtrl.text.trim();
    final type = typeCtrl.text.trim();
    final success = await controller.createComplaint(
      issue: issue,
      artisanId: artisan.length == 24 ? artisan : null,
      requestId: request.length == 24 ? request : null,
      type: type.isEmpty ? null : type,
    );
    if (!mounted) return;
    if (success) {
      Get.back();
      AppSnackBar.show('تم'.tr, 'تم إرسال الشكوى بنجاح'.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      AppSnackBar.show('خطأ'.tr, 'تعذر إرسال الشكوى، تأكد من صحة البيانات'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}


