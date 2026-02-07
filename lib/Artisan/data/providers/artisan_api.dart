import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

class ArtisanApi {
  final ApiClient _client = ApiClient.instance;

  // Auth
  Future<dynamic> signup({
    required String name,
    required String profession,
    required String email,
    required String password,
    String? phone,
  }) {
    return _client.post(ApiEndpoints.signup, data: {
      'name': name,
      'profession': profession,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
  }

  Future<dynamic> login({
    required String email,
    required String password,
  }) {
    return _client.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
  }

  Future<dynamic> verifyEmail({
    String? email,
    String? phone,
    required String code,
  }) {
    return _client.post(ApiEndpoints.verify, data: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'code': code,
    });
  }

  Future<dynamic> resendVerification(String email) {
    return _client.post(ApiEndpoints.resendVerification, data: {
      'email': email,
    });
  }

  Future<dynamic> forgotPassword({
    String? email,
    String? phone,
    String? code,
    String? newPassword,
  }) {
    return _client.post(ApiEndpoints.forgotPassword, data: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (code != null && code.isNotEmpty) 'code': code,
      if (newPassword != null && newPassword.isNotEmpty)
        'newPassword': newPassword,
    });
  }

  Future<dynamic> verifyForgotPasswordCode({
    String? email,
    String? phone,
    required String code,
  }) {
    return _client.post(ApiEndpoints.forgotPasswordVerifyCode, data: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'code': code,
    });
  }

  Future<dynamic> changePassword({
    required String current,
    required String next,
  }) {
    return _client.put(ApiEndpoints.changePassword, data: {
      'currentPassword': current,
      'newPassword': next,
    });
  }

  Future<dynamic> logout() {
    return _client.post(ApiEndpoints.logout);
  }

  Future<dynamic> getReviews({int page = 1, int perPage = 20}) {
    return _client.get(ApiEndpoints.reviews, query: {
      'page': page,
      'perPage': perPage,
    });
  }

  Future<dynamic> getReviewsAverage() {
    return _client.get(ApiEndpoints.reviewsAverage);
  }

  // Profile
  Future<dynamic> me() {
    return _client.get(ApiEndpoints.me);
  }

  Future<dynamic> updateProfile(Map<String, dynamic> payload) {
    return _client.put(ApiEndpoints.updateProfile, data: payload);
  }

  Future<dynamic> uploadProfilePhoto(String base64Image) {
    return _client.post(ApiEndpoints.profilePhoto, data: {
      'avatar': base64Image,
    });
  }

  Future<dynamic> profile() {
    return _client.get(ApiEndpoints.me);
  }

  Future<dynamic> profileCompletion() {
    return _client.get(ApiEndpoints.profileCompletion);
  }

  Future<dynamic> setLocation({required double lat, required double lng}) {
    return _client.put(ApiEndpoints.setLocation, data: {
      'lat': lat,
      'lng': lng,
    });
  }

  Future<dynamic> updateStatus(String status) {
    return _client.put(ApiEndpoints.updateStatus, data: {
      'status': status,
    });
  }

  Future<dynamic> toggleOnline({
    required bool online,
    DateTime? unavailableUntil,
  }) {
    final payload = <String, dynamic>{
      'online': online,
    };
    if (unavailableUntil != null) {
      payload['unavailableUntil'] = unavailableUntil.toIso8601String();
    }
    return _client.put(ApiEndpoints.toggleOnline, data: payload);
  }

  Future<dynamic> setAvailability(List<Map<String, dynamic>> slots,
      {DateTime? unavailableUntil}) {
    return _client.put(ApiEndpoints.availability, data: {
      'slots': slots,
      'unavailableUntil': unavailableUntil?.toIso8601String(),
    });
  }

  Future<dynamic> getAvailability() {
    return _client.get(ApiEndpoints.availability);
  }

  // Services & Pricing
  Future<dynamic> categories() {
    return _client.get(ApiEndpoints.categories);
  }

  Future<dynamic> setServices(List<String> services) {
    return _client.post(ApiEndpoints.services, data: {
      'services': services,
    });
  }

  Future<dynamic> updateService(String serviceId, String name) {
    return _client.put(ApiEndpoints.updateService(serviceId), data: {
      'name': name,
    });
  }

  Future<dynamic> deleteService(String serviceId) {
    return _client.delete(ApiEndpoints.deleteService(serviceId));
  }

  Future<dynamic> setPricing(List<Map<String, dynamic>> pricing) {
    return _client.post(ApiEndpoints.pricing, data: {
      'pricing': pricing,
    });
  }

  // Portfolio
  Future<dynamic> addPortfolio({
    required String imageBase64,
    required String description,
  }) {
    return _client.post(ApiEndpoints.portfolio, data: {
      'image': imageBase64,
      'description': description,
    });
  }

  Future<dynamic> deletePortfolio(String portfolioId) {
    return _client.delete(ApiEndpoints.portfolioItem(portfolioId));
  }

  // Requests
  Future<dynamic> newRequests() {
    return _client.get(ApiEndpoints.newRequests);
  }

  Future<dynamic> activeRequests() {
    return _client.get(ApiEndpoints.activeRequests);
  }

  Future<dynamic> requestsHistory() {
    return _client.get(ApiEndpoints.requestsHistory);
  }

  Future<dynamic> acceptRequest(String requestId,
      {int? price, String? note}) {
    return _client.post(ApiEndpoints.acceptRequest(requestId), data: {
      if (price != null) 'price': price,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<dynamic> rejectRequest(String requestId, {String? reason}) {
    return _client.post(ApiEndpoints.rejectRequest(requestId), data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<dynamic> completeRequest(String requestId) {
    return _client.post(ApiEndpoints.completeRequest(requestId));
  }

  Future<dynamic> requestDetails(String requestId) {
    return _client.get(ApiEndpoints.requestDetails(requestId));
  }

  Future<dynamic> requestTimeline(String requestId) {
    return _client.get(ApiEndpoints.requestTimeline(requestId));
  }

  Future<dynamic> updateTimeline(String requestId,
      {required String status, String? note}) {
    return _client.post(ApiEndpoints.updateTimeline(requestId), data: {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  // Wallet & Earnings
  Future<dynamic> wallet() {
    return _client.get(ApiEndpoints.wallet);
  }

  Future<dynamic> walletHistory() {
    return _client.get(ApiEndpoints.walletHistory);
  }

  Future<dynamic> earnings() {
    return _client.get(ApiEndpoints.earnings);
  }

  Future<dynamic> withdraw(int amount) {
    return _client.post(ApiEndpoints.withdraw, data: {'amount': amount});
  }

  Future<dynamic> setPaymentMethod(Map<String, dynamic> payload) {
    return _client.post(ApiEndpoints.paymentMethod, data: payload);
  }

  // Reviews
  Future<dynamic> reviews() {
    return _client.get(ApiEndpoints.reviews);
  }

  Future<dynamic> reviewsAverage() {
    return _client.get(ApiEndpoints.reviewsAverage);
  }

  Future<dynamic> replyReview(String reviewId, String reply) {
    return _client.post(ApiEndpoints.replyReview(reviewId), data: {
      'reply': reply,
    });
  }

  // Notifications
  Future<dynamic> updateNotificationSettings(
      Map<String, dynamic> payload) async {
    return _client.put(ApiEndpoints.notificationSettings, data: payload);
  }

  Future<dynamic> notifications() {
    return _client.get(ApiEndpoints.notifications);
  }

  Future<dynamic> markNotificationRead(String notificationId) {
    return _client.put(ApiEndpoints.markNotificationRead(notificationId));
  }

  Future<dynamic> notificationsSettings() {
    return _client.get(ApiEndpoints.notificationSettings);
  }

  // Analytics
  Future<dynamic> dashboard() {
    return _client.get(ApiEndpoints.dashboard);
  }

  Future<dynamic> insights() {
    return _client.get(ApiEndpoints.insights);
  }

  // Complaints
  Future<dynamic> createComplaint(Map<String, dynamic> payload) {
    return _client.post(ApiEndpoints.complaints, data: payload);
  }

  Future<dynamic> complaints({
    String? status,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.get(ApiEndpoints.complaints, query: {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'perPage': perPage,
    });
  }

  Future<dynamic> complaint(String complaintId) {
    return _client.get(ApiEndpoints.complaint(complaintId));
  }

  Future<dynamic> complaintMessages(String complaintId,
      {required String message, List<dynamic>? attachments}) {
    return _client.post(ApiEndpoints.complaintMessages(complaintId), data: {
      'message': message,
      'attachments': attachments ?? [],
    });
  }

  // Chat
  Future<dynamic> openChat(String requestId) {
    return _client.post(ApiEndpoints.openChat(requestId));
  }

  Future<dynamic> messages(String requestId) {
    return _client.get(ApiEndpoints.messages(requestId));
  }

  Future<dynamic> sendMessage({
    required String requestId,
    required String type,
    String? text,
    List<dynamic>? attachments,
  }) {
    return _client.post(ApiEndpoints.sendMessage, data: {
      'requestId': requestId,
      'type': type,
      if (text != null) 'text': text,
      if (attachments != null) 'attachments': attachments,
    });
  }

  Future<dynamic> markMessageRead(String messageId) {
    return _client.put(ApiEndpoints.markMessageRead(messageId));
  }

  Future<dynamic> editMessage(String messageId, String text) {
    return _client.patch(ApiEndpoints.editMessage(messageId), data: {
      'text': text,
    });
  }

  Future<dynamic> deleteMessage(String messageId) {
    return _client.delete(ApiEndpoints.deleteMessage(messageId));
  }

  Future<dynamic> clearRequestChat(String requestId) {
    return _client.delete(ApiEndpoints.clearRequestChat(requestId));
  }

  Future<dynamic> chats() {
    return _client.get(ApiEndpoints.chats);
  }

  Future<dynamic> directMessages(String customerId) {
    return _client.get(ApiEndpoints.directMessages(customerId));
  }

  Future<dynamic> directInbox() {
    return _client.get(ApiEndpoints.directInbox);
  }

  Future<dynamic> sendDirectMessage({
    required String customerId,
    required String message,
    List<dynamic>? attachments,
  }) {
    return _client.post(ApiEndpoints.sendDirectMessage, data: {
      'otherId': customerId,
      'message': message,
      if (attachments != null) 'attachments': attachments,
    });
  }

  Future<dynamic> editDirectMessage(String messageId, String text) {
    return _client.patch(ApiEndpoints.editDirectMessage(messageId), data: {
      'text': text,
    });
  }

  Future<dynamic> deleteDirectMessage(String messageId) {
    return _client.delete(ApiEndpoints.deleteDirectMessage(messageId));
  }

  Future<dynamic> clearDirectChat(String customerId) {
    return _client.delete(ApiEndpoints.clearDirectChat(customerId));
  }

  Future<dynamic> blockChat({
    required String customerId,
    String? reason,
  }) {
    return _client.post(ApiEndpoints.blockChat, data: {
      'otherId': customerId,
      if (reason != null) 'reason': reason,
    });
  }

  Future<dynamic> unblockChat(String customerId) {
    return _client.post(ApiEndpoints.unblockChat, data: {
      'otherId': customerId,
    });
  }
}

