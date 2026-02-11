import 'package:get/get.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';


class CustomerComplaintsController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<Map<String, dynamic>> complaints = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> selected = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final RxBool loading = false.obs;
  final RxBool loadingDetail = false.obs;
  final RxBool sending = false.obs;
  final RxBool refreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    loading.value = true;
    try {
      final res = await _repo.api.listComplaints();
      final list = res['complaints'] ?? res['data'] ?? res;
      if (list is List) {
        complaints.assignAll(
          list
              .map<Map<String, dynamic>>(
                  (e) => e is Map<String, dynamic> ? _normalizeComplaint(e) : {})
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      }
    } on ApiException catch (e) {
      _handleApiError(e);
    } finally {
      loading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchComplaint(String id) async {
    loadingDetail.value = true;
    try {
      final res = await _repo.api.getComplaint(id);
      final data = res['complaint'] ?? res['data'] ?? res;
      if (data is Map<String, dynamic>) {
        final normalized = _normalizeComplaint(data);
        selected.value = normalized;
        final msgs = normalized['messages'] ?? [];
        if (msgs is List) {
          messages.assignAll(msgs.whereType<Map<String, dynamic>>());
          _sortMessages();
        }
        return normalized;
      }
    } on ApiException catch (e) {
      _handleApiError(e);
      return null;
    } finally {
      loadingDetail.value = false;
    }
    return null;
  }

  Future<bool> createComplaint({
    required String issue,
    String? artisanId,
    String? requestId,
    String? type,
  }) async {
    sending.value = true;
    try {
      final res = await _repo.api.createComplaint(
        issue: issue,
        artisanId: artisanId,
        requestId: requestId,
        type: type,
      );
      final data = res['complaint'] ?? res['data'] ?? res;
      if (data is Map<String, dynamic>) {
        complaints.insert(0, _normalizeComplaint(data));
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      sending.value = false;
    }
  }

  Future<void> sendMessage(String id, String message) async {
    sending.value = true;
    try {
      final res = await _repo.api.postComplaintMessage(
        id: id,
        message: message,
      );
      final msg = res['message'] ?? res['data'] ?? res;
      final normalized = _normalizeMessage(msg ?? {'message': message});
      messages.add(normalized);
      _sortMessages();
    } on ApiException catch (e) {
      _handleApiError(e);
    } finally {
      sending.value = false;
    }
  }

  Map<String, dynamic> _normalizeComplaint(Map<String, dynamic> raw) {
    final msgs = raw['messages'] is List ? raw['messages'] as List : <dynamic>[];
    return {
      '_id': raw['_id'] ?? raw['id'],
      'issue': raw['issue'] ?? '',
      'status': raw['status'] ?? '',
      'statusLabel': _statusLabel(raw['status']?.toString()),
      'artisan': raw['artisan'] ?? raw['artisanId'],
      'request': raw['request'] ?? raw['requestId'],
      'createdAt': raw['createdAt'],
      'updatedAt': raw['updatedAt'],
      'messages': msgs.map((e) => _normalizeMessage(e)).toList(),
    };
  }

  Map<String, dynamic> _normalizeMessage(dynamic raw) {
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return {
      '_id': map['_id'] ?? map['id'],
      'message': map['message'] ?? map['text'] ?? '',
      'senderType': map['senderType'] ?? map['from'] ?? 'customer',
      'senderId': map['senderId'],
      'createdAt': map['createdAt'],
    };
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'قيد المعالجة'.tr;
      case 'in_review':
        return 'قيد المراجعة'.tr;
      case 'resolved':
        return 'تم الحل'.tr;
      case 'closed':
        return 'مغلقة'.tr;
      default:
        return status ?? 'غير معروف'.tr;
    }
  }

  void _sortMessages() {
    messages.sort((a, b) {
      final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });
  }

  void _handleApiError(ApiException e) {
    if (e.statusCode == 401) {
      if (Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      return;
    }
    final msg = e.message.isNotEmpty ? e.message : 'تعذر إكمال الطلب'.tr;
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}


