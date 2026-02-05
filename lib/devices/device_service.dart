import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:globalshop/auth/controllers/auth_controller.dart'; // ← IMPORT THIS

class DeviceService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static DatabaseReference get userDevicesRef =>
      _db.child('users').child(_uid).child('devices');
 
  // ➕ ADD DEVICE
  /// ✅ FIXED: Now calls AuthController.linkDevice() to save FCM token
  static Future<String?> addDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      print("🔄 DeviceService: Adding device $deviceId");
      
      // 1️⃣ Save device info in user's devices list
      await userDevicesRef.child(deviceId).set({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'createdAt': ServerValue.timestamp,
      });
      
      print("✅ DeviceService: Device info saved");
      
      // 2️⃣ ✅ CRITICAL: Call linkDevice to save FCM token
      final authController = AuthController();
      final error = await authController.linkDevice(deviceId: deviceId);
      
      if (error != null) {
        print("❌ DeviceService: Error linking device - $error");
        return error;
      }
      
      print("✅ DeviceService: Device linked with FCM token");
      return null; // Success
      
    } catch (e) {
      print("❌ DeviceService: Error adding device - $e");
      return e.toString();
    }
  }

  // 📋 GET DEVICES
  static DatabaseReference getDevices() {
    return userDevicesRef;
  }
}
