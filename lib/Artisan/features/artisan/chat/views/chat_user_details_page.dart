import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/features/artisan/chat/controllers/chat_controller.dart';
import 'package:usta/Artisan/features/artisan/chat/views/image_viewer_page.dart';
import 'package:usta/Artisan/features/artisan/chat/views/video_viewer_page.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

class ChatUserDetailsPage extends StatelessWidget {
  final String name;
  final String requestId;
  final String? customerId;
  final bool isDirect;

  const ChatUserDetailsPage({
    super.key,
    required this.name,
    required this.requestId,
    this.customerId,
    this.isDirect = false,
  });

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>(tag: 'artisan');
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            name,
            style: const TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: accent,
            tabs: [
              Tab(text: _tr('المعلومات', 'Info')),
              Tab(text: _tr('الصور', 'Photos')),
              Tab(text: _tr('الفيديوهات', 'Videos')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _infoTab(context, surface, onSurface, accent),
            Obx(() {
              final images = _mediaOf(chatController.messages, isVideo: false);
              return _mediaGrid(context, images, isVideo: false);
            }),
            Obx(() {
              final videos = _mediaOf(chatController.messages, isVideo: true);
              return _mediaGrid(context, videos, isVideo: true);
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoTab(BuildContext context, Color surface, Color onSurface, Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Text(
                      name.isNotEmpty ? name.characters.first : '?',
                      style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: "Cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDirect ? _tr('محادثة مباشرة', 'Direct chat') : _tr('محادثة على طلب', 'Request chat'),
                          style: TextStyle(color: onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(
                context,
                label: _tr('معرّف الطلب', 'Request ID'),
                value: requestId,
              ),
              if (customerId != null) ...[
                const SizedBox(height: 8),
                _infoRow(
                  context,
                  label: _tr('معرّف المستخدم', 'Customer ID'),
                  value: customerId!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _tr('تفاصيل إضافية', 'More details'),
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            'سيتم عرض المزيد من المعلومات هنا عندما تتوفر بيانات إضافية عن المستخدم.',
            'Additional info will appear here when more user data is available.',
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75)),
        ),
      ],
    );
  }

  List<String> _mediaOf(List messages, {required bool isVideo}) {
    final urls = <String>{};
    for (final m in messages) {
      final attachments = <String>[];
      if (m['attachments'] is List) {
        for (final e in (m['attachments'] as List)) {
          if (e is Map && e['url'] != null) {
            attachments.add(e['url'].toString());
          } else {
            attachments.add(e.toString());
          }
        }
      } else if (m['attachment'] != null) {
        final e = m['attachment'];
        if (e is Map && e['url'] != null) {
          attachments.add(e['url'].toString());
        } else {
          attachments.add(e.toString());
        }
      }
      for (final att in attachments) {
        final lower = att.toLowerCase();
        final isImg = lower.contains('image') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.webp');
        final isVid = lower.contains('video') ||
            lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.mkv');
        if (isVideo && isVid) {
          urls.add(att);
        } else if (!isVideo && isImg) {
          urls.add(att);
        }
      }
      final type = (m['type'] ?? '').toString().toLowerCase();
      if (type == 'video' && isVideo && m['url'] != null) {
        urls.add(m['url'].toString());
      } else if (type == 'image' && !isVideo && m['url'] != null) {
        urls.add(m['url'].toString());
      }
    }
    return urls.toList();
  }

  Widget _mediaGrid(BuildContext context, List<String> urls, {required bool isVideo}) {
    if (urls.isEmpty) {
      return Center(child: Text(_tr('لا يوجد محتوى بعد', 'No media yet')));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) {
        final raw = urls[i];
        final url = _resolveUrl(raw);
        final heroTag = '${isVideo ? 'vid' : 'img'}:$raw';
        return GestureDetector(
          onTap: () {
            if (isVideo) {
              Get.to(() => VideoViewerPage(url: url, title: _tr('فيديو', 'Video'), heroTag: heroTag));
            } else {
              Get.to(() => ImageViewerPage(url: url, heroTag: heroTag));
            }
          },
          child: Hero(
            tag: heroTag,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
                image: isVideo
                    ? null
                    : DecorationImage(
                        image: url.startsWith('data:')
                            ? MemoryImage(Uri.parse(url).data!.contentAsBytes())
                            : NetworkImage(url) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
              ),
              child: isVideo
                  ? Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _tr(String ar, String en) {
    final code = Get.locale?.languageCode;
    if (code == 'ar') return ar;
    return en;
  }

  String _resolveUrl(String url) {
    if (url.startsWith('data:')) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = ApiEndpoints.baseUrl.endsWith('/api')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 4)
        : ApiEndpoints.baseUrl;
    if (!base.endsWith('/')) {
      return '$base$url';
    }
    return '$base${url.startsWith('/') ? url.substring(1) : url}';
  }
}

