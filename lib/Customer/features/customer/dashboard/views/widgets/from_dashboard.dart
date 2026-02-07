import 'package:usta/Customer/features/customer/dashboard/controllers/customer_dashboard_controller.dart';

String fromDashboard(
  CustomerDashboardController controller,
  List<String> keys,
) {
  dynamic root = controller.dashboard;
  dynamic nested = controller.dashboard['data'];

  for (final key in keys) {
    final val = (root is Map) ? root[key] : null;
    if (val != null) return val.toString();
  }

  if (nested is Map) {
    for (final key in keys) {
      final val = nested[key];
      if (val != null) return val.toString();
    }
  }

  return '';
}

