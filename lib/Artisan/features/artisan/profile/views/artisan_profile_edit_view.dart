import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';

class ArtisanProfileEditView extends StatefulWidget {
  const ArtisanProfileEditView({super.key});

  @override
  State<ArtisanProfileEditView> createState() => _ArtisanProfileEditViewState();
}

class _ArtisanProfileEditViewState extends State<ArtisanProfileEditView> {
  final ProfileController controller = Get.find<ProfileController>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController nameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController professionCtrl;
  late final TextEditingController addressCtrl;
  late final TextEditingController descriptionCtrl;
  Uint8List? _avatarBytes;
  String? _avatarBase64;
  bool _pickingAvatar = false;

  @override
  void initState() {
    super.initState();
    final data = controller.profile;

    nameCtrl = TextEditingController(text: (data['name'] ?? '').toString());
    phoneCtrl = TextEditingController(text: (data['phone'] ?? '').toString());
    professionCtrl = TextEditingController(
      text: (data['profession'] ?? '').toString(),
    );
    addressCtrl = TextEditingController(
      text: (data['address'] ?? '').toString(),
    );
    descriptionCtrl = TextEditingController(
      text: (data['description'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    professionCtrl.dispose();
    addressCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar) return;
    setState(() => _pickingAvatar = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final mime = picked.mimeType ?? 'image/jpeg';
      final base64Image = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() {
        _avatarBytes = bytes;
        _avatarBase64 = base64Image;
      });
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _save() async {
    await controller.updateProfile({
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'profession': professionCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'description': descriptionCtrl.text.trim(),
      if (_avatarBase64 != null) 'avatar': _avatarBase64,
    });
    if (mounted) Get.back();
  }

  InputDecoration _decoration(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body(context).copyWith(
        color: scheme.onSurface.withOpacity(0.7),
      ),
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.primary.withOpacity(0.9),
          width: 1.4,
        ),
      ),
    );
  }

  String _resolveAnyUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;

    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;

    final baseNoApi = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;

    if (raw.startsWith('/uploads')) return '$baseNoApi$raw';
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/$raw';
  }

  Widget _profilePhotoSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = controller.profile;
    final avatarRaw = (data['avatar'] ?? '').toString();
    final avatarUrl = _resolveAnyUrl(avatarRaw);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withOpacity(0.12),
              border: Border.all(color: scheme.primary.withOpacity(0.2)),
            ),
            child: ClipOval(
              child: _avatarBytes != null
                  ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                  : avatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: scheme.primary,
                          size: 34,
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: scheme.primary,
                            size: 34,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.profilephoto.tr,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.edit.tr,
                  style: AppTextStyles.caption(context).copyWith(
                    color: scheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickingAvatar ? null : _pickAvatar,
            icon: _pickingAvatar
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo, size: 18),
            label: Text(AppStrings.add.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppStrings.edit.tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ✅ زر ثابت تحت
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Obx(() {
              final loading = controller.updating.value;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),

        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            _profilePhotoSection(context),
            const SizedBox(height: 14),

            // ✅ Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outline.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.edit_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.edit.tr,
                          style: const TextStyle(
                            fontFamily: "Cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "عدّل بياناتك الأساسية واحفظ التغييرات",
                          style: AppTextStyles.caption(context).copyWith(
                            color: scheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.body(context),
              decoration: _decoration(context, AppStrings.name.tr),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.body(context),
              decoration: _decoration(context, AppStrings.phone.tr),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: professionCtrl,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.body(context),
              decoration: _decoration(context, AppStrings.profession.tr),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: addressCtrl,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.body(context),
              decoration: _decoration(context, AppStrings.address.tr),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descriptionCtrl,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: AppTextStyles.body(context),
              decoration: _decoration(context, AppStrings.about.tr),
            ),

            const SizedBox(height: 90), // مساحة عشان زر الحفظ ما يغطيش آخر حقل
          ],
        ),
      ),
    );
  }
}

