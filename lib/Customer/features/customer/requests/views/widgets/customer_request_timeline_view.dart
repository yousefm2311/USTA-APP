// import 'package:flutter/material.dart';

// class CustomerRequestTimelineView extends StatelessWidget {
//   const CustomerRequestTimelineView({super.key});

//   Color get bg => const Color(0xFF050816);
//   Color get card => const Color(0xFF0B1020);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       appBar: AppBar(
//         backgroundColor: bg,
//         title: const Text("الخط الزمني", style: TextStyle(fontFamily: "Cairo")),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _step("تم إرسال الطلب", "10:15 ص"),
//           _step("تم قبول الطلب", "10:20 ص"),
//           _step("في الطريق إليك", "10:35 ص"),
//           _step("بدأ العمل", "10:45 ص"),
//         ],
//       ),
//     );
//   }

//   Widget _step(String title, String time) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white12),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.check_circle, color: Colors.greenAccent),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               "$title – $time",
//               style: const TextStyle(
//                 fontFamily: "Cairo",
//                 color: Colors.white,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
