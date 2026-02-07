import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gallery_saver/gallery_saver.dart';

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
        setState(() => _bytes = Uint8List.fromList(resp.data ?? []));
      }
    } catch (_) {
      setState(() => _bytes = null);
    }
  }

  Future<void> _saveImage() async {
    if (_bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      final dir = await Directory.systemTemp.createTemp('usta_img');
      final path =
          '${dir.path}/usta_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(_bytes!);
      final success = await GallerySaver.saveImage(file.path) ?? false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم حفظ الصورة'.tr : 'تعذر حفظ الصورة'.tr,
            ),
            backgroundColor: success ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الصورة'.tr),
            backgroundColor: Colors.redAccent,
          ),
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
        ? InteractiveViewer(child: Image.memory(_bytes!, fit: BoxFit.contain))
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
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
