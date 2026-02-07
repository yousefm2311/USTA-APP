import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_list_view.dart';
import 'package:usta/Customer/features/customer/favorites/views/customer_history_view.dart';
import 'package:usta/Customer/features/customer/home/views/customer_home_view.dart';
import 'package:usta/Customer/features/customer/profile/views/customer_profile_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_active_requests_view.dart';


class CustomerNavigationController extends GetxController {
  final selectedIndex = 0.obs;

  final screens = [
    const CustomerHomeView(),
    CustomerHistoryView(),
    CustomerChatListView(),
    CustomerActiveRequestsView(),
    const CustomerProfileView(),
  ];

  void changeTab(int index) {
    if (index == selectedIndex.value) return;
    selectedIndex.value = index;
  }
}

