

// ignore_for_file: file_names

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static final AppPrefs _instance = AppPrefs._internal();
  factory AppPrefs() => _instance;
  AppPrefs._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  String? getString(String key) => _prefs?.getString(key);

  int? getInt(String key) => _prefs?.getInt(key);

  double? getDouble(String key) => _prefs?.getDouble(key);

  bool? getBool(String key) => _prefs?.getBool(key);

  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  bool contains(String key) => _prefs?.containsKey(key) ?? false;

  Set<String> getKeys() => _prefs?.getKeys() ?? {};

  dynamic getValue(String key) => _prefs?.get(key);
}
