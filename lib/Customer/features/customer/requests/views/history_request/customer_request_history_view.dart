// import 'package:flutter/material.dart';

// class CustomerRequestHistoryView extends StatelessWidget {
//   const CustomerRequestHistoryView({super.key});

//   Color get bg => const Color(0xFF050816);
//   Color get card => const Color(0xFF0B1020);
//   Color get blue => const Color(0xFF2563EB);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       appBar: AppBar(
//         backgroundColor: bg,
//         elevation: 0,
//         title: const Text(
//           "الطلبات السابقة",
//           style: TextStyle(fontFamily: "Cairo"),
//         ),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: 5,
//         itemBuilder: (_, i) => _historyCard(),
//       ),
//     );
//   }

// ignore_for_file: deprecated_member_use

//   Widget _historyCard() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text(
//             "إصلاح كهرباء",
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 15,
//               fontFamily: "Cairo",
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 6),
//           Text(
//             "اكتمل بتاريخ 24 ديسمبر 2025",
//             style: TextStyle(
//               color: Colors.white60,
//               fontSize: 12,
//               fontFamily: "Cairo",
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Customer/features/customer/requests/views/history_request/customer_completed_request_details_view.dart';
// class CustomerRequestHistoryView extends StatelessWidget {
//   const CustomerRequestHistoryView({super.key});

//   Color get bg => const Color(0xFF050816);
//   Color get card => const Color(0xFF0B1020);
//   Color get blue => const Color(0xFF2563EB);
//   Color get green => const Color(0xFF22C55E);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       appBar: AppBar(
//         backgroundColor: bg,
//         title: const Text("سجل الطلبات", style: TextStyle(fontFamily: "Cairo")),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: 4,
//         itemBuilder: (_, i) => _historyItem(),
//       ),
//     );
//   }

//   Widget _historyItem() {
//     return InkWell(
//       onTap: () {
//         Get.to(() => const CustomerCompletedRequestDetailsView());
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 14),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: card,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.white10),
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 22,
//               backgroundColor: blue.withOpacity(0.12),
//               child: const Icon(Icons.handyman, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   Text(
//                     "تصليح كهرباء – تم الانتهاء",
//                     style: TextStyle(
//                       fontFamily: "Cairo",
//                       fontSize: 14,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     "30 يناير - 2:35 م",
//                     style: TextStyle(
//                       fontFamily: "Cairo",
//                       color: Colors.white54,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }

