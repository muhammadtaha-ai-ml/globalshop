import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  /// INIT FCM
  static Future<void> init() async {
    // Permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'water_alerts',
      'Water Alerts',
      description: 'Water level notifications',
      importance: Importance.high,
    );

    // ✅ FIXED: Create notification channel properly
    try {
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print("⚠️ Error creating notification channel: $e");
    }

    // Initialize local notifications
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _local.initialize(settings);

    // ✅ Foreground listener
    FirebaseMessaging.onMessage.listen((message) {
      _showLocal(message);
    });

    // ✅ Token refresh listener
    _messaging.onTokenRefresh.listen((newToken) async {
      await _updateTokenInDatabase(newToken);
    });
  }

  /// Show notification in foreground
  static Future<void> _showLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_alerts',
          'Water Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print("📱 FCM getToken() returned: ${token.substring(0, 20)}...");
      } else {
        print("📱 FCM getToken() returned: NULL");
      }
      return token;
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  /// ✅ NEW METHOD: Force refresh token and get it
  static Future<String?> refreshAndGetToken() async {
    try {
      print("🔄 Forcing FCM token refresh...");
      
      // Delete old token first
      await _messaging.deleteToken();
      print("   Old token deleted");
      
      // Wait a moment
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get new token
      final newToken = await _messaging.getToken();
      if (newToken != null) {
        print("   New token received: ${newToken.substring(0, 20)}...");
      } else {
        print("   New token: NULL");
      }
      
      return newToken;
    } catch (e) {
      print("❌ Error refreshing FCM token: $e");
      return null;
    }
  }

  /// Update token in database when it refreshes
  static Future<void> _updateTokenInDatabase(String newToken) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠️ Token refresh: User not logged in");
        return;
      }

      final uid = user.uid;
      final db = FirebaseDatabase.instance.ref();

      // 1️⃣ Update token in user record
      await db.child('users').child(uid).child('fcmToken').set(newToken);

      // 2️⃣ Get user's linked devices
      final devicesSnap =
          await db.child('users').child(uid).child('devices').get();
      
      if (!devicesSnap.exists) {
        print("ℹ️ Token refresh: No devices linked to user");
        return;
      }

      final devicesData = devicesSnap.value;
      if (devicesData == null) return;

      final Map<dynamic, dynamic> devices = devicesData as Map<dynamic, dynamic>;

      // 3️⃣ Update token in each linked device
      for (final deviceId in devices.keys) {
        await db
            .child('devices')
            .child(deviceId.toString())
            .child('tokens')
            .child(uid)
            .set(newToken);
        
        print("✅ Token refreshed: devices/$deviceId/tokens/$uid");
      }

      print("✅ Token refresh complete for ${devices.length} device(s)");
    } catch (e) {
      print("❌ Error updating refreshed token: $e");
    }
  }
}