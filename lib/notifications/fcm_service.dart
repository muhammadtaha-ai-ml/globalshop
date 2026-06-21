import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:globalshop/notifications/notification_service.dart';

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  // ✅ Android notification channel — must match Cloud Functions channelId
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'water_alerts',      // id — must match index.js
    'Water Alerts',      // name
    description: 'Water level and gas sensor notifications',
    importance: Importance.max, // ✅ max instead of high
    playSound: true,
    enableVibration: true,
  );

  /// INIT FCM — call once in main()
  static Future<void> init() async {
    if (kIsWeb) {
      print("🔔 FCMService: Web platform detected. Skipping FCM setup.");
      return;
    }

    // 1️⃣ Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print("🔔 FCM Permission: ${settings.authorizationStatus}");

    // 2️⃣ Create Android notification channel
    try {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      print("✅ Notification channel created: water_alerts");
    } catch (e) {
      print("⚠️ Error creating notification channel: $e");
    }

    // 3️⃣ Initialize local notifications plugin
    const InitializationSettings settings2 = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _local.initialize(settings2);
    print("✅ Local notifications initialized");

    // 4️⃣ ✅ Set foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5️⃣ Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message received: ${message.notification?.title}");
      _showLocal(message);
      
      final title = message.notification?.title ?? message.data['title'] ?? 'Alert';
      final body = message.notification?.body ?? message.data['body'] ?? 'New sensor trigger';
      NotificationService.saveNotification(title: title, body: body);
    });

    // 6️⃣ Background/terminated message handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 App opened from notification: ${message.notification?.title}");
      
      final title = message.notification?.title ?? message.data['title'] ?? 'Alert';
      final body = message.notification?.body ?? message.data['body'] ?? 'New sensor trigger';
      NotificationService.saveNotification(title: title, body: body);
    });

    // 7️⃣ Token refresh listener — auto-update all devices
    _messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...");
      await _updateTokenInDatabase(newToken);
    });

    print("✅ FCMService.init() complete");
  }

  /// Show notification when app is in foreground
  static Future<void> _showLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_alerts',   // ✅ must match channel id above
          'Water Alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    if (kIsWeb) {
      print("📱 FCM Token: Skipped on Web platform.");
      return null;
    }
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        print("📱 FCM Token: ${token.substring(0, 20)}...");
      } else {
        print("📱 FCM Token: NULL");
      }
      return token;
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  /// Force refresh token (delete old + get new)
  static Future<String?> refreshAndGetToken() async {
    if (kIsWeb) {
      print("🔄 Force FCM token refresh: Skipped on Web platform.");
      return null;
    }
    try {
      print("🔄 Forcing FCM token refresh...");
      await _messaging.deleteToken();
      print("   Old token deleted");

      await Future.delayed(const Duration(milliseconds: 800));

      final newToken = await _messaging.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        print("   New token: ${newToken.substring(0, 20)}...");
      } else {
        print("   New token: NULL");
      }
      return newToken;
    } catch (e) {
      print("❌ Error refreshing FCM token: $e");
      return null;
    }
  }

  /// Auto-update token in DB when FCM refreshes it
  static Future<void> _updateTokenInDatabase(String newToken) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠️ Token refresh: No user logged in");
        return;
      }

      final uid = user.uid;
      final db = FirebaseDatabase.instance.ref();

      // Update in user record
      await db.child('users').child(uid).child('fcmToken').set(newToken);
      print("✅ Token refreshed: users/$uid/fcmToken");

      // Get user's devices
      final devicesSnap =
          await db.child('users').child(uid).child('devices').get();
      if (!devicesSnap.exists || devicesSnap.value == null) {
        print("ℹ️ Token refresh: No devices for user");
        return;
      }

      final Map<dynamic, dynamic> devices =
          devicesSnap.value as Map<dynamic, dynamic>;

      for (final entry in devices.entries) {
        final deviceId = entry.key.toString();
        final deviceData = entry.value;

        // Skip inactive
        if (deviceData is Map && deviceData['isActive'] == false) continue;

        // ✅ Update token in global devices node
        await db
            .child('devices')
            .child(deviceId)
            .child('tokens')
            .child(uid)
            .set(newToken);

        print("✅ Token refreshed: devices/$deviceId/tokens/$uid");
      }

      print("✅ Token auto-refresh complete for ${devices.length} device(s)");
    } catch (e) {
      print("❌ Error in _updateTokenInDatabase: $e");
    }
  }
}