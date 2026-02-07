import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/settings/theme_controller.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/chat/controller/chat_controller.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_room_view.dart';
import 'package:usta/Customer/features/customer/customer_navigation_controller.dart';

class CustomerChatListView extends StatefulWidget {
  const CustomerChatListView({super.key});

  @override
  State<CustomerChatListView> createState() => _CustomerChatListViewState();
}

class _CustomerChatListViewState extends State<CustomerChatListView> {
  final ChatController controller = Get.find<ChatController>(tag: 'customer');
  final ThemeController themeController = Get.find<ThemeController>(tag: 'customer');
  late final CustomerNavigationController _navController;
  Worker? _navWorker;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _navController = Get.find<CustomerNavigationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleTabChange(_navController.selectedIndex.value);
    });
    _navWorker = ever<int>(_navController.selectedIndex, _handleTabChange);
  }

  @override
  void dispose() {
    _navWorker?.dispose();
    controller.stopChatsPolling();
    super.dispose();
  }

  void _handleTabChange(int index) {
    final shouldBeActive = index == 2;
    if (shouldBeActive && !_active) {
      _active = true;
      controller.fetchChats();
      controller.startChatsPolling();
      return;
    }
    if (!shouldBeActive && _active) {
      _active = false;
      controller.stopChatsPolling();
    }
  }

  int _getUnreadCount(Map<String, dynamic> chat) {
    final count = chat['unreadCount'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    return 0;
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'الآن'.tr;
      if (diff.inHours < 1) return '${diff.inMinutes}${'د'.tr}';
      if (diff.inHours < 24) return '${diff.inHours}${'س'.tr}';
      if (diff.inDays < 7) return '${diff.inDays}${'ي'.tr}';

      return '${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return '';
    }
  }

  void _onChatLongPress(Map<String, dynamic> chat) {
    final type = chat['type']?.toString().toLowerCase();
    final artisanId =
        chat['artisanId']?.toString() ?? chat['otherId']?.toString() ?? '';
    if (type != 'direct' || artisanId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('حذف المحادثة'.tr),
              subtitle:
                  Text('سيتم حذف جميع الرسائل المباشرة مع هذا الحرفي'.tr),
              onTap: () async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('تأكيد الحذف'.tr),
                    content: Text('سيتم حذف المحادثة بالكامل. هل أنت متأكد؟'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('إلغاء'.tr),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('حذف'.tr),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await controller.deleteDirectConversation(artisanId);
                  await controller.fetchChats();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          "المحادثات".tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        final isDark = themeController.isDark.value;
        final scheme = Theme.of(context).colorScheme;
        final surface = scheme.surface;
        final onSurface = scheme.onSurface;
        final borderColor = onSurface.withOpacity(isDark ? 0.12 : 0.08);
        final avatarBg = onSurface.withOpacity(isDark ? 0.12 : 0.08);
        final avatarIcon = onSurface.withOpacity(isDark ? 0.7 : 0.6);
        final secondaryText = onSurface.withOpacity(isDark ? 0.7 : 0.6);

        if (controller.loadingChats.value && controller.chats.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, __) => ShimmerSkeletons.listTile(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: 8,
          );
        }
        final chats = controller.chats;
        if (chats.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchChats,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 80),
                Center(child: Text("لا توجد محادثات بعد".tr)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchChats,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final type = chat['type']?.toString();
              final name =
                  chat['peerName']?.toString() ??
                  chat['artisanName']?.toString() ??
                  chat['customerName']?.toString() ??
                  chat['name']?.toString() ??
                  'Chat';
              final artisanId =
                  chat['artisanId']?.toString() ??
                  chat['otherId']?.toString() ??
                  '';
              final isAdminNotice = chat['adminNotice'] == true;
              final displayName =
                  isAdminNotice && artisanId.isEmpty ? 'الإدارة' : name;
              final lastMessage =
                  chat['lastMessage']?.toString() ??
                  chat['lastMessageText']?.toString() ??
                  '';
              final time =
                  chat['updatedAt']?.toString() ??
                  chat['lastMessageAt']?.toString() ??
                  '';
              final requestId =
                  chat['requestId']?.toString() ??
                  chat['request']?.toString() ??
                  chat['_id']?.toString() ??
                  chat['id']?.toString() ??
                  '';
              final unread = _getUnreadCount(chat);

              return InkWell(
                onTap: () {
                  if (type == 'direct') {
                    if (artisanId.isEmpty) return;
                    Get.to(
                      () => CustomerChatRoomView(
                        requestId: '',
                        customerId: artisanId,
                        customerName: name,
                        isDirect: true,
                      ),
                    );
                  } else {
                    if (requestId.isEmpty) return;
                    Get.to(
                      () => CustomerChatRoomView(
                        requestId: requestId,
                        customerName: name,
                      ),
                      );
                  }
                },
                onLongPress: () => _onChatLongPress(chat),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: avatarBg,
                        child: Icon(Icons.person, color: avatarIcon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.body.copyWith(
                                fontFamily: "Cairo",
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            if (isAdminNotice)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'رسالة من الإدارة'.tr,
                                  style: AppTextStyles.small.copyWith(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (type == 'direct')
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'محادثة مباشرة'.tr,
                                  style: AppTextStyles.small.copyWith(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              style: AppTextStyles.small.copyWith(
                                color: secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(time),
                            style: AppTextStyles.body.copyWith(
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}


