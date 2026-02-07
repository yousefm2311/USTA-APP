// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';

// class CustomerArtisanDirectRequestView extends StatefulWidget {
//   final String artisanName;
//   final String artisanService;
//   final String artisanId;
//   final List<String>? artisanServices;
//   final double? artisanLat;
//   final double? artisanLng;
//   final String? artisanAddress;
//   final String? artisanDescription;
//   final double? artisanRating;
//   final double? artisanDistanceKm;

//   const CustomerArtisanDirectRequestView({
//     super.key,
//     required this.artisanName,
//     required this.artisanService,
//     required this.artisanId,
//     this.artisanServices,
//     this.artisanLat,
//     this.artisanLng,
//     this.artisanAddress,
//     this.artisanDescription,
//     this.artisanRating,
//     this.artisanDistanceKm,
//   });

//   @override
//   State<CustomerArtisanDirectRequestView> createState() =>
//       _CustomerArtisanDirectRequestViewState();
// }

// class _CustomerArtisanDirectRequestViewState
//     extends State<CustomerArtisanDirectRequestView> {
//   Color get bg => const Color(0xFF050816);
//   Color get card => const Color(0xFF0B1020);
//   Color get blue => const Color(0xFF2563EB);

//   final TextEditingController descriptionCtrl = TextEditingController();
//   final CustomerRequestsController _requests =
//       Get.find<CustomerRequestsController>();

//   late String selectedService;
//   late final List<String> services;

//   @override
//   void initState() {
//     super.initState();
//     services = (widget.artisanServices?.isNotEmpty ?? false)
//         ? widget.artisanServices!.where((e) => e.trim().isNotEmpty).toList()
//         : [widget.artisanService].where((e) => e.trim().isNotEmpty).toList();
//     if (services.isEmpty) services.add("خدمة");
//     selectedService = services.first;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       appBar: AppBar(
//         backgroundColor: bg,
//         elevation: 0,
//         title: const Text(
//           "طلب مباشر من الحرفي",
//           style: TextStyle(fontFamily: "Cairo"),
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _artisanHeader(),
//           _detailsCard(),
//           const SizedBox(height: 25),

//           _sectionTitle("نوع الخدمة"),
//           _serviceSelector(),

//           const SizedBox(height: 25),

//           _sectionTitle("وصف المشكلة"),
//           _descriptionField(),

//           const SizedBox(height: 35),

//           _submitButton(),
//         ],
//       ),
//     );
//   }

//   Widget _artisanHeader() {
//     final distanceText = widget.artisanDistanceKm != null
//         ? "${widget.artisanDistanceKm!.toStringAsFixed(1)} كم"
//         : null;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white12),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: blue.withOpacity(0.15),
//             child: const Icon(Icons.person, color: Colors.white),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.artisanName,
//                   style: const TextStyle(
//                     fontFamily: "Cairo",
//                     fontSize: 15,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   widget.artisanService,
//                   style: const TextStyle(
//                     fontFamily: "Cairo",
//                     fontSize: 12,
//                     color: Colors.white54,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (distanceText != null) ...[
//             const SizedBox(width: 8),
//             Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.white10,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 distanceText,
//                 style: const TextStyle(
//                     color: Colors.white70,
//                     fontFamily: "Cairo",
//                     fontSize: 12),
//               ),
//             ),
//           ]
//         ],
//       ),
//     );
//   }

//   Widget _detailsCard() {
//     return Container(
//       margin: const EdgeInsets.only(top: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.star, color: Colors.amber, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 widget.artisanRating != null
//                     ? widget.artisanRating!.toStringAsFixed(1)
//                     : "-",
//                 style: const TextStyle(
//                     color: Colors.white70, fontFamily: "Cairo"),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               const Icon(Icons.place_outlined,
//                   color: Colors.white70, size: 18),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   widget.artisanAddress ??
//                       ((widget.artisanLat != null && widget.artisanLng != null)
//                           ? "${widget.artisanLat!.toStringAsFixed(4)}, ${widget.artisanLng!.toStringAsFixed(4)}"
//                           : "العنوان غير متوفر"),
//                   style: const TextStyle(
//                       color: Colors.white70, fontFamily: "Cairo"),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           if ((widget.artisanDescription ?? '').isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Text(
//               widget.artisanDescription!,
//               style: const TextStyle(
//                   color: Colors.white60, fontFamily: "Cairo", height: 1.5),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _sectionTitle(String t) {
//     return Text(
//       t,
//       style: const TextStyle(
//         fontFamily: "Cairo",
//         color: Colors.white,
//         fontSize: 15,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }

//   Widget _serviceSelector() {
//     return Column(
//       children: services.map((s) {
//         final active = selectedService == s;
//         return GestureDetector(
//           onTap: () => setState(() => selectedService = s),
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: card,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: active ? blue : Colors.white12,
//                 width: active ? 1.5 : 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   active ? Icons.radio_button_checked : Icons.circle_outlined,
//                   color: active ? blue : Colors.white38,
//                   size: 18,
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   s,
//                   style: TextStyle(
//                     fontFamily: "Cairo",
//                     fontSize: 14,
//                     color: active ? Colors.white : Colors.white70,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _descriptionField() {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white12),
//       ),
//       child: TextField(
//         controller: descriptionCtrl,
//         maxLines: 5,
//         style: const TextStyle(color: Colors.white, fontFamily: "Cairo"),
//         decoration: const InputDecoration(
//           hintText: "اكتب وصفاً واضحاً للمشكلة...",
//           hintStyle: TextStyle(color: Colors.white30, fontFamily: "Cairo"),
//           border: InputBorder.none,
//         ),
//       ),
//     );
//   }

//   Widget _submitButton() {
//     return Obx(() {
//       final loading = _requests.submitting.value;
//       return SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: loading
//               ? null
//               : () async {
//                   if (selectedService.isEmpty) {
//                     AppSnackBar.show(
//                       "تنبيه",
//                       "اختر الخدمة أولاً",
//                       colorText: Colors.white,
//                       backgroundColor: Colors.redAccent,
//                     );
//                     return;
//                   }
//                   try {
//                     await _requests.createRequest(
//                       serviceType: selectedService,
//                       artisanId: widget.artisanId,
//                       description: descriptionCtrl.text.trim(),
//                     );
//                     AppSnackBar.show(
//                       "تم الإرسال",
//                       "تم إنشاء الطلب مع ${widget.artisanName}",
//                       colorText: Colors.white,
//                       backgroundColor: Colors.green,
//                     );
//                     Get.back();
//                   } catch (_) {
//                     // errors handled by controller
//                   }
//                 },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: blue,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//           ),
//           child: loading
//               ? const SizedBox(
//                   width: 22,
//                   height: 22,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//               : const Text(
//                   "إرسال الطلب",
//                   style: TextStyle(fontFamily: "Cairo", fontSize: 16),
//                 ),
//         ),
//       );
//     });
//   }
// }


