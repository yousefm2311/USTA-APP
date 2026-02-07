import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

/// Repository that debounces duplicate request calls and normalizes responses.
class ArtisanRequestsRepository {
  final ArtisanApi _api;
  final Map<String, Future<List<Map<String, dynamic>>>> _inFlight = {};

  ArtisanRequestsRepository({ArtisanApi? api}) : _api = api ?? ArtisanApi();

  Future<List<Map<String, dynamic>>> getNewRequests() {
    return _fetch('new', _api.newRequests);
  }

  Future<List<Map<String, dynamic>>> getActiveRequests() {
    return _fetch('active', _api.activeRequests);
  }

  Future<List<Map<String, dynamic>>> getHistoryRequests() {
    return _fetch('history', _api.requestsHistory);
  }

  Future<List<Map<String, dynamic>>> _fetch(
    String key,
    Future<dynamic> Function() action,
  ) {
    if (_inFlight.containsKey(key)) {
      return _inFlight[key]!;
    }
    final future = action().then(_normalizeToList).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  List<Map<String, dynamic>> _normalizeToList(dynamic response) {
    final data = ApiClient.instance.unwrapData(response);
    if (data is List) {
      return data
          .map<Map<String, dynamic>>(
            (element) => (element as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          )
          .toList();
    }
    if (data is Map<String, dynamic>) {
      dynamic list = data['items'] ?? data['requests'];
      // If backend wraps payload as {data: {requests: [...]}}
      if (list == null && data['data'] is Map) {
        final inner = data['data'] as Map;
        list = inner['requests'] ?? inner['items'] ?? inner['data'];
      } else if (list == null) {
        list = data['data'];
      }
      if (list is List) {
        return list
            .map<Map<String, dynamic>>(
              (element) => (element as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{},
            )
            .toList();
      }
    }
    return [];
  }
}

