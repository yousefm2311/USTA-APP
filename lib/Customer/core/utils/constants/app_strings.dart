// ignore_for_file: constant_identifier_names
import 'package:get_storage/get_storage.dart';

final box = GetStorage();

class AppStrings {
  // App
  static const String appName = "app_name";
  static const String appSplash = "app_splash";

  // Common
  static const String ok = "ok";
  static const String cancel = "cancel";
  static const String confirm = "confirm";
  static const String loading = "loading";
  static const String error = "error";
  static const String retry = "retry";
  static const String noData = "no_data";
  static const String next = "next";
  static const String getStarted = "get_started";
  static const String skip = "skip";
  static const String back = "back";
  static const String continue_ = "continue";

  // Storage keys
  static const kOnboardingDoneKey = "onboarding_done";

  // Auth / Status messages
  static const String login = "login";
  static const String loginSuccess = "login_success";
  static const String createAccountSuccess = "create_account_success";
  static const String verifySuccess = "verify_success";
  static const String verifyCodeSent = "verify_code_sent";
  static const String passwordUpdated = "password_updated";
  static const String couldNotCompleteRequest = "could_not_complete_request";

  // Forgot password / Verify
  static const String forgotPaswword = "forgot_password";
  static const String forgotPaswwordText = "forgot_password_title";
  static const String checkemail = "check_email";
  static const String setnewPassword = "set_new_password";
  static const String setnewPasswordbody = "set_new_password_body";
  static const String checkemailbody = "check_email_body";
  static const String activateAccount = "activate_account";
  static const String activateAccountBody = "activate_account_body";
  static const String activateAccountButton = "activate_account_button";
  static const String resendCode = "resend_code";
  static const String forgotPaswwordbody = "forgot_password_body";
  static const String forgotPasswordButton = "forgot_password_button";
  static const String forgotPasswordSent = "forgot_password_sent";
  static const String forgotPasswordFailed = "forgot_password_failed";
  static const String sendingCode = "sending_code";
  static const String bodyLogin = "body_login";
  static const String register = "register";
  static const String email = "email";
  static const String success = "success";
  static const String successbody = "success_body";
  static const String invalidCode = "invalid_code";
  static const String accountNotApproved = "account_not_approved";
  static const String passwordResetSuccess = "password_reset_success";
  static const String passwordsMismatch = "passwords_mismatch";
  static const String updatingPassword = "updating_password";
  static const String verifyingCode = "verifying_code";

  // Reviews
  static const String artisanReviewsTitle = "artisan_reviews_title";
  static const String ratingSummary = "rating_summary";
  static const String ratingAverage = "rating_average";
  static const String ratingCount = "rating_count";
  static const String reviewerNamePlaceholder = "reviewer_name_placeholder";
  static const String reviewBodyPlaceholder = "review_body_placeholder";
  static const String reviewDatePlaceholder = "review_date_placeholder";
  static const String reviewCountSuffix = "review_count_suffix";
  static const String replyReview = "reply_review";
  static const String replyHint = "reply_hint";
  static const String reviewsLoadFailed = "reviews_load_failed";
  static const String reviewReplyFailed = "review_reply_failed";
  static const String send = "send";

  // Password
  static const String password = "password";
  static const String passwordConfirm = "password_confirm";
  static const String updatePassword = "update_password";

  // Profile
  static const String name = "name";
  static const String profession = "profession";
  static const String phone = "phone";

  // Tabs
  static const String trips = "trips";
  static const String chat = "chat";
  static const String notifications = "notifications";
  static const String reviews = "reviews";
  static const String profile = "profile";
  static const String settings = "settings";
  static const String home = "home";

  // Settings / General
  static const String wallet = "wallet";
  static const String reminder = "reminder";
  static const String oilAndMa = "maintenance";
  static const String aboutApp = "about_app";
  static const String logout = "logout";
  static const String termsandconditions = "If you are creating a new account.";
  static const String terms = "Terms & Conditions";
  static const String conditions = "Privacy Policy";
  static const String and = "and";
  static const String resend = "resend";
  static const String goodmorning = "good_morning";
  static const String status = "status";
  static const String stop = "stop";
  static const String starttrip = "start_request";
  static const String start = "start";
  static const String show = "show";
  static const String open = "open";
  static const String online = "online";
  static const String summaryday = "today_summary";
  static const String nearbyrequest = "nearby_requests";
  static const String selectpath = "select_path";
  static const String locationLive5Seconds = "location_live_5_seconds";
  static const String privacy = "privacy";
  static const String policiesanddata = "policies_and_data";
  static const String language = "language";
  static const String ar_lang = "arabic";
  static const String en_lang = "english";
  static const String change = "change";
  static const String enable = "enable";
  static const String theme = "theme";
  static const String ligth = "light"; // keep the name to not break imports

  // Trip / Vehicle
  static const String pathfrom = "path_from";
  static const String pathin = "path_to";
  static const String capacityvehicle = "vehicle_capacity";
  static const String edit = "edit";
  static const String save = "save";
  static const String vehicel = "vehicle";
  static const String vehicelname = "vehicle_type";
  static const String favoritepath = "favorite_paths";
  static const String tripsummary = "request_summary";
  static const String triprequest = "new_request";
  static const String accept = "accept";
  static const String livetrip = "live_request";
  static const String inriderpassenger = "passenger";
  static const String support = "support";
  static const String update = "update";
  static const String updatevailable = "update_available";
  static const String updateDetails = "update_details";
  static const String updatesize = "update_size";
  static const String updatenow = "update_now";

  // Upload documents
  static const String uploaddocuments = "upload_documents";
  static const String idfront = "id_front";
  static const String idback = "id_back";
  static const String license = "license";
  static const String carphoto = "car_photo";
  static const String profilephoto = "profile_photo";

  // Artisan UI extras
  static const String artisanHomeTitle = "artisan_home_title";
  static const String quickStats = "quick_stats";
  static const String statNew = "stat_new";
  static const String statActive = "stat_active";
  static const String statCompleted = "stat_completed";
  static const String walletTitle = "wallet_title";
  static const String walletSubtitle = "wallet_subtitle";
  static const String walletDetails = "wallet_details";
  static const String quickActions = "quick_actions";
  static const String goToNewRequests = "go_to_new_requests";
  static const String updateProfile = "update_profile";
  static const String city = "city";
  static const String address = "address";
  static const String security = "security";
  static const String changePassword = "change_password";
  static const String offline = "offline";
  static const String homeHeadline = "home_headline";
  static const String quickActionsServices = "quick_actions_services";
  static const String quickActionsHistory = "quick_actions_history";
  static const String quickActionsWallet = "quick_actions_wallet";
  static const String quickActionsPortfolio = "quick_actions_portfolio";
  static const String quickActionsNotifications = "quick_actions_notifications";
  static const String quickActionsProfile = "quick_actions_profile";
  static const String newRequestsCta = "new_requests_cta";
  static const String profileTitle = "profile_title";
  static const String saveProfile = "save_profile";
  static const String passwordAdvice = "password_advice";
  static const String withdraw = "withdraw";
  static const String description = "description";
  static const String requestsCompleted = "requests_completed";
  static const String rating = "rating";
  static const String portfolio = "portfolio";
  static const String about = "about";
  static const String servicesLabel = "services_label";
  static const String pricing = "pricing";
  static const String availability = "availability";
  static const String help = "help";
  static const String lightMode = "light_mode";
  static const String darkMode = "dark_mode";
  static const String logoutConfirm = "logout_confirm";
  static const String unavailableUntil = "unavailable_until";
  static const String add = "add";
  static const String setLocation = "set_location";

  // Notifications
  static const String notificationsLoadFailed = "notifications_load_failed";
  static const String notificationMarkReadFailed =
      "notification_mark_read_failed";
  static const String notificationSettingsUpdated =
      "notification_settings_updated";
  static const String notificationSettingsFailed =
      "notification_settings_failed";
  static const String notificationSettingsLoadFailed =
      "notification_settings_load_failed";
  static const String notifMarketing = "notif_marketing";
  static const String notifRequests = "notif_requests";
  static const String notifChat = "notif_chat";

  // Portfolio
  static const String portfolioLoadFailed = "portfolio_load_failed";
  static const String portfolioUploadSuccess = "portfolio_upload_success";
  static const String portfolioUploadFailed = "portfolio_upload_failed";
  static const String portfolioUploadPartial = "portfolio_upload_partial";
  static const String portfolioDeleteSuccess = "portfolio_delete_success";
  static const String portfolioDeleteFailed = "portfolio_delete_failed";
  static const String portfolioLimitReached = "portfolio_limit_reached";

  // Extra
  static const String services = "services";
}
