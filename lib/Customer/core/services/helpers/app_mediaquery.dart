// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppMediaQuery {
  final BuildContext context;
  AppMediaQuery._(this.context);
  static AppMediaQuery of(BuildContext context) => AppMediaQuery._(context);
  Size get size => MediaQuery.of(context).size;

  double get width => size.width;

  double get height => size.height;

  double get aspectRatio => size.aspectRatio;

  Orientation get orientation => MediaQuery.of(context).orientation;

  bool get isLandscape => orientation == Orientation.landscape;

  bool get isPortrait => orientation == Orientation.portrait;

  bool get isTablet => width > 600;
  bool get isMobile => width <= 600;

  double get topPadding => MediaQuery.of(context).padding.top;
  double get bottomPadding => MediaQuery.of(context).padding.bottom;
  double get leftPadding => MediaQuery.of(context).padding.left;
  double get rightPadding => MediaQuery.of(context).padding.right;

  double heightPercent(double percent) => height * (percent / 100);
  double widthPercent(double percent) => width * (percent / 100);

  double scaleText(double baseSize) => baseSize * (width / 400);

  EdgeInsets get safeInsets => MediaQuery.of(context).padding;

  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  double get textScaleFactor => MediaQuery.of(context).textScaleFactor;
}
