import 'package:usta/Customer/core/config/app_config.dart';

class ApiEndpoints {
  static String get origin => AppConfig.instance.origin;
  static String get baseUrl => AppConfig.instance.baseUrl;
  static String get socketUrl => AppConfig.instance.socketUrl;

  static String get signup => '$baseUrl/customer/signup';
  static String get login => '$baseUrl/customer/login';
  static String get logout => '$baseUrl/customer/logout';
  static String get refresh => '$baseUrl/customer/refresh-token';
  static String get verify => '$baseUrl/customer/verify';
  static String get verifyResetCode => '$baseUrl/customer/verify-reset-code';
  static String get forgotPassword => '$baseUrl/customer/forgot-password';
  static String get resendVerification => '$baseUrl/customer/resend-verification';

  static String get me => '$baseUrl/customer/me';
  static String get profile => '$baseUrl/customer/profile';
  static String get uploadPhoto => '$baseUrl/customer/profile/photo';
  static String get deleteAccount => '$baseUrl/customer/account';
  static String get updateMe => '$baseUrl/customer/me';
  static String get changePassword => '$baseUrl/customer/change-password';

  static String get notificationsSettings => '$baseUrl/customer/notifications';
  static String get language => '$baseUrl/customer/language';
  static String get theme => '$baseUrl/customer/theme';
  static String get online => '$baseUrl/customer/online';
  static String get availability => '$baseUrl/customer/availability';
  static String get settings => '$baseUrl/customer/settings';

  static String get categories => '$baseUrl/categories';
  static String get searchArtisans => '$baseUrl/artisans/search';
  static String get artisanNearby => '$baseUrl/artisans/nearby';
  static String get artisanTopRated => '$baseUrl/artisans/top-rated';
  static String get artisanArea => '$baseUrl/artisans/area';
  static String artisanDetails(String id) => '$baseUrl/artisans/$id';

  static String get createRequest => '$baseUrl/customer/requests';
  static String requestImages(String id) => '$baseUrl/customer/requests/$id/images';
  static String get activeRequests => '$baseUrl/customer/requests/active';
  static String get requestsHistory => '$baseUrl/customer/requests/history';
  static String requestDetails(String id) => '$baseUrl/customer/requests/$id';
  static String requestTimeline(String id) => '$baseUrl/customer/requests/$id/timeline';
  static String cancelRequest(String id) => '$baseUrl/customer/requests/$id/cancel';
  static String confirmCompletion(String id) =>
      '$baseUrl/customer/requests/$id/confirm-completion';
  static String requestPriceDecision(String id) =>
      '$baseUrl/requests/$id/price/decision';
  static String requestDetailsPublic(String id) => '$baseUrl/requests/$id';

  static String createReview(String artisanId) =>
      '$baseUrl/customer/reviews/$artisanId';
  static String review(String id) => '$baseUrl/customer/reviews/$id';
  static String get myReviews => '$baseUrl/customer/reviews';

  static String addFavorite(String artisanId) =>
      '$baseUrl/customer/favorites/$artisanId';
  static String get favorites => '$baseUrl/customer/favorites';
  static String removeFavorite(String artisanId) =>
      '$baseUrl/customer/favorites/$artisanId';
  static String get viewHistory => '$baseUrl/customer/history';

  static String get payment => '$baseUrl/payment';
  static String get paymentIntent => '$baseUrl/payments/intent';
  static String paymentReceipt(String id) => '$baseUrl/payment/$id/receipt';
  static String get wallet => '$baseUrl/customer/wallet';
  static String get walletRecharge => '$baseUrl/customer/wallet/recharge';
  static String get walletHistory => '$baseUrl/customer/wallet/history';

  static String get notifications => '$baseUrl/customer/notifications';
  static String markNotificationRead(String id) =>
      '$baseUrl/customer/notifications/$id/read';
  static String deleteNotification(String id) =>
      '$baseUrl/customer/notifications/$id';
  static String get fcmToken => '$baseUrl/customer/notifications/fcm-token';
  static String get listFcmTokens =>
      '$baseUrl/customer/notifications/fcm-token';
  static String get subscribeTopic =>
      '$baseUrl/customer/notifications/subscribe-topic';
  static String get unsubscribeTopic =>
      '$baseUrl/customer/notifications/unsubscribe-topic';
  static String listTokensById(String id) =>
      '$baseUrl/notifications/customer/$id/tokens';

  static String get complaints => '$baseUrl/customer/complaints';
  static String complaint(String id) => '$baseUrl/customer/complaints/$id';
  static String complaintMessages(String id) =>
      '$baseUrl/customer/complaints/$id/messages';

  static String get dashboard => '$baseUrl/customer/dashboard';
  static String get stats => '$baseUrl/customer/stats';

  static String get activeBanners => '$baseUrl/banners/active';
  static String get coupons => '$baseUrl/customer/coupons';
  static String get applyCoupon => '$baseUrl/customer/coupons/apply';
  static String get referral => '$baseUrl/customer/referral';
  static String get rewards => '$baseUrl/customer/rewards';
  static String get recommendations => '$baseUrl/customer/recommendations';
  static String get liveMap => '$baseUrl/customer/live-map';
  static String get aiFeedback => '$baseUrl/customer/ai-feedback';

  static String get chats => '$baseUrl/chat';
  static String chat(String requestId) => '$baseUrl/chat/$requestId';
  static String get chatMessage => '$baseUrl/chat/message';
  static String chatRead(String messageId) => '$baseUrl/chat/read/$messageId';
  static String get chatDirectInbox => '$baseUrl/chat/direct/inbox';
  static String chatDirect(String otherId) => '$baseUrl/chat/direct/$otherId';
  static String get chatDirectMessage => '$baseUrl/chat/direct/message';
  static String chatDirectMessageUpdate(String id) =>
      '$baseUrl/chat/direct/message/$id';
  static String chatDirectMessageDelete(String id) =>
      '$baseUrl/chat/direct/message/$id';
  static String chatDirectDeleteConversation(String otherId) =>
      '$baseUrl/chat/direct/$otherId/messages';
  static String chatDirectRead(String messageId) =>
      '$baseUrl/chat/direct/read/$messageId';
  static String get uploadChat => '$baseUrl/upload/chat';
}

