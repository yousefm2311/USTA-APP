import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';

class ImageViewerPage extends StatefulWidget {
  final String url;
  final String? heroTag;

  const ImageViewerPage({super.key, required this.url, this.heroTag});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  Uint8List? _bytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    final url = widget.url;
    try {
      if (url.startsWith('data:image')) {
        final base64Part = url.split(',').last;
        setState(() => _bytes = base64Decode(base64Part));
        return;
      }
      if (url.startsWith('http')) {
        final resp = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(resp.data ?? []);
        setState(() => _bytes = bytes);
      } else {
        final file = File(url.startsWith('file://') ? url.substring(7) : url);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          setState(() => _bytes = bytes);
        }
      }
    } catch (_) {
      setState(() => _bytes = null);
    }
  }

  Future<void> _saveImage() async {
    if (_bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      // Save to temp file then use GallerySaver to place in gallery.
      final dir = await Directory.systemTemp.createTemp('usta_img');
      final path = '${dir.path}/usta_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(_bytes!);
      final success = await GallerySaver.saveImage(file.path) ?? false;
      if (mounted) {
        AppSnackBar.show(
          success ? AppStrings.success.tr : AppStrings.error.tr,
          success
              ? AppStrings.imageSaveSuccess.tr
              : AppStrings.imageSaveFailed.tr,
          type: success ? SnackBarType.success : SnackBarType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          AppStrings.error.tr,
          AppStrings.imageSaveFailed.tr,
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.heroTag;
    final imageWidget = _bytes != null
        ? InteractiveViewer(
            child: Image.memory(_bytes!, fit: BoxFit.contain),
          )
        : const Center(child: CircularProgressIndicator(color: Colors.white));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveImage,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: heroTag != null && heroTag.isNotEmpty
            ? Hero(tag: heroTag, child: imageWidget)
            : imageWidget,
      ),
    );
  }
}

