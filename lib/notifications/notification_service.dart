import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference get notificationsRef {
    final uid = _uid;
    if (uid == null) throw Exception("User not logged in");
    return FirebaseDatabase.instance.ref('users').child(uid).child('notifications');
  }

  /// 📥 SAVE NOTIFICATION TO DATABASE
  static Future<void> saveNotification({
    required String title,
    required String body,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final newRef = notificationsRef.push();
      await newRef.set({
        'id': newRef.key,
        'title': title,
        'body': body,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
      });
      print("✅ NotificationService: Saved notification ${newRef.key}");
    } catch (e) {
      print("❌ NotificationService Error saving notification: $e");
    }
  }

  /// 🔗 STREAM UNREAD NOTIFICATIONS COUNT
  static Stream<int> getUnreadCountStream() {
    try {
      final uid = _uid;
      if (uid == null) return Stream.value(0);

      return notificationsRef.onValue.map((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return 0;
        }
        final Map all = event.snapshot.value as Map;
        int count = 0;
        all.forEach((key, value) {
          if (value is Map && value['isRead'] == false) {
            count++;
          }
        });
        return count;
      });
    } catch (e) {
      print("❌ NotificationService Error getUnreadCountStream: $e");
      return Stream.value(0);
    }
  }

  /// 📖 MARK ALL AS READ
  static Future<void> markAllAsRead() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final snapshot = await notificationsRef.get();
      if (!snapshot.exists || snapshot.value == null) return;

      final Map all = snapshot.value as Map;
      final Map<String, dynamic> updates = {};

      all.forEach((key, value) {
        if (value is Map && value['isRead'] == false) {
          updates['$key/isRead'] = true;
        }
      });

      if (updates.isNotEmpty) {
        await notificationsRef.update(updates);
        print("✅ NotificationService: Marked all notifications as read");
      }
    } catch (e) {
      print("❌ NotificationService Error marking all as read: $e");
    }
  }

  /// 🗑️ DELETE SINGLE NOTIFICATION
  static Future<void> deleteNotification(String id) async {
    try {
      await notificationsRef.child(id).remove();
      print("✅ NotificationService: Deleted notification $id");
    } catch (e) {
      print("❌ NotificationService Error deleting notification: $e");
    }
  }

  /// ➕ ADD INITIAL MOCK NOTIFICATIONS (To help user test if empty)
  static Future<void> addMockNotificationsIfNeeded() async {
    try {
      final snapshot = await notificationsRef.limitToFirst(1).get();
      if (!snapshot.exists || snapshot.value == null) {
        // Add 3 professional mock notifications
        await saveNotification(
          title: "System Initialized",
          body: "Welcome to GlobalShop! Your home monitor system is fully active.",
        );
        await Future.delayed(const Duration(milliseconds: 100));
        await saveNotification(
          title: "Water Tank Alert",
          body: "Water level is stable at 85%. All pumps are running optimally.",
        );
        await Future.delayed(const Duration(milliseconds: 100));
        await saveNotification(
          title: "Environment Monitor",
          body: "Gas sensor calibrated successfully. Air quality index: Safe.",
        );
      }
    } catch (e) {
      print("❌ NotificationService Error adding mock data: $e");
    }
  }
}
