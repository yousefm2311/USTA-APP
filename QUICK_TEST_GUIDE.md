# Quick Test Guide - Real-time Chat

## ✅ Quick Test (2 minutes)

### Prerequisites
- Backend running at `http://172.17.100.202:5000`
- Two browser tabs open (or app + browser)

### Test Steps

1. **Log in as Customer** (Tab 1)
   - Navigate to customer chat list
   - Should see list of active chats (from API)

2. **Log in as Artisan** (Tab 2)
   - Navigate to artisan chat list
   - Should see same chats with customer names

3. **Open Chat from Both Sides**
   - Tab 1: Click on a chat → opens customer chat room
   - Tab 2: Click on same chat → opens artisan chat room
   - Both should show same message history

4. **Send Message** (Tab 1 - Customer)
   - Type a message in the text field
   - Click Send button
   - Message should appear immediately on Tab 1

5. **Verify Real-time** (Tab 2 - Artisan)
   - **WITHOUT REFRESHING**: Check Tab 2
   - Message should appear **instantly** ✅
   - If not: See "Troubleshooting" below

6. **Reply** (Tab 2 - Artisan)
   - Type a response
   - Send
   - Check Tab 1 - should update instantly ✅

## 🔧 Troubleshooting

### Problem: Messages don't appear in real-time

#### Step 1: Check Socket Connection
```
Run this in Dart console or your test page:
RealtimeController rt = Get.find<RealtimeController>();
print('Socket: ${rt.status.value}');
```
✅ Should print: `SocketStatus.connected`
❌ If `disconnected`: Socket failed to connect

#### Step 2: Check Browser Network Tab
1. Open DevTools → Network tab
2. Filter by "WS" (WebSocket)
3. Look for connection to `172.17.100.202:5000`
✅ Should show: Status `101 Switching Protocols`, green circle
❌ If red X: Backend not responding

#### Step 3: Check Dart Console
1. Open Dart DevTools console
2. Send a message
3. Look for logs:
   ```
   ✅ Socket connected
   📤 Emitting: chat:message with data: {...}
   ```
✅ If you see these: Socket communication working
❌ If no logs: Socket not initialized properly

#### Step 4: Check Backend Logs
1. SSH into backend server or check logs
2. Look for socket connection messages
3. Look for `chat:subscribe` events
4. Look for `chat:message` events
✅ If you see these: Backend receiving correctly
❌ If not: Check if app sent them

### Problem: "Failed to load messages" error

**Cause**: REST API not responding
**Fix**:
1. Verify backend is running
2. Check API endpoint: `http://172.17.100.202:5000/api/chat/{requestId}`
3. Make sure auth token is valid
4. Check network in DevTools

### Problem: Socket keeps disconnecting

**Cause**: Connection issue or token expired
**Fix**:
1. Check if token needs refresh
2. Check network stability
3. Look for error logs in console
4. Try manually calling `Get.find<RealtimeController>().reconnect()`

## 📊 Expected Behavior

### Message Flow
```
Sending Side:
  User types → sendTextMessage() 
  → Adds to messages list with state: 'sending'
  → Emits to socket
  → Show in UI immediately

Receiving Side:
  Socket receives event
  → ChatRealtimeService processes
  → Adds to ChatController.messages
  → Obx() rebuilds
  → Show in UI instantly
```

### Performance
- **Local network**: 50-100ms
- **Internet**: 100-500ms
- **Poor connection**: 500-2000ms

If taking longer: Check network tab, look for delays

## 🎯 Success Indicators

✅ Messages appear without page refresh
✅ Both customer and artisan see same messages
✅ Typing indicator appears (if implemented)
✅ Read receipts update (if implemented)
✅ New message notification appears (if implemented)

## 📝 Test Checklist

- [ ] Messages load when opening chat
- [ ] New message appears on sending side immediately
- [ ] New message appears on receiving side within 2 seconds
- [ ] Rapid message sending works (5+ messages)
- [ ] Works with special characters (Arabic ✓)
- [ ] Works with emojis ✓✓✓
- [ ] Refresh shows all messages (cache works)
- [ ] Works on poor network connection
- [ ] No memory leaks (open/close 10+ times)
- [ ] Socket reconnects after disconnect

## 🚀 Performance Testing

### Stress Test (Send 100 messages)
1. Open artisan chat room
2. Run this in console:
```dart
for (int i = 0; i < 100; i++) {
  ChatController cc = Get.find<ChatController>();
  cc.sendTextMessage(requestId, 'Message $i');
  await Future.delayed(Duration(milliseconds: 100));
}
```
✅ All should be sent without errors
✅ UI should remain responsive

### Memory Test
1. Open/close chat room 10 times
2. Check memory usage in DevTools
✅ Should not grow significantly
❌ If grows: Memory leak in subscriptions

## 🔍 Debug Commands

Add these to any page for instant debugging:

```dart
// Check socket status
Get.find<RealtimeController>().status.value

// Check messages in controller
Get.find<ChatController>().messages

// Check chats list
Get.find<ChatController>().chats

// Manually reconnect socket
Get.find<RealtimeController>().reconnect()

// Emit custom event (for testing)
Get.find<RealtimeController>().emit('test:event', {'data': 'test'})

// Subscribe to chat manually
Get.find<ChatRealtimeService>().subscribeToRequest('requestId123')
```

## 📞 Still Not Working?

1. **Check logs in console** - Look for error messages
2. **Check network tab** - Is socket connected?
3. **Check backend** - Is it running and sending events?
4. **Try manual test** - Send message via Postman
5. **Check permissions** - Does user have access to this chat?
6. **Check token** - Is auth token still valid?

See `REALTIME_CHAT_FIX.md` for detailed architecture explanation.
