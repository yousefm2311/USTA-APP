class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.trim().length < 6) {
      return 'كلمة المرور قصيرة جدًا (الحد الأدنى 6 أحرف)';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$&*~.,;:<>?%^_-]').hasMatch(value);
    if (!hasUpper) {
      return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
    }
    if (!hasLower) {
      return 'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل';
    }
    if (!hasDigit) return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
    if (!hasSpecial) {
      return 'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 3) {
      return 'الاسم قصير جدًا';
    }
    return null;
  }
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.trim().isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != original) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }
}
