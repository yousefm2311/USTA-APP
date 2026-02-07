# 💻 Socket.IO Code Examples & Integration Guide

## 📚 Table of Contents

1. [Basic Socket Connection](#basic-socket-connection)
2. [Listening to Events](#listening-to-events)
3. [Emitting Events](#emitting-events)
4. [Joining Rooms](#joining-rooms)
5. [Creating Custom Listeners](#creating-custom-listeners)
6. [Error Handling](#error-handling)
7. [Integration Examples](#integration-examples)

---

## 🔌 Basic Socket Connection

### Connect to Socket
```dart
import 'package:get/get.dart';
import 'package:usta/core/realtime/realtime_controller.dart';

class MyController extends GetxController {
  final RealtimeController _rt = Get.find<RealtimeController>();

  @override
  void onInit() {
    super.onInit();
    // Socket connects automatically on app start
    // But you can manually reconnect if needed
    _rt.reconnect();
  }
}
```

### Check Connection Status
```dart
import 'package:usta/core/realtime/socket_manager.dart';

// Method 1: Using RealtimeController
final isConnected = _rt.status.value == SocketStatus.connected;

// Method 2: Using SocketManager directly
final isConnected = SocketManager.instance.isConnected;

// Method 3: Listen to status changes
_rt.status.listen((status) {
  if (status == SocketStatus.connected) {
    print('Socket connected!');
  } else {
    print('Socket disconnected!');
  }
});
```

---

## 👂 Listening to Events

### Listen to Single Event
```dart
import 'package:usta/core/realtime/events.dart';

// Listen to new request event
_rt.onEvent(RealtimeEvents.requestNew, (data) {
  print('New request received: $data');
  
  // Handle the data
  if (data is Map<String, dynamic>) {
    final requestId = data['_id'] ?? data['id'];
    final serviceType = data['serviceType'];
    print('Request ID: $requestId, Service: $serviceType');
  }
});
```

### Listen to Multiple Events
```dart
void _setupListeners() {
  // New request
  _rt.onEvent(RealtimeEvents.requestNew, _handleNewRequest);
  
  // Request accepted
  _rt.onEvent(RealtimeEvents.requestAccepted, _handleRequestAccepted);
  
  // Request rejected
  _rt.onEvent(RealtimeEvents.requestRejected, _handleRequestRejected);
  
  // Request cancelled
  _rt.onEvent(RealtimeEvents.requestCancelled, _handleRequestCancelled);
}

void _handleNewRequest(dynamic data) {
  print('New request: $data');
}

void _handleRequestAccepted(dynamic data) {
  print('Request accepted: $data');
}

void _handleRequestRejected(dynamic data) {
  print('Request rejected: $data');
}

void _handleRequestCancelled(dynamic data) {
  print('Request cancelled: $data');
}
```

### Stop Listening
```dart
// Remove specific handler
_rt.offEvent(RealtimeEvents.requestNew, _handleNewRequest);

// Or use SocketManager directly to remove all handlers for an event
SocketManager.instance.off(RealtimeEvents.requestNew);
```

---

## 📤 Emitting Events

### Emit Without Acknowledgement
```dart
_rt.emit('join', {
  'room': 'artisan:123456',
  'userId': '123456',
});
```

### Emit With Acknowledgement
```dart
_rt.emit(
  'custom:event',
  {'data': 'value'},
  ack: (response) {
    print('Server acknowledged: $response');
  },
);
```

### Emit from SocketManager
```dart
SocketManager.instance.emit('event:name', {
  'key': 'value',
});
```

---

## 🚪 Joining Rooms

### Join Single Room
```dart
void joinArtisanRoom(String artisanId) {
  _rt.emit('join', {
    'room': 'artisan:$artisanId',
    'userId': artisanId,
  });
  print('Joined room: artisan:$artisanId');
}
```

### Join Multiple Rooms
```dart
void joinRooms(String userId) {
  // Join artisan room
  _rt.emit('join', {
    'room': 'artisan:$userId',
    'userId': userId,
  });
  
  // Join user room
  _rt.emit('join', {
    'room': 'user:$userId',
    'userId': userId,
  });
  
  print('Joined multiple rooms for user: $userId');
}
```

### Leave Room
```dart
void leaveRoom(String roomName) {
  _rt.emit('leave', {
    'room': roomName,
  });
  print('Left room: $roomName');
}
```

---

## 🎨 Creating Custom Listeners

### Custom Service Example
```dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:usta/core/realtime/realtime_controller.dart';
import 'package:usta/core/realtime/events.dart';

class MyCustomRealtimeService extends GetxService {
  final RealtimeController _rt = Get.find<RealtimeController>();
  final List<StreamSubscription> _subs = [];
  
  @override
  void onInit() {
    super.onInit();
    _listenToConnection();
    _registerEvents();
  }
  
  void _listenToConnection() {
    final sub = _rt.status.listen((status) {
      if (status == SocketStatus.connected) {
        print('Connected! Joining rooms...');
        _joinRooms();
      }
    });
    _subs.add(sub);
  }
  
  void _registerEvents() {
    _rt.onEvent(RealtimeEvents.requestNew, _handleNewRequest);
  }
  
  void _handleNewRequest(dynamic data) {
    print('Custom handler: New request received!');
    // Your custom logic here
  }
  
  void _joinRooms() {
    // Join your custom rooms
    _rt.emit('join', {'room': 'my:custom:room'});
  }
  
  @override
  void onClose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.onClose();
  }
}
```

### Register Custom Service
```dart
// In binding.dart
Get.put<MyCustomRealtimeService>(
  MyCustomRealtimeService(),
  permanent: true,
);
```

---

## 🛡️ Error Handling

### Handle Connection Errors
```dart
import 'package:usta/core/realtime/socket_service.dart';

class MyController extends GetxController {
  final SocketService _socket = SocketService.to;
  
  @override
  void onInit() {
    super.onInit();
    _listenToAuthErrors();
  }
  
  void _listenToAuthErrors() {
    _socket.authError.listen((error) {
      if (error != null) {
        print('Socket auth error: $error');
        // Handle auth error (e.g., logout user)
        _handleAuthError();
      }
    });
  }
  
  void _handleAuthError() {
    // Logout or refresh token
    Get.offAllNamed('/login');
  }
}
```

### Handle Event Errors
```dart
_rt.onEvent(RealtimeEvents.requestNew, (data) {
  try {
    // Parse and handle data
    final request = Map<String, dynamic>.from(data);
    final id = request['_id'] ?? request['id'];
    
    if (id == null) {
      throw Exception('Request ID is null');
    }
    
    // Process request
    _processRequest(request);
  } catch (e, stack) {
    print('Error handling request event: $e');
    print('Stack trace: $stack');
    // Log error or show user feedback
  }
});
```

---

## 🔗 Integration Examples

### Example 1: Update UI on New Request
```dart
class RequestsController extends GetxController {
  final RealtimeController _rt = Get.find<RealtimeController>();
  final RxList<Map<String, dynamic>> requests = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _listenToNewRequests();
  }
  
  void _listenToNewRequests() {
    _rt.onEvent(RealtimeEvents.requestNew, (data) {
      if (data is Map<String, dynamic>) {
        // Add to list (UI updates automatically)
        requests.insert(0, data);
        
        // Show notification
        _showNotification(data);
      }
    });
  }
  
  void _showNotification(Map<String, dynamic> request) {
    Get.snackbar(
      'طلب جديد',
      'لديك طلب جديد من ${request['customer']?['name'] ?? 'عميل'}',
      duration: const Duration(seconds: 5),
    );
  }
}
```

### Example 2: Show Dialog on Event
```dart
void _listenToNewRequests() {
  _rt.onEvent(RealtimeEvents.requestNew, (data) {
    if (data is Map<String, dynamic>) {
      _showRequestDialog(data);
    }
  });
}

void _showRequestDialog(Map<String, dynamic> request) {
  Get.dialog(
    AlertDialog(
      title: const Text('طلب جديد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('العميل: ${request['customer']?['name'] ?? 'غير محدد'}'),
          Text('الخدمة: ${request['serviceType'] ?? 'غير محدد'}'),
          Text('العنوان: ${request['address'] ?? 'غير محدد'}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إغلاق'),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            _navigateToRequestDetails(request['_id'] ?? request['id']);
          },
          child: const Text('عرض التفاصيل'),
        ),
      ],
    ),
  );
}
```

### Example 3: Sync with REST API
```dart
class RequestsController extends GetxController {
  final RealtimeController _rt = Get.find<RealtimeController>();
  final RxList<Map<String, dynamic>> requests = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _listenToConnection();
    _listenToEvents();
  }
  
  void _listenToConnection() {
    _rt.status.listen((status) {
      if (status == SocketStatus.connected) {
        // Sync with REST API when connected
        _syncWithServer();
      }
    });
  }
  
  void _listenToEvents() {
    _rt.onEvent(RealtimeEvents.requestNew, _handleNewRequest);
    _rt.onEvent(RealtimeEvents.requestAccepted, _handleRequestUpdate);
    _rt.onEvent(RealtimeEvents.requestRejected, _handleRequestUpdate);
  }
  
  void _handleNewRequest(dynamic data) {
    if (data is Map<String, dynamic>) {
      _upsertRequest(data);
    }
  }
  
  void _handleRequestUpdate(dynamic data) {
    if (data is Map<String, dynamic>) {
      _upsertRequest(data);
    }
  }
  
  void _upsertRequest(Map<String, dynamic> request) {
    final id = request['_id'] ?? request['id'];
    final index = requests.indexWhere(
      (r) => (r['_id'] ?? r['id']) == id,
    );
    
    if (index >= 0) {
      // Update existing
      requests[index] = {...requests[index], ...request};
      requests.refresh();
    } else {
      // Add new
      requests.insert(0, request);
    }
  }
  
  Future<void> _syncWithServer() async {
    try {
      // Fetch from REST API
      final response = await api.getNewRequests();
      requests.assignAll(response);
    } catch (e) {
      print('Error syncing with server: $e');
    }
  }
}
```

---

## 🎯 Best Practices

### 1. Always Check Connection Status
```dart
if (_rt.status.value == SocketStatus.connected) {
  _rt.emit('event', data);
} else {
  print('Cannot emit: Socket not connected');
}
```

### 2. Use Event Constants
```dart
// ✅ Good
_rt.onEvent(RealtimeEvents.requestNew, handler);

// ❌ Bad
_rt.onEvent('request:new', handler);
```

### 3. Clean Up Subscriptions
```dart
@override
void onClose() {
  // Remove event listeners
  _rt.offEvent(RealtimeEvents.requestNew, _handleNewRequest);
  
  // Cancel stream subscriptions
  for (final sub in _subs) {
    sub.cancel();
  }
  
  super.onClose();
}
```

### 4. Handle Errors Gracefully
```dart
_rt.onEvent(RealtimeEvents.requestNew, (data) {
  try {
    _processRequest(data);
  } catch (e) {
    print('Error: $e');
    // Don't crash the app
  }
});
```

### 5. Sync on Reconnect
```dart
_rt.status.listen((status) {
  if (status == SocketStatus.connected) {
    _syncWithServer(); // Ensure data is up-to-date
  }
});
```

---

## 📝 Common Patterns

### Pattern 1: Queue Events While Disconnected
```dart
final List<Map<String, dynamic>> _pendingEvents = [];

void emitEvent(String event, dynamic data) {
  if (_rt.status.value == SocketStatus.connected) {
    _rt.emit(event, data);
  } else {
    _pendingEvents.add({'event': event, 'data': data});
  }
}

void _flushPendingEvents() {
  for (final item in _pendingEvents) {
    _rt.emit(item['event'], item['data']);
  }
  _pendingEvents.clear();
}

// Call when connected
_rt.status.listen((status) {
  if (status == SocketStatus.connected) {
    _flushPendingEvents();
  }
});
```

### Pattern 2: Debounce Events
```dart
import 'dart:async';

Timer? _debounceTimer;

void _handleEvent(dynamic data) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    _processEvent(data);
  });
}
```

### Pattern 3: Event Acknowledgement
```dart
void sendWithConfirmation(String event, dynamic data) {
  _rt.emit(event, data, ack: (response) {
    if (response['success'] == true) {
      print('Event sent successfully');
    } else {
      print('Event failed: ${response['error']}');
    }
  });
}
```

---

## 🔐 Security Notes

1. **Token Validation**: Always ensure token is valid before connecting
2. **Room Isolation**: Only join rooms you're authorized for
3. **Data Validation**: Validate all incoming data
4. **Error Messages**: Don't expose sensitive info in error messages

---

## 🚀 Performance Tips

1. **Limit Listeners**: Don't create duplicate listeners
2. **Clean Up**: Always remove listeners when not needed
3. **Batch Updates**: Group multiple UI updates together
4. **Debounce**: Prevent rapid-fire events from overwhelming UI

---

**Happy Coding! 💻**

Created by Antigravity 🚀
