class ApiEndpoints {
  // Live backend base url
  static const String baseUrl =
      "https://usta.qzz.io/api";

  static const String signup = "$baseUrl/artisan/signup";
  static const String login = "$baseUrl/artisan/login";
  static const String verify = "$baseUrl/artisan/verify";
  static const String forgotPassword = "$baseUrl/artisan/forgot-password";
  static const String forgotPasswordVerifyCode =
      "$baseUrl/artisan/forgot-password/verify-code";
  static const String resendVerification = "$baseUrl/artisan/resend-verification";
  static const String changePassword = "$baseUrl/artisan/change-password";
  static const String logout = "$baseUrl/artisan/logout";
  static const String refresh = "$baseUrl/artisan/refresh-token";
  static const String verificationStatus = "$baseUrl/artisan/verification/status";
  static const String verificationUploadId =
      "$baseUrl/artisan/verification/upload-id";
  static const String verificationUploadSelfie =
      "$baseUrl/artisan/verification/upload-selfie";

  // Profile
  static const String me = "$baseUrl/artisan/me";
  static const String updateProfile = "$baseUrl/artisan/profile";
  static const String profilePhoto = "$baseUrl/artisan/profile/photo";
  static const String setLocation = "$baseUrl/artisan/location";
  static const String updateStatus = "$baseUrl/artisan/status";
  static const String toggleOnline = "$baseUrl/artisan/online";
  static const String availability = "$baseUrl/artisan/availability";
  static const String profileCompletion = "$baseUrl/users/profile-completion";

  // Services & Pricing
  static const String categories = "$baseUrl/categories";
  static const String services = "$baseUrl/artisan/services";
  static const String pricing = "$baseUrl/artisan/pricing";
  static String updateService(String id) => "$services/$id";
  static String deleteService(String id) => "$services/$id";

  // Portfolio
  static const String portfolio = "$baseUrl/artisan/portfolio";
  static String portfolioItem(String id) => "$portfolio/$id";

  // Requests
  static const String newRequests = "$baseUrl/artisan/requests/new";
  static const String activeRequests = "$baseUrl/artisan/requests/active";
  static const String requestsHistory = "$baseUrl/artisan/requests/history";
  static String acceptRequest(String id) => "$baseUrl/artisan/requests/$id/accept";
  static String rejectRequest(String id) => "$baseUrl/artisan/requests/$id/reject";
  static String completeRequest(String id) => "$baseUrl/artisan/requests/$id/complete";
  static String requestDetails(String id) => "$baseUrl/artisan/requests/$id";
  static String updateTimeline(String id) => "$baseUrl/artisan/requests/$id/timeline";
  static String requestTimeline(String id) => "$baseUrl/artisan/requests/$id/timeline";

  // Wallet & Earnings
  static const String wallet = "$baseUrl/artisan/wallet";
  static const String walletHistory = "$baseUrl/artisan/wallet/history";
  static const String earnings = "$baseUrl/artisan/earnings";
  static const String withdraw = "$baseUrl/artisan/withdraw";
  static const String paymentMethod = "$baseUrl/artisan/payment-method";

  // Reviews
  static const String reviews = "$baseUrl/artisan/reviews";
  static const String reviewsAverage = "$baseUrl/artisan/reviews/average";
  static String replyReview(String id) => "$baseUrl/artisan/reviews/$id/reply";

  // Notifications
  static const String notificationSettings = "$baseUrl/artisan/notifications";
  static const String notifications = "$baseUrl/artisan/notifications";
  static String markNotificationRead(String id) =>
      "$baseUrl/artisan/notifications/$id/read";
  static const String fcmToken =
      "$baseUrl/artisan/notifications/fcm-token";
  static const String subscribeTopic =
      "$baseUrl/artisan/notifications/subscribe-topic";
  static const String unsubscribeTopic =
      "$baseUrl/artisan/notifications/unsubscribe-topic";

  // Analytics
  static const String dashboard = "$baseUrl/artisan/dashboard";
  static const String insights = "$baseUrl/artisan/insights";

  // Complaints
  static const String complaints = "$baseUrl/artisan/complaints";
  static String complaint(String id) => "$baseUrl/artisan/complaints/$id";
  static String complaintMessages(String id) =>
      "$baseUrl/artisan/complaints/$id/messages";

  // Chat
  static const String chats = "$baseUrl/chat";
  static String openChat(String requestId) => "$baseUrl/chat/$requestId";
  static String messages(String requestId) => "$baseUrl/chat/$requestId";
  static const String sendMessage = "$baseUrl/chat/message";
  static String markMessageRead(String messageId) =>
      "$baseUrl/chat/read/$messageId";
  static String editMessage(String messageId) =>
      "$baseUrl/chat/message/$messageId";
  static String deleteMessage(String messageId) =>
      "$baseUrl/chat/message/$messageId";
  static String clearRequestChat(String requestId) =>
      "$baseUrl/chat/$requestId/messages";
  static String directMessages(String customerId) =>
      "$baseUrl/chat/direct/$customerId";
  static const String directInbox = "$baseUrl/chat/direct/inbox";
  static const String sendDirectMessage = "$baseUrl/chat/direct/message";
  static String editDirectMessage(String messageId) =>
      "$baseUrl/chat/direct/message/$messageId";
  static String deleteDirectMessage(String messageId) =>
      "$baseUrl/chat/direct/message/$messageId";
  static String clearDirectChat(String customerId) =>
      "$baseUrl/chat/direct/$customerId/messages";
  static const String blockChat = "$baseUrl/chat/block";
  static const String unblockChat = "$baseUrl/chat/unblock";

  // Uploads
  static const String uploadChat = "$baseUrl/upload/chat";
}
