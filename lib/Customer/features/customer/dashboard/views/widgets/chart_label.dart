import 'package:get/get.dart';

List<String> chartLabels(int length, List<String> provided) {
  if (length == 0) return const [];
  if (provided.isNotEmpty && provided.length == length) return provided;

  final base = [
    'يناير'.tr,
    'فبراير'.tr,
    'مارس'.tr,
    'أبريل'.tr,
    'مايو'.tr,
    'يونيو'.tr,
    'يوليو'.tr,
    'أغسطس'.tr,
    'سبتمبر'.tr,
    'أكتوبر'.tr,
    'نوفمبر'.tr,
    'ديسمبر'.tr,
  ];

  return List.generate(
    length,
    (i) => i < base.length
        ? base[i]
        : 'م@num'.trParams({'num': (i + 1).toString()}),
  );
}
