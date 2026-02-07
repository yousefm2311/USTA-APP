# Socket.IO Real-time Request Testing - Quick Reference

## 🎯 Purpose
Test and verify that requests arrive in real-time via Socket.IO without page refresh.

## 🚀 Quick Steps

### 1. Access Test Page
- Login as **Artisan**
- Home → **"Socket Test"** button (Quick Actions)

### 2. Connect Socket
- Click **"Connect"** (green button)
- Status bar should turn **green** with "Connected"
- Check logs for: `✅ Socket connected`

### 3. Subscribe to Events
- Click **"Subscribe"** (blue button)
- Button turns **orange** → "Listening..."
- Logs show: `✅ Subscribed to all request events`

### 4. Join Rooms
- Click **"Join Rooms"** (purple button)
- Logs confirm: `✅ Joined room: artisan:{artisanId}`

### 5. Create Test Request
- Click **"Create Test Request"** (teal button)
- REST API creates a new request
- Logs show: `✅ Request created successfully!`

### 6. Verify Real-time Event
- **Expected:** Dialog pops up with request details
- **Logs show:** `🆕 NEW REQUEST RECEIVED!`
- **Payload:** Full request object in JSON

## 🔍 Troubleshooting

### Socket Won't Connect
- ❌ Red status bar
- ✅ **Fix:** Logout and login again (refresh token)

### Connected but No Events
- ❌ Green status but no `request:new` event
- ✅ **Fix:** 
  1. Click "Join Rooms"
  2. Verify `artisanId` matches in request
  3. Check server logs for `emit request:new to artisan:...`

### Event in Server but Not Client
- ❌ Server emits but client doesn't receive
- ✅ **Fix:**
  1. Verify exact event name: `request:new` (not `request:created`)
  2. Confirm room membership
  3. Reconnect socket

## 📡 Technical Details

**Socket URL:**
```
ws://172.17.100.202:5000/socket.io/?token={token}&transport=websocket
```

**Rooms:**
```
artisan:{artisanId}  // Primary room for artisan
user:{artisanId}     // Optional user room
```

**Events Monitored:**
- `request:new` - New request
- `request:accepted` - Request accepted
- `request:rejected` - Request rejected
- `request:cancelled` - Request cancelled
- `request:in_progress` - Request in progress
- `request:completed` - Request completed

**REST Fallback:**
```
GET /api/artisan/requests/new      // Fetch new requests
GET /api/artisan/requests/active   // Fetch active requests
GET /api/artisan/requests/history  // Fetch history
```

## ✅ Success Indicators

1. ✅ Green status bar "Connected"
2. ✅ Orange "Listening..." button
3. ✅ Rooms joined in logs
4. ✅ `🆕 NEW REQUEST RECEIVED!` in logs
5. ✅ Dialog appears with request details

## 🎨 Log Color Coding

- 🟢 **Green** - Success messages
- 🔴 **Red** - Errors
- 🟡 **Yellow** - New request events
- 🟠 **Orange** - Warnings
- ⚪ **White** - General info

## 📝 Important Notes

1. **Valid Token Required** - Server rejects invalid/expired tokens
2. **Correct artisanId** - Request must target logged-in artisan
3. **Exact Event Names** - Case-sensitive: `request:new`
4. **Room Membership** - Must join rooms to receive events
5. **Network Connection** - Ensure stable internet connection

---

**Created by Antigravity 🚀**
