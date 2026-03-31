import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';

enum VerificationCaptureMode { document, selfie }

class ArtisanVerificationCameraView extends StatefulWidget {
  const ArtisanVerificationCameraView({
    super.key,
    required this.mode,
    this.screenTitle,
    this.screenHint,
    this.frameLabel,
  });

  final VerificationCaptureMode mode;
  final String? screenTitle;
  final String? screenHint;
  final String? frameLabel;

  @override
  State<ArtisanVerificationCameraView> createState() =>
      _ArtisanVerificationCameraViewState();
}

class _ArtisanVerificationCameraViewState
    extends State<ArtisanVerificationCameraView> {
  CameraController? _controller;
  XFile? _capturedFile;
  String? _errorMessage;
  bool _initializing = true;
  bool _capturing = false;
  bool _flashEnabled = false;
  Size? _lastPreviewSize;

  bool get _isSelfie => widget.mode == VerificationCaptureMode.selfie;
  String get _title =>
      widget.screenTitle ??
      (_isSelfie
          ? AppStrings.kycSelfieCaptureLabel.tr
          : AppStrings.kycIdFrontLabel.tr);
  String get _hint =>
      widget.screenHint ??
      (_isSelfie
          ? AppStrings.kycCameraFaceHint.tr
          : AppStrings.kycCameraPositionHint.tr);
  String get _frameLabel =>
      widget.frameLabel ??
      (_isSelfie
          ? AppStrings.kycSelfieCaptureLabel.tr
          : AppStrings.kycFrontSideShort.tr);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = AppStrings.kycCameraOpenFailed.tr;
          _initializing = false;
        });
        return;
      }

      final preferredLens = _isSelfie
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == preferredLens,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.kycCameraOpenFailed.tr;
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final processedFile = await _postProcessCapture(file);
      if (!mounted) return;
      setState(() => _capturedFile = processedFile);
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        AppStrings.error.tr,
        AppStrings.kycCameraOpenFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isSelfie) {
      return;
    }

    final next = !_flashEnabled;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    if (!mounted) return;
    setState(() => _flashEnabled = next);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _capturedFile != null
              ? _CapturedPreview(
                  file: _capturedFile!,
                  mode: widget.mode,
                  onRetake: () => setState(() => _capturedFile = null),
                  onConfirm: () => Get.back(result: _capturedFile),
                )
              : _buildCameraBody(context),
        ),
      ),
    );
  }

  Widget _buildCameraBody(BuildContext context) {
    final controller = _controller;

    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  _errorMessage ?? AppStrings.kycCameraOpenFailed.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back<XFile?>(result: null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(AppStrings.back.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastPreviewSize = Size(constraints.maxWidth, constraints.maxHeight);
        var scale =
            _lastPreviewSize!.aspectRatio * controller.value.aspectRatio;
        if (scale < 1) scale = 1 / scale;
        final guideFrame = _DocumentGuideFrame(
          mode: widget.mode,
          label: _frameLabel,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: Transform.scale(
                scale: scale,
                child: Center(child: CameraPreview(controller)),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CameraGuidePainter(mode: widget.mode),
              ),
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment(0, _isSelfie ? -0.18 : -0.14),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: guideFrame,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              left: 16,
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Get.back<XFile?>(result: null),
                  ),
                  const Spacer(),
                  if (!_isSelfie)
                    _GlassIconButton(
                      icon: _flashEnabled
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onPressed: _toggleFlash,
                    ),
                ],
              ),
            ),
            Positioned(
              top: 84,
              right: 20,
              left: 20,
              child: Column(
                children: [
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.38),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              left: 20,
              bottom: 28,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isSelfie
                                ? AppStrings.kycSelfieGuide.tr
                                : AppStrings.kycDocumentGuide.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _capturing ? null : _capture,
                    child: Container(
                      width: 82,
                      height: 82,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 4),
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _capturing ? Colors.white70 : Colors.white,
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.kycCapturePhoto.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<XFile> _postProcessCapture(XFile file) async {
    if (_isSelfie) return file;

    final previewSize = _lastPreviewSize;
    if (previewSize == null) return file;

    try {
      final originalBytes = await File(file.path).readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) return file;

      final normalized = img.bakeOrientation(decoded);
      final guideRect = _guideRectForSize(previewSize, widget.mode);
      final cropRect = _mapScreenRectToImageRect(
        screenSize: previewSize,
        imageSize: Size(
          normalized.width.toDouble(),
          normalized.height.toDouble(),
        ),
        screenRect: guideRect,
      );

      final cropped = img.copyCrop(
        normalized,
        x: cropRect.left.round(),
        y: cropRect.top.round(),
        width: cropRect.width.round(),
        height: cropRect.height.round(),
      );

      final outputPath = file.path.replaceFirst(
        RegExp(r'(\.[a-zA-Z0-9]+)$'),
        '-card-cropped.jpg',
      );
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(cropped, quality: 96));

      return XFile(
        outputFile.path,
        mimeType: 'image/jpeg',
        name: '${file.name}-card-cropped.jpg',
      );
    } catch (_) {
      return file;
    }
  }
}

Rect _guideRectForSize(Size size, VerificationCaptureMode mode) {
  if (mode == VerificationCaptureMode.selfie) {
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.58,
      height: size.width * 0.58,
    );
  }

  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height * 0.43),
    width: size.width * 0.82,
    height: size.width * 0.82 / 1.58,
  );
}

Rect _mapScreenRectToImageRect({
  required Size screenSize,
  required Size imageSize,
  required Rect screenRect,
}) {
  final imageAspect = imageSize.width / imageSize.height;
  final screenAspect = screenSize.width / screenSize.height;

  late final double displayedWidth;
  late final double displayedHeight;

  if (imageAspect > screenAspect) {
    displayedHeight = screenSize.height;
    displayedWidth = displayedHeight * imageAspect;
  } else {
    displayedWidth = screenSize.width;
    displayedHeight = displayedWidth / imageAspect;
  }

  final offsetX = (displayedWidth - screenSize.width) / 2;
  final offsetY = (displayedHeight - screenSize.height) / 2;

  final left = ((screenRect.left + offsetX) / displayedWidth) * imageSize.width;
  final top = ((screenRect.top + offsetY) / displayedHeight) * imageSize.height;
  final width = (screenRect.width / displayedWidth) * imageSize.width;
  final height = (screenRect.height / displayedHeight) * imageSize.height;

  final safeLeft = left.clamp(0.0, imageSize.width - 1);
  final safeTop = top.clamp(0.0, imageSize.height - 1);
  final safeWidth = width.clamp(1.0, imageSize.width - safeLeft);
  final safeHeight = height.clamp(1.0, imageSize.height - safeTop);

  return Rect.fromLTWH(safeLeft, safeTop, safeWidth, safeHeight);
}

class _CapturedPreview extends StatelessWidget {
  const _CapturedPreview({
    required this.file,
    required this.mode,
    required this.onRetake,
    required this.onConfirm,
  });

  final XFile file;
  final VerificationCaptureMode mode;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  bool get _isSelfie => mode == VerificationCaptureMode.selfie;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(file.path), fit: BoxFit.cover),
              Positioned.fill(
                child: CustomPaint(
                  painter: _CameraGuidePainter(
                    mode: mode,
                    dimBackground: false,
                  ),
                ),
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment(0, _isSelfie ? -0.18 : -0.14),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _DocumentGuideFrame(
                      mode: mode,
                      label: _isSelfie
                          ? AppStrings.kycPreviewSelfie.tr
                          : AppStrings.kycPreviewDocument.tr,
                      previewMode: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: _GlassIconButton(
                  icon: Icons.close_rounded,
                  onPressed: () => Get.back<XFile?>(result: null),
                ),
              ),
            ],
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
              Text(
                _isSelfie
                    ? AppStrings.kycPreviewSelfie.tr
                    : AppStrings.kycPreviewDocument.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSelfie
                    ? AppStrings.kycSelfieGuide.tr
                    : AppStrings.kycDocumentGuide.tr,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(AppStrings.kycRetakePhoto.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(AppStrings.kycUseThisPhoto.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentGuideFrame extends StatelessWidget {
  const _DocumentGuideFrame({
    required this.mode,
    required this.label,
    this.previewMode = false,
  });

  final VerificationCaptureMode mode;
  final String label;
  final bool previewMode;

  bool get _isSelfie => mode == VerificationCaptureMode.selfie;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final width = _isSelfie ? media.width * 0.56 : media.width * 0.82;
    final height = _isSelfie ? width : width / 1.58;
    final borderColor = previewMode ? Colors.white : const Color(0xFFF8FAFC);
    final accentColor = previewMode
        ? Colors.white.withOpacity(0.85)
        : const Color(0xFF60A5FA);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isSelfie)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(previewMode ? 0.34 : 0.44),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: _isSelfie ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: _isSelfie ? null : BorderRadius.circular(26),
                border: Border.all(color: borderColor, width: 2.6),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(previewMode ? 0.04 : 0.02),
                    Colors.white.withOpacity(previewMode ? 0.02 : 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(previewMode ? 0.12 : 0.08),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: _isSelfie
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          2,
                          (_) => Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                      ),
                    ),
            ),
            if (!_isSelfie) ...[
              _FrameCorner(
                top: -1,
                right: -1,
                rotationQuarterTurns: 0,
                color: accentColor,
              ),
              _FrameCorner(
                top: -1,
                left: -1,
                rotationQuarterTurns: 1,
                color: accentColor,
              ),
              _FrameCorner(
                bottom: -1,
                left: -1,
                rotationQuarterTurns: 2,
                color: accentColor,
              ),
              _FrameCorner(
                bottom: -1,
                right: -1,
                rotationQuarterTurns: 3,
                color: accentColor,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.rotationQuarterTurns,
    required this.color,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final int rotationQuarterTurns;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: RotatedBox(
        quarterTurns: rotationQuarterTurns,
        child: SizedBox(
          width: 34,
          height: 34,
          child: CustomPaint(painter: _CornerPainter(color)),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width, 12)
      ..lineTo(size.width, 0)
      ..lineTo(12, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.color != color;
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

class _CameraGuidePainter extends CustomPainter {
  _CameraGuidePainter({required this.mode, this.dimBackground = true});

  final VerificationCaptureMode mode;
  final bool dimBackground;

  bool get _isSelfie => mode == VerificationCaptureMode.selfie;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = dimBackground
          ? Colors.black.withOpacity(0.52)
          : Colors.transparent;

    final path = Path()..addRect(Offset.zero & size);
    final cutoutRect = _guideRectForSize(size, mode);

    final cutoutPath = Path()
      ..addRRect(
        _isSelfie
            ? RRect.fromRectAndRadius(
                cutoutRect,
                Radius.circular(cutoutRect.width / 2),
              )
            : RRect.fromRectAndRadius(cutoutRect, const Radius.circular(26)),
      );

    if (dimBackground) {
      final difference = Path.combine(
        PathOperation.difference,
        path,
        cutoutPath,
      );
      canvas.drawPath(difference, overlayPaint);
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final accentPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (_isSelfie) {
      canvas.drawOval(cutoutRect, borderPaint);
      return;
    }

    final rrect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(26),
    );
    canvas.drawRRect(rrect, borderPaint);

    const corner = 28.0;
    final left = cutoutRect.left;
    final right = cutoutRect.right;
    final top = cutoutRect.top;
    final bottom = cutoutRect.bottom;

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
  bool shouldRepaint(covariant _CameraGuidePainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.dimBackground != dimBackground;
  }
}
