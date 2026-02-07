// import 'dart:convert';
// import 'dart:developer' as developer;

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Artisan/core/realtime/events.dart';
// import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
// import 'package:usta/Artisan/core/realtime/socket_manager.dart';
// import 'package:usta/Artisan/core/realtime/socket_service.dart' hide SocketStatus;
// import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
// import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
// import 'package:usta/Artisan/core/utils/constants/app_constant.dart';

// class SocketTestPage extends StatefulWidget {
//   const SocketTestPage({super.key});

//   @override
//   State<SocketTestPage> createState() => _SocketTestPageState();
// }

// class _SocketTestPageState extends State<SocketTestPage> {
//   final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');
//   final AppPrefs _prefs = AppPrefs();
//   final List<String> _logs = [];
//   final ScrollController _scrollController = ScrollController();

//   String? _token;
//   String? _artisanId;
//   bool _isListening = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadTokenAndProfile();
//     _listenToStatus();
//   }

//   Future<void> _loadTokenAndProfile() async {
//     await _prefs.init();
//     _token = _prefs.getString(kAuthTokenKey);

//     // Load artisan ID from cached profile
//     try {
//       final cached = _prefs.getString(kCachedProfileKey);
//       if (cached != null && cached.isNotEmpty) {
//         final map = jsonDecode(cached);
//         if (map is Map) {
//           _artisanId = (map['_id'] ?? map['id'])?.toString();
//         }
//       }
//     } catch (e) {
//       _addLog('❌ Error loading profile: $e');
//     }

//     setState(() {});
//     _addLog('📋 Token loaded: ${_token?.substring(0, 20)}...');
//     _addLog('👤 Artisan ID: $_artisanId');
//   }

//   void _listenToStatus() {
//     _rt.status.listen((status) {
//       _addLog('🔌 Socket Status: ${status.toString().split('.').last}');
//     });
//   }

//   void _addLog(String message) {
//     setState(() {
//       _logs.add(
//         '${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)} - $message',
//       );
//     });

//     // Auto scroll to bottom
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });

//     developer.log(message);
//   }

//   void _connectSocket() {
//     _addLog('🔄 Attempting to connect socket...');
//     _rt.reconnect();
//   }

//   void _disconnectSocket() {
//     _addLog('🔌 Disconnecting socket...');
//     SocketManager.instance.disconnect();
//   }

//   void _subscribeToEvents() {
//     if (_isListening) {
//       _addLog('⚠️ Already listening to events');
//       return;
//     }

//     _addLog('👂 Subscribing to request:new event...');

//     _rt.onEvent(RealtimeEvents.requestNew, (data) {
//       _addLog('🆕 NEW REQUEST RECEIVED!');
//       _addLog('📦 Payload: ${jsonEncode(data)}');

//       // Show dialog
//       if (mounted) {
//         _showRequestDialog(data);
//       }
//     });

//     // Subscribe to other events for debugging
//     _rt.onEvent(RealtimeEvents.requestAccepted, (data) {
//       _addLog('✅ Request Accepted: ${jsonEncode(data)}');
//     });

//     _rt.onEvent(RealtimeEvents.requestRejected, (data) {
//       _addLog('❌ Request Rejected: ${jsonEncode(data)}');
//     });

//     _rt.onEvent(RealtimeEvents.requestCancelled, (data) {
//       _addLog('🚫 Request Cancelled: ${jsonEncode(data)}');
//     });

//     _rt.onEvent(RealtimeEvents.requestInProgress, (data) {
//       _addLog('🔄 Request In Progress: ${jsonEncode(data)}');
//     });

//     _rt.onEvent(RealtimeEvents.requestCompleted, (data) {
//       _addLog('✅ Request Completed: ${jsonEncode(data)}');
//     });

//     setState(() {
//       _isListening = true;
//     });
//     _addLog('✅ Subscribed to all request events');
//   }

//   void _joinRooms() {
//     if (_artisanId == null || _artisanId!.isEmpty) {
//       _addLog('❌ Cannot join rooms: Artisan ID not found');
//       return;
//     }

//     _addLog('🚪 Joining rooms...');

//     // Join artisan room
//     _rt.emit('join', {'room': 'artisan:$_artisanId', 'userId': _artisanId});
//     _addLog('✅ Joined room: artisan:$_artisanId');

//     // Join user room (for testing)
//     _rt.emit('join', {'room': 'user:$_artisanId', 'userId': _artisanId});
//     _addLog('✅ Joined room: user:$_artisanId');
//   }

//   void _showRequestDialog(dynamic data) {
//     final Map<String, dynamic> request = data is Map
//         ? Map<String, dynamic>.from(data)
//         : {};

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('🆕 طلب جديد وصل!'),
//         content: SingleChildScrollView(
//           child: Text(
//             const JsonEncoder.withIndent('  ').convert(request),
//             style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('إغلاق'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _createTestRequest() async {
//     if (_artisanId == null || _artisanId!.isEmpty) {
//       _addLog('❌ No artisan ID found.');
//       return;
//     }

//     _addLog('ℹ️ To test Socket.IO real-time events:');
//     _addLog('');
//     _addLog('📱 Method 1: Use Customer App');
//     _addLog('   1. Login as a CUSTOMER (not artisan)');
//     _addLog('   2. Create a request for this artisan');
//     _addLog('   3. Artisan ID: $_artisanId');
//     _addLog('   4. Watch this screen for the event!');
//     _addLog('');
//     _addLog('🌐 Method 2: Use Postman/API Client');
//     _addLog('   POST ${ApiEndpoints.baseUrl}/customer/requests');
//     _addLog('   Headers:');
//     _addLog('     Authorization: Bearer {CUSTOMER_TOKEN}');
//     _addLog('     Content-Type: application/json');
//     _addLog('   Body:');
//     _addLog('   {');
//     _addLog('     "artisanId": "$_artisanId",');
//     _addLog('     "serviceType": "Test Service",');
//     _addLog('     "description": "Test request",');
//     _addLog('     "address": "Cairo, Egypt",');
//     _addLog(
//       '     "scheduledDate": "${DateTime.now().add(const Duration(days: 1)).toIso8601String()}"',
//     );
//     _addLog('   }');
//     _addLog('');
//     _addLog('⏳ Waiting for request event...');
//     _addLog('💡 Make sure you clicked: Connect → Subscribe → Join Rooms');

//     // Show dialog with instructions
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('📋 كيفية اختبار السوكت'),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'لاختبار وصول الطلبات لحظياً:',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text('الطريقة 1: استخدام تطبيق العميل'),
//                 const SizedBox(height: 8),
//                 const Text('1. سجل دخول كـ عميل (Customer)'),
//                 const Text('2. اعمل طلب جديد'),
//                 Text('3. اختر الحرفي: $_artisanId'),
//                 const Text('4. راقب هذه الشاشة!'),
//                 const SizedBox(height: 16),
//                 const Text('الطريقة 2: استخدام Postman'),
//                 const SizedBox(height: 8),
//                 const Text('1. افتح Postman'),
//                 const Text('2. POST /api/customer/requests'),
//                 const Text('3. استخدم توكن عميل'),
//                 Text('4. في الـ Body ضع: artisanId = $_artisanId'),
//                 const SizedBox(height: 16),
//                 const Text(
//                   '💡 تأكد إنك ضغطت: Connect → Subscribe → Join Rooms',
//                   style: TextStyle(
//                     color: Colors.orange,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('فهمت'),
//             ),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 // Copy artisan ID to clipboard would be nice
//                 _addLog('📋 Artisan ID: $_artisanId');
//               },
//               icon: const Icon(Icons.copy),
//               label: const Text('نسخ Artisan ID'),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   void _clearLogs() {
//     setState(() {
//       _logs.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Socket.IO Test'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: Column(
//         children: [
//           // Status Bar
//           Obx(() {
//             final status = _rt.status.value;
//             final isConnected = status == SocketStatus.connected;

//             return Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               color: isConnected ? Colors.green : Colors.red,
//               child: Row(
//                 children: [
//                   Icon(
//                     isConnected ? Icons.check_circle : Icons.error,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     isConnected ? 'Connected' : 'Disconnected',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (!isConnected)
//                     const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }),

//           // Control Buttons
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _connectSocket,
//                   icon: const Icon(Icons.power),
//                   label: const Text('Connect'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _disconnectSocket,
//                   icon: const Icon(Icons.power_off),
//                   label: const Text('Disconnect'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _subscribeToEvents,
//                   icon: const Icon(Icons.notifications_active),
//                   label: Text(_isListening ? 'Listening...' : 'Subscribe'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _isListening ? Colors.orange : Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _joinRooms,
//                   icon: const Icon(Icons.meeting_room),
//                   label: const Text('Join Rooms'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.purple,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _createTestRequest,
//                   icon: const Icon(Icons.help_outline),
//                   label: const Text('How to Test?'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _clearLogs,
//                   icon: const Icon(Icons.clear_all),
//                   label: const Text('Clear Logs'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const Divider(),

//           // Logs
//           Expanded(
//             child: Container(
//               color: Colors.black,
//               padding: const EdgeInsets.all(8),
//               child: _logs.isEmpty
//                   ? const Center(
//                       child: Text(
//                         'No logs yet. Start by connecting the socket.',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       controller: _scrollController,
//                       itemCount: _logs.length,
//                       itemBuilder: (context, index) {
//                         final log = _logs[index];
//                         Color textColor = Colors.white;

//                         if (log.contains('❌') || log.contains('Error')) {
//                           textColor = Colors.red;
//                         } else if (log.contains('✅') ||
//                             log.contains('Success')) {
//                           textColor = Colors.green;
//                         } else if (log.contains('⚠️') ||
//                             log.contains('Warning')) {
//                           textColor = Colors.orange;
//                         } else if (log.contains('🆕') ||
//                             log.contains('NEW REQUEST')) {
//                           textColor = Colors.yellow;
//                         }

//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 2),
//                           child: Text(
//                             log,
//                             style: TextStyle(
//                               color: textColor,
//                               fontFamily: 'monospace',
//                               fontSize: 12,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

