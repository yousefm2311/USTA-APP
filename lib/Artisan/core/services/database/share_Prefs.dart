

// ignore_for_file: file_names

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  // عمل Singleton instance للكلاس عشان تقدر تستخدمه من أي مكان بسهولة
  static final AppPrefs _instance = AppPrefs._internal();
  factory AppPrefs() => _instance;
  AppPrefs._internal();

  SharedPreferences? _prefs;

  /// تهيئة SharedPreferences مرة واحدة عند تشغيل التطبيق
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// حفظ String
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// حفظ رقم صحيح (int)
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// حفظ رقم عشري (double)
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// حفظ قيمة منطقية (bool)
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  /// قراءة String
  String? getString(String key) => _prefs?.getString(key);

  /// قراءة int
  int? getInt(String key) => _prefs?.getInt(key);

  /// قراءة double
  double? getDouble(String key) => _prefs?.getDouble(key);

  /// قراءة bool
  bool? getBool(String key) => _prefs?.getBool(key);

  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  /// حذف مفتاح محدد
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// مسح جميع البيانات
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  /// التحقق هل المفتاح موجود
  bool contains(String key) => _prefs?.containsKey(key) ?? false;

  /// جلب كل المفاتيح الحالية
  Set<String> getKeys() => _prefs?.getKeys() ?? {};

  /// قراءة أي نوع عام
  dynamic getValue(String key) => _prefs?.get(key);
}
