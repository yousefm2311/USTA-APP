import 'package:flutter/material.dart';
import 'package:get/get.dart';


void pushRoute(Widget page, {dynamic arguments}) {
  Get.to(() => page, arguments: arguments);
}


void pushNamedRoute(
  String routeName, {
  dynamic arguments,
  Map<String, String>? parameters,
}) {
  Get.toNamed(routeName, arguments: arguments, parameters: parameters);
}

void pushReplacementRoute(Widget page, {dynamic arguments}) {
  Get.off(() => page, arguments: arguments);
}

void pushReplacementAllNamedRoute(
  String routeName, {
  dynamic arguments,
  Map<String, String>? parameters,
}) {
  Get.offAllNamed(routeName, arguments: arguments, parameters: parameters);
}

void pushReplacementNamedRoute(
  String routeName, {
  dynamic arguments,
  Map<String, String>? parameters,
}) {
  Get.offNamed(routeName, arguments: arguments, parameters: parameters);
}

void popRoute<T>([T? result]) {
  Get.back<T>(result: result);
}

void goRouteWithWidget(Widget page, {dynamic arguments}) {
  Get.offAll(() => page, arguments: arguments);
}