import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/widgets/icon_broken.dart';
import 'package:usta/Artisan/features/artisan/chat/controllers/chat_controller.dart';
import 'package:usta/Artisan/features/artisan/chat/views/chat_user_details_page.dart';
import 'package:usta/Artisan/features/artisan/chat/views/image_viewer_page.dart';
import 'package:usta/Artisan/features/artisan/chat/views/video_viewer_page.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ArtisanChatView extends StatefulWidget {
  final String customerName;
  final String requestId;
  final String? customerId;
  final bool isDirect;

  const ArtisanChatView({
    super.key,
    required this.customerName,
    required this.requestId,
    this.customerId,
    this.isDirect = false,
  });

  @override
  State<ArtisanChatView> createState() => _ArtisanChatViewState();
}

class _ArtisanChatViewState extends State<ArtisanChatView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final ChatController controller = Get.find<ChatController>(tag: 'artisan');
  final msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final Set<String> _expanded = HashSet<String>();
  final ImagePicker _picker = ImagePicker();
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, StreamSubscription<PlayerState>> _audioStateSubs = {};
  final Map<String, StreamSubscription<Duration>> _audioPosSubs = {};
  final Map<String, StreamSubscription<Duration?>> _audioDurSubs = {};
  final Map<String, Duration> _audioPositions = {};
  final Map<String, Duration?> _audioDurations = {};
  String? _currentPlayingUrl;
  final Set<String> _audioLoading = {};
  final Map<String, Uint8List?> _videoThumbCache = {};
  final Map<String, Future<Uint8List?>> _videoThumbFutures = {};
  bool _showAttachmentActions = false;
  AudioRecorder? _recorder;
  bool _recorderSupported = true;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  int _lastMessageCount = 0;
  bool _didInitialScroll = false;

  Future<void> _confirmDeleteMessage(String messageId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه الرسالة؟ لا يمكن التراجع عن هذا الإجراء.'),
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
    if (widget.isDirect) {
      await controller.deleteDirectMessage(messageId);
    } else {
      await controller.deleteRequestMessage(messageId);
    }
  }

  Future<void> _showEditMessageDialog(
    String messageId,
    String currentText,
  ) async {
    final editCtrl = TextEditingController(text: currentText);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: editCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final updated = editCtrl.text.trim();
    if (updated.isEmpty) return;
    if (widget.isDirect) {
      await controller.editDirectMessage(messageId, updated);
    } else {
      await controller.editRequestMessage(messageId, updated);
    }
  }

  void _showMessageActions({
    required String messageId,
    required bool canEdit,
    required String text,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  ListTile(
                    leading: const Icon(IconBroken.Edit),
                    title: const Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditMessageDialog(messageId, text);
                    },
                  ),
                ListTile(
                  leading: const Icon(IconBroken.Delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(messageId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  @override
  void initState() {
    super.initState();
    controller.setChatScreenOpen(true);
    if (widget.isDirect && widget.customerId != null) {
      controller.activeRequestId = null;
      controller.activeCustomerId = widget.customerId!;
      controller.fetchDirectMessages(widget.customerId!);
    } else {
      controller.activeCustomerId = null;
      controller.activeRequestId = widget.requestId;
      controller.fetchMessages(widget.requestId);
    }
  }

  @override
  void dispose() {
    controller.setChatScreenOpen(false);
    controller.clearActive();
    for (final p in _audioPlayers.values) {
      p.dispose();
    }
    for (final sub in _audioStateSubs.values) {
      sub.cancel();
    }
    for (final sub in _audioPosSubs.values) {
      sub.cancel();
    }
    for (final sub in _audioDurSubs.values) {
      sub.cancel();
    }
    _recordTimer?.cancel();
    _recorder?.dispose();
    msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }


  String _idOf(Map<String, dynamic> m) =>
      (m['localId'] ?? m['_id'] ?? m['id'] ?? m['messageId'] ?? '').toString();

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    final dt = DateTime.tryParse(time);
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _scrollToBottom({bool force = false}) {
    if (!_scrollCtrl.hasClients) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom(force: force));
      return;
    }
    final position = _scrollCtrl.position;
    final target = position.maxScrollExtent + 24;
    final distance = (target - position.pixels).abs();
    if (!force && (distance > 1600 || distance < 8)) return;
    if (force && distance > 2000) {
      _scrollCtrl.jumpTo(target);
      return;
    }
    final durationMs = distance.clamp(180, 420).toInt();
    _scrollCtrl.animateTo(
      target,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: InkWell(
          onTap: () => Get.to(
            () => ChatUserDetailsPage(
              name: widget.customerName,
              customerId: widget.customerId,
              requestId: widget.requestId,
              isDirect: widget.isDirect,
            ),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
            child: Text(
              widget.customerName,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.loadingMessages.value &&
                  controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = controller.messages;
              if (messages.isNotEmpty && !_didInitialScroll) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(force: true);
                  _didInitialScroll = true;
                });
              } else if (messages.length > _lastMessageCount) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_scrollCtrl.hasClients) return;
                  final distanceFromBottom =
                      _scrollCtrl.position.maxScrollExtent -
                      _scrollCtrl.position.pixels;
                  // لو المستخدم مش بعيد عن آخر الرسائل، اسحب له بسلاسة
                  if (distanceFromBottom < 400) {
                    _scrollToBottom();
                  }
                });
              }
              _lastMessageCount = messages.length;
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final text =
                      m['text']?.toString() ?? m['message']?.toString() ?? '';
                  final fromMe =
                      m['isMine'] == true ||
                      m['sender']?.toString().toLowerCase() == 'artisan' ||
                      m['role']?.toString().toLowerCase() == 'artisan';
                  final senderRole =
                      (m['sender'] ?? m['role'])?.toString().toLowerCase() ??
                          '';
                  final isAdmin = senderRole == 'admin';
                  final msgId = _idOf(m);
                  final showMeta = _expanded.contains(msgId);
                  final createdAt =
                      m['createdAt']?.toString() ??
                      m['updatedAt']?.toString() ??
                      '';
                  final state = m['state']?.toString() ?? '';
                  final edited = m['edited'] == true;
                  final read =
                      m['read'] == true ||
                      m['readBy']?['customer'] == true ||
                      state == 'read';
                  final sending =
                      state == 'sending' || state == 'retrying';
                  final sent =
                      state == 'sent' || state == 'downloaded' || m['_id'] != null;
                  final uploadProgress =
                      (m['uploadProgress'] as num?)?.toDouble();
                  final downloadProgress =
                      (m['downloadProgress'] as num?)?.toDouble();
                  final localFilePath = m['localFilePath']?.toString();
                  final attachments = _attachments(m);
                  final mediaSources = attachments.isNotEmpty
                      ? attachments
                      : (localFilePath != null ? [localFilePath] : <String>[]);
                  final isAudioType =
                      (m['type'] ?? '').toString().toLowerCase() == 'audio';
                  final isVideoType =
                      (m['type'] ?? '').toString().toLowerCase() == 'video';
                  final type =
                      (m['type'] ?? '').toString().toLowerCase();
                  final canEdit = fromMe &&
                      text.trim().isNotEmpty &&
                      mediaSources.isEmpty &&
                      !isAudioType &&
                      !isVideoType &&
                      (type.isEmpty || type == 'text');

                  final hidden = {"[audio]", "[image]", "[video]"};

                  return Align(
                    alignment: fromMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (showMeta) {
                            _expanded.remove(msgId);
                          } else {
                            _expanded.add(msgId);
                          }
                        });
                      },
                      onLongPress: () {
                        if (!fromMe || msgId.isEmpty) return;
                        _showMessageActions(
                          messageId: msgId,
                          canEdit: canEdit,
                          text: text,
                        );
                      },
                      child: Container(
                        padding: hidden.contains(text)
                            ? EdgeInsets.all(6)
                            : EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: fromMe
                              ? Theme.of(context).colorScheme.primary.withOpacity(.9)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (mediaSources.isNotEmpty)
                              ...mediaSources.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: _attachmentWidget(
                                    url: url,
                                    fromMe: fromMe,
                                    localId: msgId,
                                    state: state,
                                    uploadProgress: uploadProgress,
                                    downloadProgress: downloadProgress,
                                    localFilePath: localFilePath,
                                    isAudioType: isAudioType,
                                    heroSuffix: msgId,
                                    onDownload: fromMe
                                        ? null
                                        : () => controller.startDownload(
                                              msgId,
                                              url,
                                            ),
                                    onCancel: () => controller.cancelMessage(
                                      msgId,
                                    ),
                                    onRetry: () =>
                                        controller.retryMessage(msgId),
                                  ),
                                ),
                              ),
                            if (mediaSources.isEmpty && isVideoType)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _videoPlaceholder(fromMe, sending),
                              ),
                            if (isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'رسالة من الإدارة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                                ),
                              ),
                            if (text.isNotEmpty)
                              hidden.contains(text)
                                  ? const SizedBox.shrink()
                                  : Text(
                                      text,
                                      style: TextStyle(
                                        fontFamily: "Cairo",
                                        color: fromMe
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSecondary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                      ),
                                    ),
                            if (true )
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (sending)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          // valueColor: AlwaysStoppedAnimation(
                                          //   Colors.white70,
                                          // ),
                                        ),
                                      ),
                                    if (sending) const SizedBox(width: 6),
                                    Text(
                                      _formatTime(createdAt),
                                      style: TextStyle(
                                        fontFamily: "Cairo",
                                        fontSize: 11,
                                        color: fromMe
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSecondary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                        // color: fromMe
                                        //     ? Colors.white70
                                        //     : Theme.of(context)
                                        //           .colorScheme
                                        //           .onSurface
                                        //           .withOpacity(0.7),
                                      ),
                                    ),
                                    if (edited) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        'تم التعديل',
                                        style: TextStyle(
                                          fontFamily: "Cairo",
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    if (fromMe) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        sending
                                            ? Icons.access_time
                                            : read
                                            ? Icons.done_all
                                            : sent
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 16,
                                        color: sending
                                            ? Colors.white54
                                            : read
                                            ? Colors.lightBlueAccent
                                            : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _showAttachmentActions
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              _attachmentChip(
                                icon: Icons.image,
                                label: _tr('صورة', 'Photo'),
                                color: primaryBlue,
                                onTap: controller.sending.value
                                    ? null
                                    : () {
                                        setState(
                                          () => _showAttachmentActions = false,
                                        );
                                        _pickMedia(isVideo: false);
                                      },
                              ),
                              const SizedBox(width: 8),
                              _attachmentChip(
                                icon: Icons.videocam,
                                label: _tr('فيديو', 'Video'),
                                color: primaryBlue,
                                onTap: controller.sending.value
                                    ? null
                                    : () {
                                        setState(
                                          () => _showAttachmentActions = false,
                                        );
                                        _pickMedia(isVideo: true);
                                      },
                              ),
                              const SizedBox(width: 8),
                              _attachmentChip(
                                icon: _isRecording ? Icons.stop : Icons.mic,
                                label: _isRecording
                                    ? _tr('إيقاف', 'Stop')
                                    : _tr('صوت', 'Audio'),
                                color: _isRecording ? Colors.red : primaryBlue,
                                onTap: controller.sending.value
                                    ? null
                                    : () {
                                        setState(
                                          () => _showAttachmentActions = false,
                                        );
                                        if (!_recorderSupported) {
                                          _pickAudioFile();
                                          return;
                                        }
                                        if (_isRecording) {
                                          _stopRecording();
                                        } else {
                                          _startRecording();
                                        }
                                      },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.sending.value
                          ? null
                          : () => setState(
                                () =>
                                    _showAttachmentActions =
                                        !_showAttachmentActions,
                              ),
                      icon: Icon(
                        _showAttachmentActions
                            ? Icons.close
                            : Icons.add_circle_outline,
                        color: primaryBlue,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: msgCtrl,
                        style: AppTextStyles.body(context),
                        decoration: InputDecoration(
                          hintText: "اكتب رسالة...",
                          hintStyle: AppTextStyles.body(context),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).inputDecorationTheme.fillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.lightBlueAccent,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Obx(() {
                      final disabled = controller.sending.value;
                      return IconButton(
                        onPressed: disabled
                            ? null
                            : () async {
                                if (_isRecording) {
                                  await _stopRecording(sendNow: true);
                                  return;
                                }
                                if (widget.isDirect &&
                                    widget.customerId != null) {
                                  controller.sendDirectText(
                                    widget.customerId!,
                                    msgCtrl.text,
                                  );
                                } else {
                                  controller.sendTextMessage(
                                    widget.requestId,
                                    msgCtrl.text,
                                  );
                                }
                                msgCtrl.clear();
                              },
                        icon: Icon(
                          IconBroken.Send,
                          color: disabled ? Colors.grey : primaryBlue,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatRecordDuration(),
                    style: AppTextStyles.body(context).copyWith(color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'جاري التسجيل...',
                    style: AppTextStyles.body(context).copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _attachments(Map<String, dynamic> m) {
    final list = <String>[];
    if (m['attachments'] is List) {
      list.addAll(
        (m['attachments'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty),
      );
    }
    if (m['image'] != null) list.add(m['image'].toString());
    if (m['video'] != null) list.add(m['video'].toString());
    return list;
  }

  Future<Uint8List?> _getVideoThumbnail(String url) {
    if (_videoThumbCache.containsKey(url)) {
      return Future.value(_videoThumbCache[url]);
    }
    if (_videoThumbFutures.containsKey(url)) return _videoThumbFutures[url]!;
    final future =
        VideoThumbnail.thumbnailData(
              video: url,
              imageFormat: ImageFormat.PNG,
              maxWidth: 320,
              quality: 60,
            )
            .then((data) {
              _videoThumbCache[url] = data;
              return data;
            })
            .catchError((_) {
              _videoThumbCache[url] = null;
              return null;
            });
    _videoThumbFutures[url] = future;
    return future;
  }

  Widget _videoPlaceholder(bool fromMe, bool sending) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fromMe ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam, color: fromMe ? Colors.white : Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sending ? 'جاري رفع الفيديو...' : 'فيديو',
              style: TextStyle(
                color: fromMe
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 18,
            height: 18,
            child: sending
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _attachmentChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(disabled ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // color: disabled ? Colors.grey : color,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color:  Theme.of(context).colorScheme.onSurface ,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentWidget({
    required String url,
    required bool fromMe,
    required String localId,
    required String state,
    double? uploadProgress,
    double? downloadProgress,
    String? localFilePath,
    bool isAudioType = false,
    String? heroSuffix,
    VoidCallback? onDownload,
    VoidCallback? onCancel,
    VoidCallback? onRetry,
  }) {
    final rawPath = (localFilePath != null && localFilePath.isNotEmpty)
        ? localFilePath
        : url;
    final path = rawPath.startsWith('file://')
        ? rawPath.substring(7)
        : rawPath;
    final lower = path.toLowerCase();
    final uploadsBase = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;
    final uploadsNoApi =
        uploadsBase.endsWith('/api') ? uploadsBase.substring(0, uploadsBase.length - 4) : uploadsBase;
    final resolvedUrl = path.startsWith('http')
        ? path
        : path.startsWith('/uploads')
            ? '$uploadsNoApi$path'
            : path;
    final isImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.contains('image/');
    final isVideo =
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.contains('video/');
    final isAudio =
        isAudioType ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.wav') ||
        lower.contains('audio/');
    final file = File(path).existsSync() ? File(path) : null;
    final isUploading = state == 'sending' || state == 'retrying';
    final isDownloading = state == 'downloading';
    final isFailed = state == 'failed';
    final showDownload = !fromMe &&
        state == 'sent' &&
        (localFilePath == null || localFilePath.isEmpty) &&
        !isUploading &&
        !isDownloading &&
        !isFailed;

    Widget overlay() {
        if (isUploading) {
          final progress = uploadProgress ?? 0.0;
          return _attachmentOverlay(
            label: _tr('جارٍ الرفع', 'Uploading'),
            progress: progress,
            onCancel: onCancel,
          );
        }
        if (isDownloading) {
          final progress = downloadProgress ?? 0.0;
          return _attachmentOverlay(
            label: _tr('جارٍ التحميل', 'Downloading'),
            progress: progress,
            onCancel: onCancel,
          );
        }
        if (isFailed) {
          return _retryOverlay(onRetry);
        }
        if (showDownload) {
          return _downloadOverlay(onDownload);
        }
        return const SizedBox.shrink();
    }

    Widget media;
    if (isImage) {
      final heroTag = 'image:${heroSuffix ?? resolvedUrl}';
      final imageWidget = file != null
          ? Image.file(
              file,
              width: 220,
              height: 180,
              fit: BoxFit.cover,
            )
          : resolvedUrl.startsWith('http')
              ? Image.network(
                  resolvedUrl,
                  width: 220,
                  height: 180,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(resolvedUrl),
                  width: 220,
                  height: 180,
                  fit: BoxFit.cover,
                );
      media = GestureDetector(
        onTap: () => Get.to(
          () => ImageViewerPage(url: resolvedUrl, heroTag: heroTag),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 200),
        ),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget,
          ),
        ),
      );
      media = Stack(
        children: [
          media,
          Positioned.fill(child: overlay()),
        ],
      );
      return media;
    }

    if (isVideo) {
      final heroTag = 'video:${heroSuffix ?? resolvedUrl}';
      final card = Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Uint8List?>(
              future: _getVideoThumbnail(file?.path ?? resolvedUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black38,
                    ),
                  );
                }
                if (snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      snapshot.data!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
          ],
        ),
      );
      media = Stack(
        children: [
          GestureDetector(
            onTap: () => Get.to(
              () => VideoViewerPage(
                url: file?.path ?? resolvedUrl,
                title: 'فيديو',
                heroTag: heroTag,
              ),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
            ),
            child: Hero(tag: heroTag, child: card),
          ),
          Positioned.fill(child: overlay()),
        ],
      );
      return media;
    }

    if (isAudio) {
      final resolvedAudio = file?.path ?? resolvedUrl;
      final player = _playerFor(resolvedAudio);
      final isPlaying = player.playing;
      final isLoading = _audioLoading.contains(resolvedAudio);
      final pos = _audioPositions[resolvedAudio] ?? Duration.zero;
      final total = _audioDurations[resolvedAudio] ?? player.duration;
      final totalMs = total?.inMilliseconds ?? 1;
      final valueMs = pos.inMilliseconds.clamp(0, totalMs);
      final bubbleColor = fromMe ? Colors.blue.shade50 : Colors.grey.shade200;
      final iconBg = fromMe ? primaryBlue : Colors.white;
      final iconColor = fromMe ? Colors.white : primaryBlue;
      final bars = const [
        10.0,
        15.0,
        8.0,
        14.0,
        6.0,
        12.0,
        9.0,
        13.0,
        7.0,
        11.0,
        9.0,
        12.0,
      ];
      media = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: isUploading || isDownloading || isFailed
                  ? null
                  : () => _toggleAudio(resolvedAudio),
              borderRadius: BorderRadius.circular(24),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: iconBg,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: iconColor,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    isUploading
                        ? _tr('جارٍ الرفع', 'Uploading...')
                        : isDownloading
                            ? _tr('جارٍ التحميل', 'Downloading...')
                            : isPlaying
                                ? _tr('يتم التشغيل الآن', 'Playing now')
                                : _tr('رسالة صوتية', 'Voice message'),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final barCount = 20;
                      final spacing = 3.0;
                      final barWidth =
                          (c.maxWidth - (barCount - 1) * spacing) / barCount;
                      final progress = totalMs <= 0 ? 0.0 : valueMs / totalMs;
                      final isRtl = Directionality.of(ctx) == TextDirection.rtl;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (d) {
                          if (total == null) return;
                          final dx = d.localPosition.dx
                              .clamp(0, c.maxWidth)
                              .toDouble();
                          _seekInWave(
                            player: player,
                            url: resolvedAudio,
                            dx: dx,
                            width: c.maxWidth,
                            totalMs: totalMs,
                          );
                        },
                        onPanUpdate: (d) {
                          if (total == null) return;
                          final dx = d.localPosition.dx
                              .clamp(0, c.maxWidth)
                              .toDouble();
                          _seekInWave(
                            player: player,
                            url: resolvedAudio,
                            dx: dx,
                            width: c.maxWidth,
                            totalMs: totalMs,
                          );
                        },
                        child: SizedBox(
                          width: c.maxWidth,
                          height: 28,
                          child: Row(
                            children: List.generate(barCount, (i) {
                              final idx = isRtl ? (barCount - i) : (i + 1);
                              final filled = idx / barCount <= progress;
                              final base = bars[i % bars.length];
                              final animBump = isPlaying
                                  ? 4 *
                                          math.sin(
                                            (pos.inMilliseconds / 180) +
                                                (i * 0.6),
                                          )
                                  : 0;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: i == barCount - 1 ? 0 : spacing,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: barWidth,
                                  height: (base + animBump).clamp(6, 24),
                                  decoration: BoxDecoration(
                                    color: filled
                                        ? primaryBlue
                                        : primaryBlue.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(pos),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDuration(total ?? Duration.zero),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      return Stack(
        children: [
          media,
          Positioned.fill(child: overlay()),
        ],
      );
    }
    return Stack(
      children: [
        InkWell(
          onTap: () => _launchUrl(resolvedUrl),
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fromMe ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_circle, color: Colors.white70),
                SizedBox(width: 8),
                Text('وسائط', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        Positioned.fill(child: overlay()),
      ],
    );
  }

  Widget _attachmentOverlay({
    required String label,
    double? progress,
    VoidCallback? onCancel,
  }) {
    final pct = progress != null ? (progress * 100).clamp(0, 100).toInt() : 0;
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              value: progress?.clamp(0.0, 1.0),
              strokeWidth: 4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == null ? label : "$label ($pct%)",
            style: const TextStyle(color: Colors.white),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }

  Widget _retryOverlay(VoidCallback? onRetry) {
    if (onRetry == null) return const SizedBox.shrink();
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
        onPressed: onRetry,
      ),
    );
  }

  Widget _downloadOverlay(VoidCallback? onDownload) {
    if (onDownload == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black54,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: onDownload,
          ),
        ),
      ),
    );
  }
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  AudioPlayer _playerFor(String url) {
    final player = _audioPlayers.putIfAbsent(url, () => AudioPlayer());
    if (!_audioStateSubs.containsKey(url)) {
      _audioStateSubs[url] = player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero);
          await player.pause();
          if (_currentPlayingUrl == url) {
            _currentPlayingUrl = null;
          }
          if (mounted) setState(() {});
        }
      });
    }
    _audioPosSubs.putIfAbsent(
      url,
      () => player.positionStream.listen((pos) {
        _audioPositions[url] = pos;
        if (mounted) setState(() {});
      }),
    );
    _audioDurSubs.putIfAbsent(
      url,
      () => player.durationStream.listen((dur) {
        _audioDurations[url] = dur;
        if (mounted) setState(() {});
      }),
    );
    return player;
  }

  Future<void> _stopAllExcept(String keepUrl) async {
    for (final entry in _audioPlayers.entries) {
      if (entry.key == keepUrl) continue;
      final p = entry.value;
      await p.pause();
      await p.seek(Duration.zero);
    }
  }

  void _seekInWave({
    required AudioPlayer player,
    required String url,
    required double dx,
    required double width,
    required int totalMs,
  }) {
    if (totalMs <= 0 || width <= 0) return;
    final targetMs = (dx / width * totalMs).clamp(0, totalMs).toInt();
    player.seek(Duration(milliseconds: targetMs));
    _audioPositions[url] = Duration(milliseconds: targetMs);
    if (mounted) setState(() {});
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    try {
      final picked = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
      if (picked == null) return;
      final file = File(picked.path);
      final size = await file.length();
      final limit = isVideo ? 20 * 1024 * 1024 : 3 * 1024 * 1024;
      if (size > limit) {
        _showSnack(
          isVideo
              ? AppStrings.videoTooLarge.tr
              : AppStrings.imageTooLarge.tr,
          SnackBarType.error,
        );
        return;
      }
      final mime =
          picked.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg');
      if (widget.isDirect && widget.customerId != null) {
        await controller.sendDirectAttachment(
          widget.customerId!,
          dataUri: picked.path,
          mime: mime,
        );
      } else {
        await controller.sendRequestAttachment(
          widget.requestId,
          dataUri: picked.path,
          mime: mime,
        );
      }
    } catch (_) {
      _showSnack(AppStrings.filePickFailed.tr, SnackBarType.error);
    }
  }

  Future<void> _startRecording() async {
    if (!_recorderSupported) {
      await _pickAudioFile();
      return;
    }
    try {
      if (_recorder == null) {
        try {
          final rec = AudioRecorder();
          final hasPerm = await rec.hasPermission();
          if (!hasPerm) {
            _showSnack(
              AppStrings.microphonePermissionRequired.tr,
              SnackBarType.error,
            );
            return;
          }
          _recorder = rec;
        } on MissingPluginException {
          _recorderSupported = false;
          await _pickAudioFile();
          return;
        }
      }
      final hasPerm = await _recorder!.hasPermission();
      if (!hasPerm) {
        _showSnack(
          AppStrings.microphonePermissionRequired.tr,
          SnackBarType.error,
        );
        return;
      }
      _recordDuration = Duration.zero;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      });
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      setState(() => _isRecording = true);
    } on MissingPluginException {
      _recorderSupported = false;
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });
      _showSnack(
        AppStrings.recordingNotAvailable.tr,
        SnackBarType.error,
      );
      await _pickAudioFile();
    } catch (_) {
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      _showSnack(AppStrings.recordingStartFailed.tr, SnackBarType.error);
    }
  }

  Future<void> _stopRecording({bool sendNow = true}) async {
    try {
      final path = await _recorder?.stop();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });
      if (path == null) return;
      final file = File(path);
      if (!await file.exists()) return;
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        _showSnack(AppStrings.audioTooLarge.tr, SnackBarType.error);
        return;
      }
      final ext = path.split('.').last.toLowerCase();
      final mime = ext == 'wav'
          ? 'audio/wav'
          : ext == 'ogg'
              ? 'audio/ogg'
              : ext == 'aac' || ext == 'm4a'
                  ? 'audio/aac'
                  : 'audio/mpeg';
      if (sendNow) {
        if (widget.isDirect && widget.customerId != null) {
          await controller.sendDirectAttachment(
            widget.customerId!,
            dataUri: path,
            mime: mime,
          );
        } else {
          await controller.sendRequestAttachment(
            widget.requestId,
            dataUri: path,
            mime: mime,
          );
        }
      }
    } catch (_) {
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });
      _showSnack(AppStrings.recordingStopFailed.tr, SnackBarType.error);
    }
  }
  Future<void> _toggleAudio(String url) async {
    final player = _playerFor(url);
    if (_audioLoading.contains(url)) return;
    try {
      if (!player.playing) {
        await _stopAllExcept(url);
        _currentPlayingUrl = url;
        _audioLoading.add(url);
        setState(() {});
        if (url.startsWith('http')) {
          await player.setUrl(url);
        } else {
          final path = url.startsWith('file://') ? url.substring(7) : url;
          await player.setFilePath(path);
        }
        _audioLoading.remove(url);
        setState(() {});
        await player.play();
      } else {
        await player.pause();
        _currentPlayingUrl = null;
        setState(() {});
      }
    } catch (_) {
      _audioLoading.remove(url);
      setState(() {});
      _showSnack(AppStrings.audioPlayFailed.tr, SnackBarType.error);
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'aac', 'ogg', 'wav'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final ext = (file.extension ?? 'mp3').toLowerCase();
      final mime = ext == 'wav'
          ? 'audio/wav'
          : ext == 'ogg'
              ? 'audio/ogg'
              : ext == 'aac' || ext == 'm4a'
                  ? 'audio/aac'
                  : 'audio/mpeg';
      Uint8List? bytes = file.bytes;
      String? path = file.path;
      if (path == null || path.isEmpty) {
        if (bytes == null) return;
        final tempDir = await getTemporaryDirectory();
        path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(path).writeAsBytes(bytes, flush: true);
      }
      final fileLength = bytes?.length ?? await File(path).length();
      if (fileLength > 5 * 1024 * 1024) {
        _showSnack(AppStrings.audioTooLarge.tr, SnackBarType.error);
        return;
      }
      if (widget.isDirect && widget.customerId != null) {
        await controller.sendDirectAttachment(
          widget.customerId!,
          dataUri: path,
          mime: mime,
        );
      } else {
        await controller.sendRequestAttachment(
          widget.requestId,
          dataUri: path,
          mime: mime,
        );
      }
    } catch (_) {
      _showSnack(AppStrings.filePickFailed.tr, SnackBarType.error);
    }
  }

  void _showSnack(String message, SnackBarType type) {
    String title;
    switch (type) {
      case SnackBarType.error:
        title = AppStrings.error.tr;
        break;
      case SnackBarType.warning:
        title = AppStrings.warning.tr;
        break;
      case SnackBarType.success:
        title = AppStrings.success.tr;
        break;
      case SnackBarType.info:
        title = AppStrings.info.tr;
        break;
    }
    AppSnackBar.show(title, message, type: type);
  }

  String _formatRecordDuration() {
    final mm = _recordDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final ss = _recordDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$mm:$ss';
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _tr(String ar, String en) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'ar' ? ar : en;
  }
}




