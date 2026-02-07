import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/widgets/create_request_field.dart';

class CreateRequestServiceSelector extends StatelessWidget {
  const CreateRequestServiceSelector({
    super.key,
    required this.controller,
    required this.serviceCtrl,
    required this.selectedService,
    required this.onChanged,
  });

  final CustomerRequestsController controller;
  final TextEditingController serviceCtrl;
  final String? selectedService;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.serviceTypes;
      final hasList = list.isNotEmpty;
      String? dropdownValue = selectedService;
      if (dropdownValue != null &&
          dropdownValue != '__custom__' &&
          !list.contains(dropdownValue)) {
        dropdownValue = null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasList)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonFormField<String>(
                value: dropdownValue,
                dropdownColor: Theme.of(context).colorScheme.surface,
                focusColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  counterStyle: TextStyle(
                    fontFamily: "Cairo",
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  border: InputBorder.none,
                  labelText: 'نوع الخدمة'.tr,
                  labelStyle: const TextStyle(fontFamily: "Cairo"),
                ),
                style: TextStyle(
                  fontFamily: "Cairo",
                  color: Get.isDarkMode ? Colors.white : Colors.black,
                ),
                items: [
                  ...list.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.tr,
                        style: const TextStyle(fontFamily: "Cairo"),
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '__custom__',
                    child: Text(
                      'أخرى (اكتب يدويًا)'.tr,
                      style: const TextStyle(fontFamily: "Cairo"),
                    ),
                  ),
                ],
                onChanged: onChanged,
                validator: (_) => serviceCtrl.text.trim().isNotEmpty
                    ? null
                    : 'نوع الخدمة مطلوب'.tr,
              ),
            ),
          if (!hasList ||
              selectedService == '__custom__' ||
              selectedService == null)
            Padding(
              padding: EdgeInsets.only(top: hasList ? 10 : 0),
              child: CreateRequestField(
                controller: serviceCtrl,
                label: hasList ? 'نوع الخدمة (يدوي)' : 'نوع الخدمة',
                hint: 'سباكة / كهرباء ...',
                validator: (value) => value != null && value.trim().isNotEmpty
                    ? null
                    : 'نوع الخدمة مطلوب'.tr,
              ),
            ),
        ],
      );
    });
  }
}

