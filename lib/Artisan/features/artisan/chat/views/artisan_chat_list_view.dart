import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/chat/controllers/chat_controller.dart';
import 'package:usta/Artisan/features/artisan/chat/views/artisan_chat_view.dart';

class ArtisanChatListView extends StatefulWidget {
  const ArtisanChatListView({super.key});

  @override
  State<ArtisanChatListView> createState() => _ArtisanChatListViewState();
}

class _ArtisanChatListViewState extends State<ArtisanChatListView> {
  final ChatController controller = Get.find<ChatController>(tag: 'artisan');

  @override
  void initState() {
    super.initState();
    controller.setChatScreenOpen(false);
    controller.clearActive();
    controller.fetchChats();
  }

  Future<void> _confirmDeleteChat({
    required BuildContext context,
    required String? requestId,
    required String? customerId,
    required bool isDirect,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'حذف المحادثة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف هذه المحادثة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (result != true) return;
    if (isDirect) {
      if (customerId == null || customerId.isEmpty) return;
      await controller.clearDirectChat(customerId);
    } else {
      if (requestId == null || requestId.isEmpty) return;
      await controller.clearRequestChat(requestId);
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
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inHours < 1) return '${diff.inMinutes}د';
      if (diff.inHours < 24) return '${diff.inHours}س';
      if (diff.inDays < 7) return '${diff.inDays}ي';
      return '${dateTime.day}/${dateTime.month}';
    } catch (_) {
      return '';
    }
  }

  void longPress(
    type, {
    required BuildContext context,
    required String? requestId,
    required String? customerId,
    required bool isDirect,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('حذف المحادثة'),
              subtitle: const Text(
                'سيتم حذف جميع الرسائل المباشرة مع هذا الحرفي',
              ),
              onTap: () async {
                Navigator.pop(context); // يقفل الـ bottom sheet
                await _confirmDeleteChat(
                  context: context,
                  requestId: requestId,
                  customerId: customerId,
                  isDirect: type == 'direct',
                );
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
        title: const Text(
          "المحادثات",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final isDark = Get.isDarkMode;
        final cs = Theme.of(context).colorScheme;
        if (controller.loadingChats.value && controller.chats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final chats = controller.chats;
        if (chats.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchChats,
            child: ListView(
              key: ValueKey(isDark),
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 80),
                Center(child: Text("لا توجد محادثات بعد")),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchChats,
          child: ListView.builder(
            key: ValueKey(isDark),
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final type = chat['type']?.toString();
              final isAdmin = chat['isAdmin'] == true ||
                  (chat['lastSender']?.toString().toLowerCase() == 'admin');
              var name =
                  chat['customerName']?.toString() ??
                  chat['name']?.toString() ??
                  'Chat';
              if (isAdmin) {
                name = 'الإدارة';
              }
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
              final customerId = chat['customerId']?.toString();
              final unread = _getUnreadCount(chat);
              return InkWell(
                onLongPress: () {
                  return longPress(
                    type,
                    context: context,
                    requestId: requestId,
                    customerId: customerId,
                    isDirect: type == 'direct',
                  );
                },
                onTap: () {
                  if (type == 'direct') {
                    if (customerId == null || customerId.isEmpty) return;
                    Get.to(
                      () => ArtisanChatView(
                        requestId: '',
                        customerId: customerId,
                        customerName: name,
                        isDirect: true,
                      ),
                    );
                  } else {
                    if (requestId.isEmpty) return;
                    Get.to(
                      () => ArtisanChatView(
                        requestId: requestId,
                        customerName: name,
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Get.isDarkMode
                            ? Colors.black87.withOpacity(.1)
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            if (isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'رسالة من الإدارة',
                                  style: AppTextStyles.small(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.error,
                                  ),
                                ),
                              )
                            else if (type == 'direct')
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'محادثة مباشرة',
                                  style: AppTextStyles.small(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              style: AppTextStyles.small(
                                context,
                              ).copyWith(color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // IconButton(
                      //   tooltip: 'حذف المحادثة',
                      //   icon: Icon(
                      //     IconBroken.Delete,
                      //     color: cs.onSurface.withOpacity(0.8),
                      //   ),
                      //   onPressed: () => _confirmDeleteChat(
                      //     context: context,
                      //     requestId: requestId,
                      //     customerId: customerId,
                      //     isDirect: type == 'direct',
                      //   ),
                      // ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(time),
                            style: AppTextStyles.small(
                              context,
                            ).copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unread',
                                style: TextStyle(
                                  color: cs.onError,
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

