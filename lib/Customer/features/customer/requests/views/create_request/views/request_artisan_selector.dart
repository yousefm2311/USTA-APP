// import 'package:flutter/material.dart';

// class RequestArtisanSelector extends StatelessWidget {
//   const RequestArtisanSelector({super.key});

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
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 24,
//             backgroundColor: blue.withOpacity(0.2),
//             child: const Icon(Icons.person),
//           ),
//           const SizedBox(width: 12),
//           const Expanded(
//             child: Text(
//               "اختيار حرفي (اختياري)",
//               style: TextStyle( fontFamily: "Cairo"),
//             ),
//           ),
//           const Icon(Icons.arrow_forward_ios, size: 16),
//         ],
//       ),
//     );
//   }
// }
