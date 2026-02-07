// // ignore_for_file: unused_element_parameter, camel_case_types

// import 'package:flutter/material.dart';

// class RequestServiceSelector extends StatelessWidget {
//   const RequestServiceSelector({super.key});

//   Color get card => const Color(0xFF0B1020);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text(
//             "نوع الخدمة",
//             style: TextStyle(
//               color: Colors.white,
//               fontFamily: "Cairo",
//               fontSize: 14,
//             ),
//           ),
//           SizedBox(height: 12),
//           _item("كشف فني"),
//           _item("تصليح شامل"),
//           _item("تركيب جديد"),
//         ],
//       ),
//     );
//   }
// }

// class _item extends StatelessWidget {
  
//   const _item(this.title, {super.key});
// final String title;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.white24),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         title,
//         style: const TextStyle(color: Colors.white, fontFamily: "Cairo"),
//       ),
//     );
//   }
// }
