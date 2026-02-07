import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/complaints/controllers/customer_complaints_controller.dart';
import 'package:usta/Customer/features/customer/complaints/views/widgets/info_card_detail_view.dart';
import 'package:usta/Customer/features/customer/complaints/views/widgets/input_area_details_view.dart';
import 'package:usta/Customer/features/customer/complaints/views/widgets/message_bubble_details_view.dart';

class CustomerComplaintDetailView extends StatefulWidget {
  const CustomerComplaintDetailView({super.key, required this.complaintId});

  final String complaintId;

  @override
  State<CustomerComplaintDetailView> createState() =>
      _CustomerComplaintDetailViewState();
}

class _CustomerComplaintDetailViewState
    extends State<CustomerComplaintDetailView> {
  final controller = Get.find<CustomerComplaintsController>();
  final msgCtrl = TextEditingController();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    controller.selected.value = null;
    controller.messages.clear();
    controller.fetchComplaint(widget.complaintId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "تفاصيل الشكوى".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.loadingDetail.value &&
                  controller.selected.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final complaint = controller.selected.value ?? {};
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  infoCardDetailsView(context, complaint),
                  const SizedBox(height: 12),
                  Text(
                    "الرسائل".tr,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...controller.messages.map(messageBubbleDetailsView),
                ],
              );
            }),
          ),
          inputAreaDetailsView(
            context,
            msgCtrl,
            widget.complaintId,
            controller,
            blue,
          ),
        ],
      ),
    );
  }
}

