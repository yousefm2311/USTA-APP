// import 'dart:async';
// import 'dart:convert';
// import 'package:get/get.dart';
// import '../network_v2/api_client_v2.dart';
// import '../network_v2/api_response_parser.dart';
// import '../network_v2/api_exception.dart';
// import '../utils/constants/api_endpoints_v2.dart';
// import 'token_storage_v2.dart';

// class AuthServiceV2 extends GetxService {
//   static AuthServiceV2 get to => Get.find<AuthServiceV2>();
//   final _ready = Completer<void>();
//   String? _accessToken;
//   String? _refreshToken;
//   final _authStream = StreamController<bool>.broadcast();

//   Future<AuthServiceV2> init() async {
//     final tokens = await TokenStorageV2.instance.readTokens();
//     _accessToken = tokens['access'];
//     _refreshToken = tokens['refresh'];
//     ApiClientV2 client = Get.find();
//     client.setTokens(_accessToken, _refreshToken);
//     _authStream.add(isAuthenticated);
//     if (!_ready.isCompleted) _ready.complete();
//     return this;
//   }

//   bool get isAuthenticated => (_accessToken ?? '').isNotEmpty;
//   Stream<bool> get authenticatedStream => _authStream.stream;
//   Future<void> waitForAuthentication() => _ready.future;
//   String? get customerId {
//     final token = _accessToken;
//     if (token == null || !token.contains('.')) return null;
//     final parts = token.split('.');
//     if (parts.length < 2) return null;
//     try {
//       final payload =
//           jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
//       return payload['id']?.toString() ?? payload['sub']?.toString();
//     } catch (_) {
//       return null;
//     }
//   }

//   Future<void> saveTokens(String access, String refresh) async {
//     _accessToken = access;
//     _refreshToken = refresh;
//     await TokenStorageV2.instance.saveTokens(access, refresh);
//     Get.find<ApiClientV2>().setTokens(access, refresh);
//     _authStream.add(true);
//   }

//   Future<void> clearTokens() async {
//     _accessToken = null;
//     _refreshToken = null;
//     await TokenStorageV2.instance.clear();
//     Get.find<ApiClientV2>().setTokens(null, null);
//     _authStream.add(false);
//   }

//   Future<void> refresh() async {
//     if (_refreshToken == null) {
//       throw ApiException(message: 'No refresh token');
//     }
//     final res = await Get.find<ApiClientV2>()
//         .post(ApiEndpointsV2.refreshToken, data: {'refreshToken': _refreshToken});
//     final data = ApiResponseParser.extractData(res.data);
//     final access = data['accessToken']?.toString() ?? '';
//     final refresh = data['refreshToken']?.toString() ?? _refreshToken!;
//     await saveTokens(access, refresh);
//   }
// }
