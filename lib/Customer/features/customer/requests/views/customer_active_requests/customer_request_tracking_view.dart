// import 'package:flutter/material.dart';

// class CustomerRequestTrackingView extends StatelessWidget {
//   const CustomerRequestTrackingView({super.key});

//   Color get bg => const Color(0xFF050816);
//   Color get card => const Color(0xFF0B1020);
//   Color get blue => const Color(0xFF2563EB);

//   final steps = const [
//     "جاري مراجعة الطلب",
//     "تم قبول الطلب",
//     "الحرفي في الطريق",
//     "جاري التنفيذ",
//     "اكتمل الطلب",
//   ];

//   final currentStep = 2; // Placeholder

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       appBar: AppBar(
//         backgroundColor: bg,
//         elevation: 0,
//         title: const Text("تتبع الطلب", style: TextStyle(fontFamily: "Cairo")),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: steps.length,
//         itemBuilder: (_, i) => _stepItem(i),
//       ),
//     );
//   }

//   Widget _stepItem(int index) {
//     bool isDone = index <= currentStep;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: card,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: isDone ? blue : Colors.white10,
//           width: isDone ? 1.5 : 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.check_circle,
//             color: isDone ? blue : Colors.white24,
//             size: 26,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             steps[index],
//             style: TextStyle(
//               color: isDone ? Colors.white : Colors.white60,
//               fontFamily: "Cairo",
//               fontSize: 14,
//               fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
