// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// 🧠 كلاس مساعد للوصول السريع لكل قيم MediaQuery
class AppMediaQuery {
  final BuildContext context;
  AppMediaQuery._(this.context);

  /// طريقة الاستدعاء السهلة:
  static AppMediaQuery of(BuildContext context) => AppMediaQuery._(context);

  /// 📏 حجم الشاشة الكامل
  Size get size => MediaQuery.of(context).size;

  /// 🔹 العرض
  double get width => size.width;

  /// 🔹 الارتفاع
  double get height => size.height;

  /// 🔸 نسبة الطول إلى العرض
  double get aspectRatio => size.aspectRatio;

  /// 🧭 الاتجاه (أفقي / رأسي)
  Orientation get orientation => MediaQuery.of(context).orientation;

  /// 📱 هل الوضع أفقي؟
  bool get isLandscape => orientation == Orientation.landscape;

  /// 📱 هل الوضع رأسي؟
  bool get isPortrait => orientation == Orientation.portrait;

  /// 🧩 هل الجهاز موبايل أو تابلت بناءً على العرض
  bool get isTablet => width > 600;
  bool get isMobile => width <= 600;

  /// 🧱 قيم SafeArea (زي النوتش أو البار العلوي)
  double get topPadding => MediaQuery.of(context).padding.top;
  double get bottomPadding => MediaQuery.of(context).padding.bottom;
  double get leftPadding => MediaQuery.of(context).padding.left;
  double get rightPadding => MediaQuery.of(context).padding.right;

  /// 📐 نسب ديناميكية (زي CSS %)
  double heightPercent(double percent) => height * (percent / 100);
  double widthPercent(double percent) => width * (percent / 100);

  /// 🔤 حجم الخط النسبي حسب الشاشة
  double scaleText(double baseSize) => baseSize * (width / 400);

  /// 🔄 نسبة الأمان (يستخدم لتعديل القيم تلقائيًا)
  EdgeInsets get safeInsets => MediaQuery.of(context).padding;

  /// 🖐 عدد الـ pixels في كل بوصة (لكياسات دقيقة)
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  /// 📶 إمكانية الوصول (مثلاً لو المستخدم مكبر الخط)
  double get textScaleFactor => MediaQuery.of(context).textScaleFactor;
}
