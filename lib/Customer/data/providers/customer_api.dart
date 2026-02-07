import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_client.dart';
import 'package:usta/Customer/core/utils/constants/api_endpoints.dart';


class CustomerApi {
  final ApiClient _client = Get.find<ApiClient>(tag: 'customer');

  Map<String, dynamic> _clean(Map<String, dynamic> payload) {
    payload.removeWhere((_, v) => v == null);
    return payload;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }


  Future<Map<String, dynamic>> signup({
    required String name,
    required String password,
    String? phone,
    String? email,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.signup,
      data: _clean({
        'name': name,
        'password': password,
        'phone': phone,
        'email': email,
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> login({
    required String password,
    String? phone,
    String? email,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.login,
      data: _clean({'password': password, 'phone': phone, 'email': email}),
    );
    return _asMap(response.data);
  }

  Future<void> logout() => _client.post(ApiEndpoints.logout);

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.refresh,
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> verify({
    required String code,
    String? email,
    String? phone,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.verify,
      data: _clean({'code': code, 'email': email, 'phone': phone}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> forgotPassword({
    String? email,
    String? phone,
    String? code,
    String? newPassword,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.forgotPassword,
      data: _clean({
        'email': email,
        'phone': phone,
        'code': code,
        'newPassword': newPassword,
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> verifyResetCode({
    String? email,
    String? phone,
    required String code,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.verifyResetCode,
      data: _clean({'email': email, 'phone': phone, 'code': code}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> verifyForgotPasswordCode({
    String? email,
    String? phone,
    required String code,
  }) async {
    return verifyResetCode(email: email, phone: phone, code: code);
  }

  Future<Map<String, dynamic>> resendVerificationCode({
    String? email,
    String? phone,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.resendVerification,
      data: _clean({'email': email, 'phone': phone}),
    );
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> me() async {
    final response = await _client.get<dynamic>(ApiEndpoints.me);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get<dynamic>(ApiEndpoints.profile);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
  }) async {
    final response = await _client.put<dynamic>(
      ApiEndpoints.profile,
      data: _clean({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadPhoto(String photoBase64) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.uploadPhoto,
      data: {'photo': photoBase64},
    );
    return _asMap(response.data);
  }

  Future<void> deleteAccount() async {
    await _client.delete(ApiEndpoints.deleteAccount);
  }

  Future<Map<String, dynamic>> updateMe({
    String? name,
    String? phone,
    String? email,
    String? address,
  }) async {
    final response = await _client.put<dynamic>(
      ApiEndpoints.updateMe,
      data: _clean({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      }),
    );
    return _asMap(response.data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }


  Future<void> updateNotificationSettings({
    bool? marketing,
    bool? requests,
    bool? chat,
  }) async {
    await _client.put(
      ApiEndpoints.notificationsSettings,
      data: _clean({
        'marketing': marketing,
        'requests': requests,
        'chat': chat,
      }),
    );
  }

  Future<void> setLanguage(String language) async {
    await _client.put(ApiEndpoints.language, data: {'language': language});
  }

  Future<void> setTheme(String theme) async {
    await _client.put(ApiEndpoints.theme, data: {'theme': theme});
  }

  Future<Map<String, dynamic>> setOnline({
    bool? online,
    String? unavailableUntil,
  }) async {
    final data = <String, dynamic>{};
    if (online != null) data['online'] = online;
    if (unavailableUntil != null) data['unavailableUntil'] = unavailableUntil;
    final response = await _client.put<dynamic>(
      ApiEndpoints.online,
      data: data,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getOnlineStatus() async {
    final response = await _client.get<dynamic>(ApiEndpoints.online);
    return _asMap(response.data);
  }

  Future<void> setAvailability(List<dynamic> slots) async {
    await _client.put(ApiEndpoints.availability, data: {'slots': slots});
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _client.get<dynamic>(ApiEndpoints.settings);
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> categories() async {
    final response = await _client.get<dynamic>(ApiEndpoints.categories);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> searchArtisans({
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.searchArtisans,
      query: query,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> artisanDetails(String id) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.artisanDetails(id),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> nearbyArtisans({
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.artisanNearby,
      query: query,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> topRatedArtisans({
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.artisanTopRated,
      query: query,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> artisansInArea({
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.artisanArea,
      query: query,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> artisanNearby({
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.artisanNearby,
      query: query,
    );
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> createRequest({
    String? serviceType,
    String? artisanId,
    double? lat,
    double? lng,
    String? address,
    String? description,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.createRequest,
      data: _clean({
        'serviceType': serviceType,
        'artisanId': artisanId,
        'lat': lat,
        'lng': lng,
        'address': address,
        'description': description,
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> addRequestImages({
    required String requestId,
    required List<dynamic> images,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.requestImages(requestId),
      data: {'images': images},
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> activeRequests() async {
    final response = await _client.get<dynamic>(ApiEndpoints.activeRequests);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> requestsHistory() async {
    final response = await _client.get<dynamic>(ApiEndpoints.requestsHistory);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> requestDetails(String id) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.requestDetails(id),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> requestDetailsPublic(String id) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.requestDetailsPublic(id),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> requestTimeline(String id) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.requestTimeline(id),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> cancelRequest({
    required String id,
    String? reason,
  }) async {
    final response = await _client.delete<dynamic>(
      ApiEndpoints.cancelRequest(id),
      data: _clean({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> confirmCompletion({
    required String id,
    String? note,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.confirmCompletion(id),
      data: _clean({'note': note}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> decidePrice({
    required String id,
    required String action,
    String? notes,
    num? price,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.requestPriceDecision(id),
      data: _clean({
        'action': action,
        'notes': notes,
        if (price != null) 'price': price,
      }),
    );
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> createReview({
    required String artisanId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.createReview(artisanId),
      data: _clean({'rating': rating, 'comment': comment}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateReview({
    required String id,
    int? rating,
    String? comment,
  }) async {
    final response = await _client.put<dynamic>(
      ApiEndpoints.review(id),
      data: _clean({'rating': rating, 'comment': comment}),
    );
    return _asMap(response.data);
  }

  Future<void> deleteReview(String id) async {
    await _client.delete(ApiEndpoints.review(id));
  }

  Future<Map<String, dynamic>> myReviews() async {
    final response = await _client.get<dynamic>(ApiEndpoints.myReviews);
    return _asMap(response.data);
  }


  Future<void> addFavorite(String artisanId) async {
    await _client.post(ApiEndpoints.addFavorite(artisanId));
  }

  Future<void> removeFavorite(String artisanId) async {
    await _client.delete(ApiEndpoints.removeFavorite(artisanId));
  }

  Future<Map<String, dynamic>> listFavorites() async {
    final response = await _client.get<dynamic>(ApiEndpoints.favorites);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> viewHistory() async {
    final response = await _client.get<dynamic>(ApiEndpoints.viewHistory);
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> createPayment({
    required String requestId,
    required num amount,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.payment,
      data: {'requestId': requestId, 'amount': amount},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String requestId,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.paymentIntent,
      data: {'requestId': requestId},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> paymentReceipt(String id) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.paymentReceipt(id),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> wallet() async {
    final response = await _client.get<dynamic>(ApiEndpoints.wallet);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> rechargeWallet(num amount) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.walletRecharge,
      data: {'amount': amount},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> walletHistory() async {
    final response = await _client.get<dynamic>(ApiEndpoints.walletHistory);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> notifications() async {
    final response = await _client.get<dynamic>(ApiEndpoints.notifications);
    return _asMap(response.data);
  }

  Future<void> markNotificationRead(String id) async {
    await _client.put(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> deleteNotification(String id) async {
    await _client.delete(ApiEndpoints.deleteNotification(id));
  }

  Future<void> saveFcmToken({
    required String token,
    required String deviceId,
  }) async {
    await _client.post(
      ApiEndpoints.fcmToken,
      data: {'token': token, 'deviceId': deviceId},
    );
  }

  Future<void> subscribeTopic({
    required String topic,
    required String deviceId,
  }) async {
    await _client.post(
      ApiEndpoints.subscribeTopic,
      data: {'topic': topic, 'deviceId': deviceId},
    );
  }

  Future<void> unsubscribeTopic({
    required String topic,
    required String deviceId,
  }) async {
    await _client.post(
      ApiEndpoints.unsubscribeTopic,
      data: {'topic': topic, 'deviceId': deviceId},
    );
  }

  Future<Map<String, dynamic>> listFcmTokens() async {
    final response = await _client.get<dynamic>(ApiEndpoints.listFcmTokens);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> listTokensById(String id) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.listTokensById(id),
    );
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> activeBanners({
    String? city,
    String? category,
    String? userType,
  }) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.activeBanners,
      query: _clean({
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (userType != null && userType.trim().isNotEmpty)
          'userType': userType.trim(),
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> createComplaint({
    required String issue,
    String? artisanId,
    String? requestId,
    String? type,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.complaints,
      data: _clean({
        'issue': issue,
        'artisanId': artisanId,
        'requestId': requestId,
        'type': type,
      }),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> listComplaints() async {
    final response = await _client.get<dynamic>(ApiEndpoints.complaints);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getComplaint(String id) async {
    final response = await _client.get<dynamic>(ApiEndpoints.complaint(id));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> postComplaintMessage({
    required String id,
    required String message,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.complaintMessages(id),
      data: {'message': message},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.get<dynamic>(ApiEndpoints.dashboard);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> stats() async {
    final response = await _client.get<dynamic>(ApiEndpoints.stats);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> coupons() async {
    final response = await _client.get<dynamic>(ApiEndpoints.coupons);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.applyCoupon,
      data: {'code': code},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> referral(String code) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.referral,
      data: {'code': code},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> rewards() async {
    final response = await _client.get<dynamic>(ApiEndpoints.rewards);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> recommendations() async {
    final response = await _client.get<dynamic>(ApiEndpoints.recommendations);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> liveMap({
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    final query = <String, dynamic>{};
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;
    if (radiusKm != null) query['radiusKm'] = radiusKm;

    final response = await _client.get<dynamic>(
      ApiEndpoints.liveMap,
      query: query.isEmpty ? null : query,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> aiFeedback({String? feedback}) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.aiFeedback,
      query: feedback != null && feedback.isNotEmpty
          ? {'message': feedback}
          : null,
    );
    return _asMap(response.data);
  }


  Future<Map<String, dynamic>> openChat(String requestId) async {
    final response = await _client.post<dynamic>(ApiEndpoints.chat(requestId));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> listChats() async {
    final response = await _client.get<dynamic>(ApiEndpoints.chats);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> chatMessages(String requestId) async {
    final response = await _client.get<dynamic>(ApiEndpoints.chat(requestId));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String requestId,
    required String type,
    String? message,
    List<dynamic>? attachments,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.chatMessage,
      data: _clean({
        'requestId': requestId,
        'type': type,
        'message': message,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      }),
    );
    return _asMap(response.data);
  }

  Future<void> markChatRead(String messageId) async {
    await _client.put(ApiEndpoints.chatRead(messageId));
  }


  Future<Map<String, dynamic>> directInbox() async {
    final response = await _client.get<dynamic>(ApiEndpoints.chatDirectInbox);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> directMessages(String otherId) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.chatDirect(otherId),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> sendDirectMessage({
    required String otherId,
    required String message,
    String? type,
    List<dynamic>? attachments,
  }) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.chatDirectMessage,
      data: _clean({
        'otherId': otherId,
        'message': message,
        'type': type,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      }),
    );
    return _asMap(response.data);
  }

  Future<void> markDirectRead(String messageId) async {
    await _client.put(ApiEndpoints.chatDirectRead(messageId));
  }

  Future<Map<String, dynamic>> updateDirectMessage({
    required String messageId,
    required String text,
  }) async {
    final response = await _client.put<dynamic>(
      ApiEndpoints.chatDirectMessageUpdate(messageId),
      data: {'text': text},
    );
    return _asMap(response.data);
  }

  Future<void> deleteDirectMessage(String messageId) async {
    await _client.delete(ApiEndpoints.chatDirectMessageDelete(messageId));
  }

  Future<void> deleteDirectConversation(String otherId) async {
    await _client.delete(ApiEndpoints.chatDirectDeleteConversation(otherId));
  }
}


