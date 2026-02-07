import 'package:get/get.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب'.tr;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح'.tr;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة'.tr;
    }
    if (value.trim().length < 6) {
      return 'كلمة المرور قصيرة جدًا (الحد الأدنى 6 أحرف)'.tr;
    }
    return null;
  }

  static String? strongPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة'.tr;
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف'.tr;
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$&*~.,;:<>?%^_-]').hasMatch(value);
    if (!hasUpper) {
      return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل'.tr;
    }
    if (!hasLower) {
      return 'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل'.tr;
    }
    if (!hasDigit) {
      return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل'.tr;
    }
    if (!hasSpecial) {
      return 'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل'.tr;
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب'.tr;
    }
    if (value.trim().length < 3) {
      return 'الاسم قصير جدًا'.tr;
    }
    return null;
  }
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب'.tr;
    }
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف غير صحيح'.tr;
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.trim().isEmpty) {
      return 'تأكيد كلمة المرور مطلوب'.tr;
    }
    if (value != original) {
      return 'كلمتا المرور غير متطابقتين'.tr;
    }
    return null;
  }
}
