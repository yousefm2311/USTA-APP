class RealtimeEvents {
  static const String requestNew = 'request:new';
  static const String requestAccepted = 'request:accepted';
  static const String requestRejected = 'request:rejected';
  static const String requestCancelled = 'request:cancelled';
  static const String requestUpdated = 'request:update';
  static const String requestTimeline = 'request:timeline';

  // Chat
  static const String chatSubscribe = 'chat:subscribe';
  static const String chatMessage = 'chat:message';
  static const String chatRead = 'chat:read';
  static const String directSubscribe = 'direct:subscribe';
  static const String directMessage = 'direct:message';
  static const String directRead = 'direct:read';
  static const String directBlock = 'direct:block';
  static const String directUnblock = 'direct:unblock';
  static const String directBlocked = 'direct:blocked';
  static const String directUnblocked = 'direct:unblocked';
}
