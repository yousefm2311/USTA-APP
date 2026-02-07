import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/portfolio/controllers/portfolio_controller.dart';
import 'package:usta/Artisan/features/artisan/services/controllers/services_controller.dart';

class ArtisanAddPortfolioView extends StatefulWidget {
  const ArtisanAddPortfolioView({super.key});

  @override
  State<ArtisanAddPortfolioView> createState() =>
      _ArtisanAddPortfolioViewState();
}

class _ArtisanAddPortfolioViewState extends State<ArtisanAddPortfolioView> {
  Color get primaryBlue => const Color(0xFF2563EB);
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final List<XFile> images = [];
  final picker = ImagePicker();
  final TextEditingController descCtrl = TextEditingController();
  String? selectedService;

  final PortfolioController portfolioController =
      Get.find<PortfolioController>();
  final ServicesController servicesController = Get.find<ServicesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      portfolioController.loadFromProfile();
      servicesController.loadFromProfile();
    });
  }

  @override
  void dispose() {
    descCtrl.dispose();
    super.dispose();
  }

  int get _maxItems => PortfolioController.maxItems;

  int _remaining(int existingCount) {
    final remaining = _maxItems - existingCount - images.length;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _pickFromGallery() async {
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final existing = portfolioController.items.length;
    final remaining = _remaining(existing);

    if (remaining <= 0) {
      _showLimitSnack();
      return;
    }

    final allowed = <XFile>[];
    for (final file in picked) {
      if (allowed.length >= remaining) break;
      final validated = await _validateImage(file);
      if (validated != null) allowed.add(validated);
    }
    if (allowed.isEmpty) {
      _showLimitSnack();
      return;
    }

    setState(() => images.addAll(allowed));

    if (allowed.length < picked.length) {
      _showLimitSnack();
    }
  }

  Future<void> _pickFromCamera() async {
    final existing = portfolioController.items.length;
    final remaining = _remaining(existing);

    if (remaining <= 0) {
      _showLimitSnack();
      return;
    }

    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    final validated = await _validateImage(picked);
    if (validated == null) return;
    setState(() => images.add(validated));
  }

  Future<XFile?> _validateImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showSnack(AppStrings.portfolioEmptyImage.tr, color: Colors.redAccent);
        return null;
      }
      if (bytes.length > _maxImageBytes) {
        _showSnack(AppStrings.portfolioImageTooLarge.tr, color: Colors.redAccent);
        return null;
      }
      return await _persistImage(file, bytes);
    } catch (_) {
      _showSnack(AppStrings.portfolioReadImageFailed.tr, color: Colors.redAccent);
      return null;
    }
  }

  Future<XFile> _persistImage(XFile file, List<int> bytes) async {
    final ext = _extensionFrom(file);
    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/portfolio_${DateTime.now().microsecondsSinceEpoch}$ext';
    final outFile = File(path);
    await outFile.writeAsBytes(bytes, flush: true);
    return XFile(outFile.path, mimeType: file.mimeType, name: file.name);
  }

  String _extensionFrom(XFile file) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return name.substring(dot);
    }
    final mime = file.mimeType ?? '';
    if (mime.contains('png')) return '.png';
    if (mime.contains('webp')) return '.webp';
    return '.jpg';
  }

  void _openPickSheet() {
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
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'اختيار الصور',
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _sheetItem(
                  icon: Icons.photo_library_outlined,
                  title: 'من الاستوديو (أكثر من صورة)',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                ),
                const SizedBox(height: 10),
                _sheetItem(
                  icon: Icons.photo_camera_outlined,
                  title: 'من الكاميرا (صورة واحدة)',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(
            scheme.brightness == Brightness.dark ? 0.28 : 0.6,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: primaryBlue.withOpacity(0.25)),
              ),
              child: Icon(icon, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body(context).copyWith(fontSize: 14),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: scheme.onSurface.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitSnack() {
    AppSnackBar.show(
      AppStrings.warning.tr,
      AppStrings.portfolioLimitReached.trParams({'count': '$_maxItems'}),
      type: SnackBarType.warning,
    );
  }

  void _showSnack(String msg, {Color? color}) {
    final type =
        color == Colors.redAccent ? SnackBarType.error : SnackBarType.info;
    AppSnackBar.show(
      type == SnackBarType.error ? AppStrings.error.tr : AppStrings.info.tr,
      msg,
      type: type,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (images.isEmpty) {
      _showSnack(
        AppStrings.portfolioSelectAtLeastOne.tr,
        color: Colors.redAccent,
      );
      return;
    }

    final before = portfolioController.items.length;

    // لو عندك API بيدعم ربط البورتفوليو بخدمة:
    // عدّل controller.addPortfolios بحيث يستقبل serviceName (اختياري)
    // وابعته هنا.
    await portfolioController.addPortfolios(
      files: images,
      description: descCtrl.text.trim(),
      // serviceName: selectedService, // ✅ فعّلها لو الcontroller بيدعمها
    );

    final after = portfolioController.items.length;
    if (!mounted) return;

    if (after > before) {
      setState(() => images.clear());
      descCtrl.clear();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.quickActionsPortfolio.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(AppStrings.carphoto.tr),
            const SizedBox(height: 10),
            Obx(
              () => _imagesPicker(
                existingCount: portfolioController.items.length,
              ),
            ),
            const SizedBox(height: 22),

            _label(AppStrings.quickActionsServices.tr),
            const SizedBox(height: 8),
            _serviceDropdown(),
            const SizedBox(height: 22),

            _label(AppStrings.description.tr),
            const SizedBox(height: 8),
            _descField(),
            const SizedBox(height: 26),

            Obx(() {
              final isSaving = portfolioController.saving.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppStrings.save.tr,
                          style: const TextStyle(
                            fontFamily: "Cairo",
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),

            const SizedBox(height: 10),
            Text(
              'الحد الأقصى: $_maxItems صور',
              style: AppTextStyles.body(context).copyWith(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String txt) {
    return Text(
      txt,
      style: AppTextStyles.body(context).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _imagesPicker({required int existingCount}) {
    final scheme = Theme.of(context).colorScheme;
    final totalSelected = existingCount + images.length;
    final canAddMore = totalSelected < _maxItems;

    if (images.isEmpty) {
      return InkWell(
        onTap: canAddMore ? _openPickSheet : _showLimitSnack,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'اضغط لإضافة صور',
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 14,
                    color: scheme.onSurface.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outline.withOpacity(0.15)),
                ),
                child: Text(
                  '$totalSelected/$_maxItems',
                  style: AppTextStyles.body(context).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          itemCount: images.length + (canAddMore ? 1 : 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) {
            if (canAddMore && i == images.length) {
              return InkWell(
                onTap: _openPickSheet,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outline.withOpacity(0.18)),
                  ),
                  child: Center(
                    child: Icon(Icons.add, color: primaryBlue, size: 30),
                  ),
                ),
              );
            }

            final file = images[i];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(file.path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _filePlaceholder(scheme.onSurface),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => setState(() => images.removeAt(i)),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: scheme.outline.withOpacity(0.15)),
              ),
              child: Text(
                '$totalSelected/$_maxItems',
                style: AppTextStyles.body(context).copyWith(fontSize: 12),
              ),
            ),
            const Spacer(),
            if (!canAddMore)
              Text(
                'وصلت للحد الأقصى',
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 12,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _filePlaceholder(Color color) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: color.withOpacity(0.5),
          size: 28,
        ),
      ),
    );
  }

  Widget _serviceDropdown() {
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final services = servicesController.serviceNames;

      if (services.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orangeAccent.withOpacity(0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'مفيش خدمات مضافة عندك… ضيف خدمة الأول عشان تربطها بالعمل (اختياري).',
                  style: AppTextStyles.body(context).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withOpacity(0.15)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            dropdownColor: scheme.surface,
            value: selectedService,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: scheme.onSurface.withOpacity(0.7),
            ),
            hint: Text(
              'اختر خدمة (اختياري)',
              style: AppTextStyles.body(context).copyWith(fontSize: 14),
            ),
            items: services
                .map(
                  (srv) => DropdownMenuItem(
                    value: srv,
                    child: Text(
                      srv,
                      style: AppTextStyles.body(context).copyWith(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedService = val),
          ),
        ),
      );
    });
  }

  Widget _descField() {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: descCtrl,
      maxLines: 4,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        hintText: AppStrings.description.tr,
        hintStyle: AppTextStyles.body(context).copyWith(
          color: scheme.onSurface.withOpacity(0.45),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

