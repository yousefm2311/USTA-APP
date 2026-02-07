// import 'package:flutter/material.dart';

// class RequestCategorySelector extends StatelessWidget {
//   const RequestCategorySelector({super.key});

//   Color get card => const Color(0xFF0B1020);
//   Color get blue => const Color(0xFF2563EB);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color:  Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "اختر القسم",
//             style: TextStyle(
//               fontFamily: "Cairo",
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               _item(Icons.water_drop, "سباكة"),
//               const SizedBox(width: 12),
//               _item(Icons.bolt, "كهرباء"),
//               const SizedBox(width: 12),
//               _item(Icons.chair, "نجارة"),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _item(IconData icon, String title) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.white24),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: blue, size: 26),
//             const SizedBox(height: 6),
//             Text(
//               title,
//               style: const TextStyle(fontFamily: "Cairo"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
