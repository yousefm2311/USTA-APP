import 'package:usta/Customer/core/utils/routes/routes.dart';

enum CustomerNotificationDestinationKind {
  chat,
  request,
  payment,
  wallet,
  namedRoute,
  unknown,
}

class CustomerNotificationDestination {
  const CustomerNotificationDestination({
    required this.kind,
    this.route = '',
    this.id = '',
    this.requestId = '',
    this.paymentId = '',
    this.artisanId = '',
    this.title = '',
    this.isDirect = false,
  });

  final CustomerNotificationDestinationKind kind;
  final String route;
  final String id;
  final String requestId;
  final String paymentId;
  final String artisanId;
  final String title;
  final bool isDirect;
}

CustomerNotificationDestination resolveCustomerNotificationDestination(
  Map<String, String> data,
) {
  final rawRoute = _pick(data, ['route', 'screen', 'path', 'deepLink']) ?? '';
  final route = _normalize(rawRoute);
  final type = _normalize(_pick(data, ['type']));
  final id =
      _pick(data, [
        'id',
        'requestId',
        'request',
        'orderId',
        'paymentId',
        'chatId',
      ]) ??
      '';
  final requestId =
      _pick(data, ['requestId', 'request_id', 'request', 'orderId']) ?? '';
  final paymentId =
      _pick(data, ['paymentId', 'payment_id', 'receiptId', 'transactionId']) ??
      '';
  final artisanId =
      _pick(data, ['artisanId', 'otherId', 'customerId', 'conversationId']) ??
      '';
  final title =
      _pick(data, ['title', 'name', 'artisanName', 'customerName']) ?? '';
  final isDirect =
      _isTruthy(data['direct']) ||
      type == 'direct' ||
      route.endsWith('/direct-chat');

  if (_matchesType(type, const ['chat', 'message', 'messages', 'direct']) ||
      _matchesRoute(route, const ['/chat', 'chat', '/messages', 'messages'])) {
    return CustomerNotificationDestination(
      kind: CustomerNotificationDestinationKind.chat,
      route: rawRoute,
      id: id,
      requestId: requestId,
      artisanId: artisanId,
      title: title,
      isDirect: isDirect,
    );
  }

  if (_matchesType(type, const ['request', 'requests', 'order', 'orders']) ||
      _matchesRoute(route, const [
        '/request',
        '/requests',
        '/order',
        '/orders',
        'requests',
      ])) {
    return CustomerNotificationDestination(
      kind: CustomerNotificationDestinationKind.request,
      route: rawRoute,
      id: id,
      requestId: requestId,
      title: title,
    );
  }

  if (_matchesType(type, const ['payment', 'payments']) ||
      _matchesRoute(route, const [
        '/payment',
        '/payments',
        '/wallet/history',
        'payments',
      ])) {
    return CustomerNotificationDestination(
      kind: CustomerNotificationDestinationKind.payment,
      route: rawRoute,
      id: id,
      paymentId: paymentId,
      title: title,
    );
  }

  if (_matchesType(type, const ['wallet']) ||
      _matchesRoute(route, const ['/wallet', 'wallet'])) {
    return CustomerNotificationDestination(
      kind: CustomerNotificationDestinationKind.wallet,
      route: rawRoute,
      id: id,
      title: title,
    );
  }

  if (_isSupportedNamedRoute(route)) {
    return CustomerNotificationDestination(
      kind: CustomerNotificationDestinationKind.namedRoute,
      route: rawRoute,
      id: id,
      title: title,
    );
  }

  return CustomerNotificationDestination(
    kind: CustomerNotificationDestinationKind.unknown,
    route: rawRoute,
    id: id,
    requestId: requestId,
    paymentId: paymentId,
    artisanId: artisanId,
    title: title,
    isDirect: isDirect,
  );
}

String? _pick(Map<String, String> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _normalize(String? value) => value?.trim().toLowerCase() ?? '';

bool _matchesType(String type, List<String> candidates) {
  if (type.isEmpty) return false;
  return candidates.contains(type);
}

bool _matchesRoute(String route, List<String> candidates) {
  if (route.isEmpty) return false;
  for (final candidate in candidates) {
    final normalized = candidate.toLowerCase();
    if (route == normalized || route.endsWith(normalized)) {
      return true;
    }
  }
  return false;
}

bool _isSupportedNamedRoute(String route) {
  final normalizedRoute = _normalize(route);
  return normalizedRoute == _normalize(AppRoutes.customerBottomNaviBar) ||
      normalizedRoute == _normalize(AppRoutes.customerHomeView);
}

bool _isTruthy(String? value) {
  final normalized = _normalize(value);
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'direct';
}
