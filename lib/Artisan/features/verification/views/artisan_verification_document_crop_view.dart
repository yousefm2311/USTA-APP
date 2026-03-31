import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';

class ArtisanVerificationDocumentCropView extends StatefulWidget {
  const ArtisanVerificationDocumentCropView({
    super.key,
    required this.file,
    this.screenTitle,
    this.screenHint,
    this.frameLabel,
  });

  final XFile file;
  final String? screenTitle;
  final String? screenHint;
  final String? frameLabel;

  @override
  State<ArtisanVerificationDocumentCropView> createState() =>
      _ArtisanVerificationDocumentCropViewState();
}

class _ArtisanVerificationDocumentCropViewState
    extends State<ArtisanVerificationDocumentCropView> {
  final TransformationController _transformationController =
      TransformationController();

  img.Image? _decodedImage;
  Uint8List? _previewBytes;
  Size? _imageSize;
  Size? _viewportSize;
  bool _loading = true;
  bool _saving = false;

  String get _title => widget.screenTitle ?? AppStrings.kycPreviewDocument.tr;
  String get _hint => widget.screenHint ?? AppStrings.kycAdjustDocumentCrop.tr;
  String get _frameLabel =>
      widget.frameLabel ?? AppStrings.kycFrontSideShort.tr;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
    _loadImage();
  }

  @override
  void dispose() {
    _transformationController
      ..removeListener(_handleTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FormatException('Unable to decode image');
      }

      final normalized = img.bakeOrientation(decoded);
      final normalizedBytes = Uint8List.fromList(
        img.encodeJpg(normalized, quality: 98),
      );

      if (!mounted) return;
      setState(() {
        _decodedImage = normalized;
        _previewBytes = normalizedBytes;
        _imageSize = Size(
          normalized.width.toDouble(),
          normalized.height.toDouble(),
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        AppStrings.error.tr,
        AppStrings.filePickFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back<XFile?>(result: null);
    }
  }

  void _syncInitialTransform(Size viewportSize) {
    if (_imageSize == null) return;
    if (_viewportSize == viewportSize) return;

    _viewportSize = viewportSize;
    final scale = math.min(
      viewportSize.width / _imageSize!.width,
      viewportSize.height / _imageSize!.height,
    );
    final dx = (viewportSize.width - _imageSize!.width * scale) / 2;
    final dy = (viewportSize.height - _imageSize!.height * scale) / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewportSize != viewportSize) return;
      _transformationController.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(scale);
    });
  }

  Rect _guideRectForSize(Size size) {
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.43),
      width: size.width * 0.82,
      height: size.width * 0.82 / 1.58,
    );
  }

  Rect _imageRectOnScreen() {
    final imageSize = _imageSize;
    if (imageSize == null) return Rect.zero;

    final matrix = _transformationController.value;
    final topLeft = MatrixUtils.transformPoint(matrix, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      matrix,
      Offset(imageSize.width, imageSize.height),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  bool _isGuideCovered(Size viewportSize) {
    final imageRect = _imageRectOnScreen();
    if (imageRect.isEmpty) return false;
    final guideRect = _guideRectForSize(viewportSize);
    return imageRect.left <= guideRect.left &&
        imageRect.top <= guideRect.top &&
        imageRect.right >= guideRect.right &&
        imageRect.bottom >= guideRect.bottom;
  }

  Rect _mapGuideToImageRect(Size viewportSize) {
    final imageSize = _imageSize!;
    final guideRect = _guideRectForSize(viewportSize);
    final inverseMatrix = Matrix4.inverted(_transformationController.value);

    final topLeft = MatrixUtils.transformPoint(
      inverseMatrix,
      guideRect.topLeft,
    );
    final bottomRight = MatrixUtils.transformPoint(
      inverseMatrix,
      guideRect.bottomRight,
    );
    final rawRect = Rect.fromPoints(topLeft, bottomRight);

    final safeLeft = rawRect.left.clamp(0.0, imageSize.width - 1.0);
    final safeTop = rawRect.top.clamp(0.0, imageSize.height - 1.0);
    final safeRight = rawRect.right.clamp(safeLeft + 1.0, imageSize.width);
    final safeBottom = rawRect.bottom.clamp(safeTop + 1.0, imageSize.height);

    return Rect.fromLTRB(safeLeft, safeTop, safeRight, safeBottom);
  }

  Future<void> _confirmCrop() async {
    final decodedImage = _decodedImage;
    final viewportSize = _viewportSize;
    if (decodedImage == null || viewportSize == null) return;
    if (!_isGuideCovered(viewportSize) || _saving) return;

    setState(() => _saving = true);
    try {
      final cropRect = _mapGuideToImageRect(viewportSize);
      final cropped = img.copyCrop(
        decodedImage,
        x: cropRect.left.round(),
        y: cropRect.top.round(),
        width: cropRect.width.round(),
        height: cropRect.height.round(),
      );

      final outputPath =
          '${Directory.systemTemp.path}/kyc-document-crop-${DateTime.now().microsecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(
        img.encodeJpg(cropped, quality: 96),
        flush: true,
      );

      if (!mounted) return;
      Get.back(
        result: XFile(
          outputFile.path,
          mimeType: 'image/jpeg',
          name: 'kyc-document-crop.jpg',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        AppStrings.error.tr,
        AppStrings.filePickFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.close_rounded,
                      onPressed: () => Get.back<XFile?>(result: null),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _hint,
                            style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          _syncInitialTransform(viewportSize);
                          final isReady = _isGuideCovered(viewportSize);
                          final guideRect = _guideRectForSize(viewportSize);

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRect(
                                  child: InteractiveViewer(
                                    transformationController:
                                        _transformationController,
                                    boundaryMargin: const EdgeInsets.all(180),
                                    minScale: 0.05,
                                    maxScale: 6,
                                    clipBehavior: Clip.none,
                                    child: SizedBox(
                                      width: _imageSize!.width,
                                      height: _imageSize!.height,
                                      child: Image.memory(
                                        _previewBytes!,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _DocumentCropGuidePainter(
                                    guideRect: guideRect,
                                    isReady: isReady,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 18,
                                left: 18,
                                right: 18,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isReady
                                          ? const Color(0xFF052E16)
                                          : Colors.black.withOpacity(0.42),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isReady
                                            ? const Color(0xFF22C55E)
                                            : Colors.white24,
                                      ),
                                    ),
                                    child: Text(
                                      isReady
                                          ? AppStrings.kycCropCoverageReady.tr
                                          : AppStrings.kycAdjustDocumentCrop.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isReady
                                            ? const Color(0xFFBBF7D0)
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: guideRect.top - 42,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Text(
                                      _frameLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.crop_free_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.kycAdjustDocumentCrop.tr,
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Get.back<XFile?>(result: null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(AppStrings.cancel.tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _confirmCrop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Text(AppStrings.kycUseThisPhoto.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCropGuidePainter extends CustomPainter {
  const _DocumentCropGuidePainter({
    required this.guideRect,
    required this.isReady,
  });

  final Rect guideRect;
  final bool isReady;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final guidePath = Path()
      ..addRRect(RRect.fromRectAndRadius(guideRect, const Radius.circular(26)));

    final dimmed = Path.combine(
      PathOperation.difference,
      overlayPath,
      guidePath,
    );

    canvas.drawPath(dimmed, Paint()..color = Colors.black.withOpacity(0.58));

    final borderColor = isReady ? const Color(0xFF22C55E) : Colors.white;
    final accentColor = isReady
        ? const Color(0xFF4ADE80)
        : const Color(0xFF60A5FA);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(guideRect, const Radius.circular(26)),
      borderPaint,
    );

    const corner = 30.0;
    final left = guideRect.left;
    final right = guideRect.right;
    final top = guideRect.top;
    final bottom = guideRect.bottom;

    canvas.drawLine(Offset(left, top + corner), Offset(left, top), accentPaint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), accentPaint);

    canvas.drawLine(
      Offset(right - corner, top),
      Offset(right, top),
      accentPaint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + corner),
      accentPaint,
    );

    canvas.drawLine(
      Offset(left, bottom - corner),
      Offset(left, bottom),
      accentPaint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + corner, bottom),
      accentPaint,
    );

    canvas.drawLine(
      Offset(right - corner, bottom),
      Offset(right, bottom),
      accentPaint,
    );
    canvas.drawLine(
      Offset(right, bottom - corner),
      Offset(right, bottom),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DocumentCropGuidePainter oldDelegate) {
    return oldDelegate.guideRect != guideRect || oldDelegate.isReady != isReady;
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
