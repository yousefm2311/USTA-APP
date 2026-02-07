

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:usta/Artisan/features/artisan/chat/views/artisan_chat_list_view.dart';
import 'package:usta/Artisan/features/artisan/home/views/home_view/home_view.dart';
import 'package:usta/Artisan/features/artisan/profile/views/profile_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/settings_view.dart';

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const ArtisanHomeView(),
    const ArtisanChatListView(),
     ArtisanSettingsView(),
    const ArtisanProfileView()
  ];
}

