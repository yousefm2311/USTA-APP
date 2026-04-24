import 'package:flutter_test/flutter_test.dart';
import 'package:usta/Customer/core/services/notification_navigation.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';

void main() {
  test('chat notifications resolve direct conversations safely', () {
    final destination = resolveCustomerNotificationDestination({
      'route': '/chat',
      'artisanId': 'artisan-1',
      'title': 'نجار',
      'direct': 'true',
    });

    expect(destination.kind, CustomerNotificationDestinationKind.chat);
    expect(destination.artisanId, 'artisan-1');
    expect(destination.isDirect, isTrue);
  });

  test('request notifications resolve the request details target', () {
    final destination = resolveCustomerNotificationDestination({
      'type': 'request',
      'requestId': 'request-42',
    });

    expect(destination.kind, CustomerNotificationDestinationKind.request);
    expect(destination.requestId, 'request-42');
  });

  test('payment notifications resolve the receipt when an id is available', () {
    final destination = resolveCustomerNotificationDestination({
      'route': '/payments',
      'paymentId': 'payment-7',
    });

    expect(destination.kind, CustomerNotificationDestinationKind.payment);
    expect(destination.paymentId, 'payment-7');
  });

  test('supported customer named routes stay routable', () {
    final destination = resolveCustomerNotificationDestination({
      'route': AppRoutes.customerBottomNaviBar,
      'id': 'nav',
    });

    expect(destination.kind, CustomerNotificationDestinationKind.namedRoute);
    expect(destination.route, AppRoutes.customerBottomNaviBar);
  });

  test('unknown notification payloads stay unknown instead of misrouting', () {
    final destination = resolveCustomerNotificationDestination({
      'route': '/product_details',
      'id': '123',
    });

    expect(destination.kind, CustomerNotificationDestinationKind.unknown);
  });
}
