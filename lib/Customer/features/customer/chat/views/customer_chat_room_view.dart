import 'dart:async';
import 'dart:collection';
import 'dart:convert';
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
import 'package:usta/Customer/core/utils/constants/api_endpoints.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/chat/controller/chat_controller.dart';
import 'package:usta/Customer/features/customer/chat/views/chat_user_details_view.dart';
import 'package:usta/Customer/features/customer/chat/views/image_viewer_page.dart';
import 'package:usta/Customer/features/customer/chat/views/video_viewer_page.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CustomerChatRoomView extends StatefulWidget {
  final String customerName;
  final String requestId;
  final String? customerId;
  final bool isDirect;

  const CustomerChatRoomView({
    super.key,
    required this.customerName,
    required this.requestId,
    this.customerId,
    this.isDirect = false,
  });

  @override
  State<CustomerChatRoomView> createState() => _CustomerChatRoomViewState();
}

class _CustomerChatRoomViewState extends State<CustomerChatRoomView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final ChatController controller = Get.find<ChatController>(tag: 'customer');
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

  @override
  void initState() {
    super.initState();
    if (widget.isDirect && widget.customerId != null) {
      controller.fetchMessages(widget.customerId!, direct: true);
    } else {
      controller.fetchMessages(widget.requestId);
    }
    controller.setActiveConversation(
      widget.isDirect ? (widget.customerId ?? '') : widget.requestId,
      direct: widget.isDirect,
    );
  }

  @override
  void dispose() {
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

  void _showMessageActions(
    BuildContext context, {
    required Map<String, dynamic> message,
    required ChatController controller,
  }) {
    if (!widget.isDirect) return;
    final isText = (message['attachments'] is! List ||
            (message['attachments'] as List).isEmpty) &&
        ((message['type'] ?? '').toString() == 'text');
    final messageId =
        (message['_id'] ?? message['id'] ?? message['localId'] ?? '').toString();
    if (messageId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isText)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('تعديل الرسالة'.tr),
                onTap: () {
                  Navigator.of(context).pop();
                  _promptEditMessage(
                    context,
                    controller,
                    messageId,
                    initial:
                        (message['text'] ?? message['message'] ?? '').toString(),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('حذف الرسالة'.tr),
              onTap: () async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('تأكيد الحذف'.tr),
                    content: Text('سيتم حذف هذه الرسالة. هل أنت متأكد؟'.tr),
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
                  await controller.deleteDirectMessage(messageId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptEditMessage(
    BuildContext context,
    ChatController controller,
    String messageId, {
    required String initial,
  }) {
    final controllerText = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تعديل الرسالة'.tr),
        content: TextField(
          controller: controllerText,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'.tr),
          ),
          TextButton(
            onPressed: () async {
              final newText = controllerText.text.trim();
              Navigator.of(context).pop();
              if (newText.isNotEmpty) {
                await controller.editDirectMessage(messageId, newText);
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom({bool force = false}) {
    void scrollAction() {
      if (!_scrollCtrl.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollAction());
        return;
      }

      final position = _scrollCtrl.position;
      final target = position.maxScrollExtent + 24;
      final distance = (target - position.pixels).abs();

      if (!force && distance > 1600) return;
      if (!force && distance < 8) return;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollAction());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: InkWell(
          onTap: () => Get.to(
            () => ChatUserDetailsView(
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
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ShimmerSkeletons.chatBubble(fromMe: false),
                    ShimmerSkeletons.chatBubble(fromMe: true),
                    ShimmerSkeletons.chatBubble(fromMe: false),
                    ShimmerSkeletons.chatBubble(fromMe: true),
                    ShimmerSkeletons.chatBubble(fromMe: false),
                  ],
                );
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
                  final sender = (m['sender'] ?? m['role'] ?? '')
                      .toString()
                      .toLowerCase();
                  final fromMe =
                      m['isMine'] == true ||
                      sender == 'customer' ||
                      m['fromCustomer'] == true;
                  final bubbleColor = fromMe
                      ? primaryBlue.withOpacity(0.12)
                      : primaryBlue.withOpacity(0.1);
                  final textColor = fromMe
                      ? Colors.black
                      : Theme.of(context).colorScheme.onSurface;
                  final msgId = _idOf(m);
                  final showMeta = _expanded.contains(msgId);
                  final edited = m['edited'] == true;
                  final isAdmin = m['isAdmin'] == true;
                  final createdAt =
                      m['createdAt']?.toString() ??
                      m['updatedAt']?.toString() ??
                      '';
                  final state = m['state']?.toString();
                  final read =
                      m['read'] == true ||
                      m['readBy']?['customer'] == true ||
                      state == 'read';
                  final sending = state == 'sending';
                  final sent = state == 'sent' || m['_id'] != null;
                  final attachments = _attachments(m);
                  final localId = (m['localId'] ?? '').toString();
                  final uploadProgress =
                      (m['uploadProgress'] as num?)?.toDouble();
                  final downloadProgress =
                      (m['downloadProgress'] as num?)?.toDouble();
                  final localFilePath = m['localFilePath']?.toString();
                  final isAudioType =
                      (m['type'] ?? '').toString().toLowerCase() == 'audio';
                  final isVideoType =
                      (m['type'] ?? '').toString().toLowerCase() == 'video';
                  final hidden = {"[audio]", "[image]", "[video]"};
                  return Align(
                    alignment: fromMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: fromMe
                          ? () => _showMessageActions(
                                context,
                                message: m,
                                controller: controller,
                              )
                          : null,
                      onTap: () {
                        setState(() {
                          if (showMeta) {
                            _expanded.remove(msgId);
                          } else {
                            _expanded.add(msgId);
                          }
                        });
                      },
                      child: Container(
                        padding: hidden.contains(text)
                            ? EdgeInsets.all(6)
                            : EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (attachments.isNotEmpty)
                              ...attachments.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: _attachmentWidget(
                                    url: url,
                                    fromMe: fromMe,
                                    localId: localId,
                                    state: state ?? 'sent',
                                    uploadProgress: uploadProgress,
                                    downloadProgress: downloadProgress,
                                    localFilePath: localFilePath,
                                    isAudioType: isAudioType,
                                    heroSuffix: msgId.isNotEmpty
                                        ? msgId
                                        : 'idx$index',
                                    onDownload: fromMe
                                        ? null
                                        : () => controller.startDownload(
                                              localId,
                                              url,
                                            ),
                                    onCancel: () =>
                                        controller.cancelMessage(localId),
                                    onRetry: () =>
                                        controller.retryMessage(localId),
                                  ),
                                ),
                              ),
                            if (attachments.isEmpty && isVideoType)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _videoPlaceholder(fromMe, sending),
                              ),
                            if (text.isNotEmpty)
                              hidden.contains(text)
                                  ? SizedBox()
                                  : Text(
                                      text,
                                      style: TextStyle(
                                        fontFamily: "Cairo",
                                      ),
                                    ),
                            if (true)
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
                                        ),
                                      ),
                                    if (sending) const SizedBox(width: 6),
                                    Text(
                                      _formatTime(createdAt),
                                      style: TextStyle(
                                        fontFamily: "Cairo",
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        'من الإدارة'.tr,
                                        style: const TextStyle(
                                          fontFamily: "Cairo",
                                          fontSize: 11,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                      if (edited) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          'تم التعديل'.tr,
                                          style: const TextStyle(
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
                              () => _showAttachmentActions =
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
                        style: AppTextStyles.body,
                          decoration: InputDecoration(
                            hintText: "اكتب رسالة...".tr,
                            hintStyle: AppTextStyles.body,
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
                                  controller.sendTextMessage(
                                    widget.customerId!,
                                    msgCtrl.text,
                                    direct: true,
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
                    style: AppTextStyles.body.copyWith(color: Colors.red),
                  ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري التسجيل...'.tr,
                      style: AppTextStyles.body.copyWith(color: Colors.red),
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
                sending ? 'جاري رفع الفيديو...'.tr : 'فيديو'.tr,
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
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
    final radius = BorderRadius.circular(12);
    final hasLocal = localFilePath != null && localFilePath.isNotEmpty;
    final uploadsBase = ApiEndpoints.baseUrl.endsWith('/api')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 4)
        : ApiEndpoints.baseUrl;
    final resolvedRemote = url.startsWith('http')
        ? url
        : url.startsWith('file://') || url.contains(':\\')
            ? url
            : url.startsWith('/uploads')
                ? '$uploadsBase$url'
                : '${ApiEndpoints.baseUrl}$url';
    final resolvedFilePath = hasLocal
        ? (localFilePath.startsWith('file://')
            ? Uri.parse(localFilePath).path
            : localFilePath)
        : null;
    final displayUrl = resolvedFilePath ?? resolvedRemote;
    final playbackUrl =
        resolvedFilePath != null ? Uri.file(resolvedFilePath).toString() : resolvedRemote;
    final lower = (resolvedFilePath ?? url).toLowerCase();
    final isImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    final isVideo =
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv');
    final isAudio =
        isAudioType ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.wav');
    final stateLower = state.toLowerCase();
    final isUploading = stateLower == 'sending' || stateLower == 'retrying';
    final isDownloading = stateLower == 'downloading';
    final isFailed = stateLower == 'failed';
    final showDownloadAction = !fromMe &&
        stateLower == 'sent' &&
        !hasLocal &&
        !isUploading &&
        !isDownloading &&
        !isFailed;

    Widget progressOverlay(String label, double? value) {
      final v = value?.clamp(0.0, 1.0);
      final percent =
          v == null ? '--' : v.isNaN ? '--' : (v * 100).clamp(0, 100).toStringAsFixed(0);
      return Positioned.fill(
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$label ${percent == '--' ? '' : '$percent%'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onCancel != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: onCancel,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget failedOverlay() {
      if (onRetry == null) return const SizedBox.shrink();
      return Positioned.fill(
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text('إعادة المحاولة'.tr),
                ),
              ),
          ),
        ),
      );
    }

    Widget downloadOverlay() {
      if (onDownload == null) return const SizedBox.shrink();
      return Positioned(
        top: 8,
        right: 8,
        child: InkWell(
          onTap: onDownload,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.download, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    Widget buildImage() {
      final heroTag =
          heroSuffix == null ? 'image:$displayUrl' : 'image:$displayUrl#$heroSuffix';
      Widget imageWidget;
      if (resolvedFilePath != null) {
        imageWidget = Image.file(
          File(resolvedFilePath),
          width: 220,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => _brokenImagePlaceholder(),
        );
      } else if (displayUrl.startsWith('http')) {
        imageWidget = Image.network(
          displayUrl,
          width: 220,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => _brokenImagePlaceholder(),
        );
      } else {
        imageWidget = _brokenImagePlaceholder();
      }
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Get.to(
              () => ImageViewerPage(url: displayUrl, heroTag: heroTag),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
            ),
            child: Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: radius,
                child: imageWidget,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildVideo() {
      final heroTag =
          heroSuffix == null ? 'video:$displayUrl' : 'video:$displayUrl#$heroSuffix';
      final card = Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: radius,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Uint8List?>(
              future: _getVideoThumbnail(displayUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: Colors.black38,
                    ),
                  );
                }
                if (snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: radius,
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
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tr('فيديو', 'Video'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
          ],
        ),
      );
      return GestureDetector(
        onTap: () => Get.to(
          () => VideoViewerPage(
            url: displayUrl,
            title: _tr('فيديو', 'Video'),
            heroTag: heroTag,
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 200),
        ),
        child: Hero(tag: heroTag, child: card),
      );
    }

    Widget buildAudio() {
      final player = _playerFor(playbackUrl);
      final isPlaying = player.playing;
      final isLoading = _audioLoading.contains(playbackUrl);
      final pos = _audioPositions[playbackUrl] ?? Duration.zero;
      final total = _audioDurations[playbackUrl] ?? player.duration;
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _toggleAudio(playbackUrl),
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
                    isPlaying
                        ? _tr('تم التشغيل الآن', 'Playing now')
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
                            url: playbackUrl,
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
                            url: playbackUrl,
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
                                        (pos.inMilliseconds / 180) + (i * 0.6),
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
    }

    Widget base;
    if (isImage) {
      base = buildImage();
    } else if (isVideo) {
      base = buildVideo();
    } else if (isAudio) {
      base = buildAudio();
    } else {
      base = InkWell(
        onTap: () => _launchUrl(displayUrl),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: fromMe ? Colors.white24 : Colors.black12,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle, color: Colors.white70),
              const SizedBox(width: 8),
              Text('ملف'.tr, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        base,
        if (isUploading) progressOverlay(_tr('جاري الرفع', 'Uploading'), uploadProgress),
        if (isDownloading)
          progressOverlay(_tr('جاري التحميل', 'Downloading'), downloadProgress),
        if (isFailed) failedOverlay(),
        if (showDownloadAction) downloadOverlay(),
      ],
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
      final type = isVideo ? 'video' : 'image';
      final localId = widget.isDirect && widget.customerId != null
          ? controller.addPendingAttachment(
              type: type,
              placeholderAttachment:
                  'uploading://$type-${DateTime.now().microsecondsSinceEpoch}',
              customerId: widget.customerId,
              text: isVideo ? '[video]' : '[image]',
            )
          : controller.addPendingAttachment(
              type: type,
              placeholderAttachment:
                  'uploading://$type-${DateTime.now().microsecondsSinceEpoch}',
              requestId: widget.requestId,
              text: isVideo ? '[video]' : '[image]',
            );
      final file = File(picked.path);
      final size = await file.length();
      final limit = isVideo ? 20 * 1024 * 1024 : 3 * 1024 * 1024;
      if (size > limit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVideo
                  ? 'الفيديو أكبر من 20MB'.tr
                  : 'الصورة أكبر من 3MB'.tr,
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      final mime = isVideo ? 'video/mp4' : 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      if (widget.isDirect && widget.customerId != null) {
        await controller.sendDirectAttachment(
          widget.customerId!,
          dataUri: dataUri,
          mime: mime,
          localId: localId,
        );
      } else {
        await controller.sendRequestAttachment(
          widget.requestId,
          dataUri: dataUri,
          mime: mime,
          localId: localId,
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار الملف'.tr),
          backgroundColor: Colors.redAccent,
        ),
      );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('السماح بالمايك مطلوب للتسجيل'.tr),
                backgroundColor: Colors.redAccent,
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('السماح بالمايك مطلوب للتسجيل'.tr),
            backgroundColor: Colors.redAccent,
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'التسجيل غير متوفر الآن، جرّب إعادة تشغيل التطبيق أو اختر ملف صوتي.'
                .tr,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      await _pickAudioFile();
    } catch (_) {
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر بدء التسجيل'.tr),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الصوت أكبر من 5MB'.tr),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      final ext = path.split('.').last.toLowerCase();
      final mime = ext == 'wav'
          ? 'audio/wav'
          : ext == 'ogg'
          ? 'audio/ogg'
          : ext == 'aac' || ext == 'm4a'
          ? 'audio/aac'
          : 'audio/mpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      if (sendNow) {
        if (widget.isDirect && widget.customerId != null) {
          await controller.sendDirectAttachment(
            widget.customerId!,
            dataUri: dataUri,
            mime: mime,
          );
        } else {
          await controller.sendRequestAttachment(
            widget.requestId,
            dataUri: dataUri,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إيقاف/إرسال التسجيل'.tr),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        await player.setUrl(url);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تشغيل الصوت'.tr),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _brokenImagePlaceholder() {
    return Container(
      width: 220,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 36),
    );
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'aac', 'ogg', 'wav'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null) return;
      final audioFile = File(path);
      final size = await audioFile.length();
      if (size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الصوت أكبر من 5MB'.tr),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      final ext = (file.extension ?? 'mp3').toLowerCase();
      final mime = ext == 'wav'
          ? 'audio/wav'
          : ext == 'ogg'
          ? 'audio/ogg'
          : ext == 'aac' || ext == 'm4a'
          ? 'audio/aac'
          : 'audio/mpeg';
      final dataUri = path;
      if (widget.isDirect && widget.customerId != null) {
        await controller.sendDirectAttachment(
          widget.customerId!,
          dataUri: dataUri,
          mime: mime,
        );
      } else {
        await controller.sendRequestAttachment(
          widget.requestId,
          dataUri: dataUri,
          mime: mime,
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار الصوت'.tr),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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


