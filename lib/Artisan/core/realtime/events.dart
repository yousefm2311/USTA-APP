class RealtimeEvents {
  // Requests
  static const String requestNew = 'request:new';
  static const String requestAccepted = 'request:accepted';
  static const String requestRejected = 'request:rejected';
  static const String requestCancelled = 'request:cancelled';
  static const String requestCanceled = 'request:canceled'; // backend alias
  static const String requestUpdated = 'request:updated';
  static const String requestInProgress = 'request:in_progress';
  static const String requestCompleted = 'request:completed';

  // Location
  static const String locationUpdate = 'location:update';
  static const String locationStreamStart = 'location:stream:start';
  static const String locationStreamStop = 'location:stream:stop';

  // Chat
  static const String chatMessage = 'chat:message';
  static const String chatDelivered = 'chat:delivered';
  static const String chatSeen = 'chat:seen';
  static const String chatRead = 'chat:read';
  static const String chatSubscribe = 'chat:subscribe';
  static const String chatEdited = 'chat:edited';
  static const String chatDeleted = 'chat:deleted';
  static const String chatCleared = 'chat:cleared';
  static const String directSubscribe = 'direct:subscribe';
  static const String directMessage = 'direct:message';
  static const String directRead = 'direct:read';
  static const String directEdited = 'direct:edited';
  static const String directDeleted = 'direct:deleted';
  static const String directCleared = 'direct:cleared';
  static const String directBlock = 'direct:block';
  static const String directUnblock = 'direct:unblock';
  // Backend emits these aliases; listen to both.
  static const String directBlocked = 'direct:blocked';
  static const String directUnblocked = 'direct:unblocked';

  // Notifications
  static const String notificationNew = 'notification:new';
  static const String notificationUpdate = 'notification:update';


    // ===== Artisan Inbox (NEW) =====
  static const String artisanSubscribe = 'artisan:subscribe';
  static const String artisanInbox = 'artisan:inbox';

}
