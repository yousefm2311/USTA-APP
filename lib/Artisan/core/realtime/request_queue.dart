import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/features/artisan/requests/ui/request_dialog.dart';

class RequestQueue {
  // Singleton instance
  static final RequestQueue _instance = RequestQueue._internal();
  factory RequestQueue() => _instance;
  RequestQueue._internal();

  final Queue<Map<String, dynamic>> _queue = Queue<Map<String, dynamic>>();
  final Set<String> _processedRequestIds = {};
  final Set<String> _seenDialogs = {};
  final AppPrefs _prefs = AppPrefs();
  bool _prefsLoaded = false;

  bool _isDialogOpen = false;
  String? _currentRequestId;

  Future<void> _loadSeen() async {
    if (_prefsLoaded) return;
    await _prefs.init();
    final stored = _prefs.getStringList('seen_request_queue');
    if (stored != null) _seenDialogs.addAll(stored);
    _prefsLoaded = true;
  }

  Future<void> _persistSeen() async {
    if (!_prefsLoaded) return;
    _prefs.setStringList('seen_request_queue', _seenDialogs.toList());
  }

  /// Add a new request to the queue
  Future<void> add(Map<String, dynamic> data) async {
    await _loadSeen();
    final requestId = data['requestId'] ?? data['_id'] ?? data['id'];

    if (requestId == null) {
      developer.log(
        '[RequestQueue] Ignored request with no ID. Keys: ${data.keys}',
      );
      return;
    }

    final requestKey = requestId.toString();

    if (_seenDialogs.contains(requestKey)) {
      developer.log('[RequestQueue] Ignored seen request: $requestKey');
      return;
    }

    if (_processedRequestIds.contains(requestId.toString())) {
      developer.log('[RequestQueue] Ignored duplicate request: $requestId');
      return;
    }

    // Check if already in queue
    final isAlreadyInQueue = _queue.any((element) {
      final id = element['requestId'] ?? element['_id'] ?? element['id'];
      return id.toString() == requestId.toString();
    });

    if (isAlreadyInQueue) {
      developer.log('[RequestQueue] Request already in queue: $requestId');
      return;
    }

    developer.log('[RequestQueue] Adding request to queue: $requestId');
    _queue.add(data);
    _processedRequestIds.add(requestId.toString());

    showNextDialog();
  }

  /// Remove a request from the queue (e.g. if cancelled)
  void remove(String requestId) {
    _queue.removeWhere((element) {
      final id = element['requestId'] ?? element['_id'] ?? element['id'];
      return id.toString() == requestId;
    });

    // If the current dialog is showing this request, close it
    if (_isDialogOpen && _currentRequestId == requestId) {
      developer.log(
        '[RequestQueue] Closing dialog for cancelled request: $requestId',
      );
      if (Get.isDialogOpen == true) {
        Get.back(); // Close the dialog
      }
      _isDialogOpen = false;
      _currentRequestId = null;
      showNextDialog();
    }
  }

  /// Show the next dialog in the queue
  Future<void> showNextDialog() async {
    if (_isDialogOpen) {
      developer.log('[RequestQueue] Dialog already open, waiting...');
      return;
    }

    if (_queue.isEmpty) {
      developer.log('[RequestQueue] Queue empty');
      return;
    }

    final requestData = _queue.removeFirst();
    final requestId =
        requestData['requestId'] ?? requestData['_id'] ?? requestData['id'];

    _isDialogOpen = true;
    _currentRequestId = requestId.toString();

    try {
      developer.log('[RequestQueue] Showing dialog for: $requestId');

      await showRequestDialog(
        requestData,
        onClose: () {
          _isDialogOpen = false;
          _currentRequestId = null;
          if (requestId != null) {
            _seenDialogs.add(requestId.toString());
            _persistSeen();
          }
          // Add a small delay to prevent rapid flashing
          Future.delayed(const Duration(milliseconds: 300), () {
            showNextDialog();
          });
        },
      );
    } catch (e) {
      developer.log('[RequestQueue] Error showing dialog: $e');
      _isDialogOpen = false;
      _currentRequestId = null;
      showNextDialog(); // Try next one
    }
  }

  void clear() {
    _queue.clear();
    _processedRequestIds.clear();
    _isDialogOpen = false;
    _currentRequestId = null;
  }
}

