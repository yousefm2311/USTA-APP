import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:usta/Customer/core/utils/app_snackbar.dart';

Future<String> getAccessToken() async {
  final jsonString = await rootBundle.loadString(
    'assets/notification_key/usta-89a20-d2cbd81d001b.json',
  );

  final accountCredentials = auth.ServiceAccountCredentials.fromJson(
    jsonString,
  );

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  final client = await auth.clientViaServiceAccount(accountCredentials, scopes);

  return client.credentials.accessToken.data;
}



Future<void> sendNotification({
  required String token,
  required String title,
  required String body,
  required Map<String, String> data,
}) async {
  final String accessToken = await getAccessToken();
  final String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/usta-89a20/messages:send';



      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    AppSnackBar.show(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 5),
    );
  });


  final response = await http.post(
    Uri.parse(fcmUrl),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode(<String, dynamic>{
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'data': data,

        'android': {
          'notification': {
            "sound": "custom_sound",
            'click_action':
                'FLUTTER_NOTIFICATION_CLICK',
            'channel_id': 'high_importance_channel',
          },
        },
        'apns': {
          'payload': {
            'aps': {"sound": "custom_sound.caf", 'content-available': 1},
          },
        },
      },
    }),
  );

  if (response.statusCode == 200) {
    debugPrint('Notification sent successfully');
  } else {
    debugPrint('Failed to send notification: ${response.body}');
  }
}

void handleNotification(BuildContext context, Map<String, dynamic> data) {
  String route = data['route'];
  String id = data['id'];

  if (route == '/product_detials') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Container(),
      ),
    );
  }
}


