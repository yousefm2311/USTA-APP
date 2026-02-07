import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/edit_profile_field.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/edit_profile_header_card.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerEditProfileView extends StatefulWidget {
  const CustomerEditProfileView({super.key});

  @override
  State<CustomerEditProfileView> createState() =>
      _CustomerEditProfileViewState();
}

class _CustomerEditProfileViewState extends State<CustomerEditProfileView> {
  final controller = Get.find<CustomerProfileController>();
  final formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool _photoUploading = false;

  late final TextEditingController nameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController addressCtrl;

  String? _photoUrl;
  String? _photoBase64;
  Color get blue => const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    final profile = controller.profile.value ?? {};

    nameCtrl = TextEditingController(text: (profile['name'] ?? '').toString());
    phoneCtrl = TextEditingController(
      text: (profile['phone'] ?? '').toString(),
    );
    emailCtrl = TextEditingController(
      text: (profile['email'] ?? '').toString(),
    );
    addressCtrl = TextEditingController(
      text: (profile['address'] ?? '').toString(),
    );
    final rawPhoto =
        profile['photo']?.toString() ??
        profile['photoUrl']?.toString() ??
        profile['avatar']?.toString();

    _photoUrl = _normalizePhotoUrl(rawPhoto);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }
  String? _normalizePhotoUrl(String? raw) {
    if (raw == null) return null;
    final p = raw.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final origin = AppConfig.instance.origin.trim();
    if (origin.isEmpty) return p;
    if (p.startsWith('/')) return '$origin$p';
    return '$origin/$p';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "تعديل بيانات الحساب".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EditProfileHeaderCard(
                imageProvider: _avatarProvider(),
                uploading: _photoUploading,
                onPick: _pickAndUpload,
                primaryColor: blue,
              ),
              const SizedBox(height: 16),

              EditProfileField(
                title: "الاسم".tr,
                controller: nameCtrl,
                validator: _required,
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                primaryColor: blue,
              ),
              EditProfileField(
                title: "رقم الجوال".tr,
                controller: phoneCtrl,
                validator: _required,
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                primaryColor: blue,
              ),
              EditProfileField(
                title: "البريد الإلكتروني".tr,
                controller: emailCtrl,
                validator: _emailValidator,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                primaryColor: blue,
              ),
              EditProfileField(
                title: "العنوان".tr,
                controller: addressCtrl,
                validator: _required,
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                primaryColor: blue,
              ),

              const SizedBox(height: 18),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (controller.saving.value || _photoUploading)
                        ? null
                        : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      controller.saving.value
                          ? 'جارٍ الحفظ...'.tr
                          : "حفظ التعديلات".tr,
                      style: const TextStyle(fontFamily: "Cairo", fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'ملاحظة: يمكنك تغيير صورتك بالضغط على الصورة بالأعلى.'.tr,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _avatarProvider() {
    if (_photoBase64 != null) {
      return MemoryImage(base64Decode(_photoBase64!));
    }
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
      return CachedNetworkImageProvider(_photoUrl!);
    }
    return null;
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب'.tr : null;

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'البريد الإلكتروني غير صحيح'.tr;
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final success = await controller.updateProfile(
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      address: addressCtrl.text.trim(),
    );

    if (success && mounted) Get.back();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);

      if (base64.length < 10) {
        AppSnackBar.show(
          'خطأ'.tr,
          'الصورة غير صالحة'.tr,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      setState(() {
        _photoBase64 = base64;
        _photoUrl = null;
        _photoUploading = true;
      });

      final ok = await controller.uploadPhoto(base64);

      if (ok && mounted) {
        await controller.refreshProfile(showLoader: false);
        final refreshed = controller.profile.value ?? {};
        final rawPhoto =
            refreshed['photo']?.toString() ??
            refreshed['photoUrl']?.toString() ??
            refreshed['avatar']?.toString();
        setState(() {
          _photoUrl = _normalizePhotoUrl(rawPhoto);
          _photoBase64 = null;
        });
      } else {
        AppSnackBar.show(
          'تنبيه'.tr,
          'لم يتم رفع الصورة، حاول مرة أخرى'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      AppSnackBar.show(
        'خطأ'.tr,
        'حدث خطأ أثناء اختيار/رفع الصورة'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }
}


