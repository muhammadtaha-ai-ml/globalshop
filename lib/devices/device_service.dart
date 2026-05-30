import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:globalshop/auth/controllers/auth_controller.dart';

class DeviceService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ✅ User's devices list path
  static DatabaseReference get userDevicesRef =>
      _db.child('users').child(_uid).child('devices');

  // ✅ Global devices path (Cloud Functions read from here)
  static DatabaseReference get globalDevicesRef =>
      _db.child('devices');

  // ➕ ADD DEVICE
  static Future<String?> addDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      print("🔄 DeviceService: Adding device $deviceId");

      // 1️⃣ Check if device already exists in user's list (active or inactive)
      final existingSnapshot = await userDevicesRef.child(deviceId).get();

      if (existingSnapshot.exists) {
        final existingData = existingSnapshot.value as Map;
        final isActive = existingData['isActive'];

        if (isActive == false) {
          // ✅ Device was deactivated — REACTIVATE it
          print("🔄 DeviceService: Device was inactive, reactivating...");

          // Update user's device record
          await userDevicesRef.child(deviceId).update({
            'deviceId': deviceId,
            'deviceName': deviceName,
            'isActive': true,
            'reactivatedAt': ServerValue.timestamp,
          });

          // ✅ Also update global devices node (needed for Cloud Functions)
          await globalDevicesRef.child(deviceId).update({
            'deviceId': deviceId,
            'deviceName': deviceName,
            'isActive': true,
            'reactivatedAt': ServerValue.timestamp,
          });

          print("✅ DeviceService: Device reactivated in both paths");

          // Re-link FCM token
          final authController = AuthController();
          final error = await authController.linkDevice(deviceId: deviceId);

          if (error != null) {
            print("❌ DeviceService: Error linking device - $error");
            return error;
          }

          print("✅ DeviceService: Device re-linked with FCM token");
          return null; // Success
        } else {
          // Device is already active
          return "device_already_active";
        }
      }

      // 2️⃣ New device — save to USER's devices list
      await userDevicesRef.child(deviceId).set({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'createdAt': ServerValue.timestamp,
        'isActive': true,
      });
      print("✅ DeviceService: Saved to users/$_uid/devices/$deviceId");

      // 3️⃣ ✅ CRITICAL: Also save to GLOBAL devices node
      //    Cloud Functions read device name from here
      //    And tokens are stored under here too
      await globalDevicesRef.child(deviceId).update({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'isActive': true,
        'createdAt': ServerValue.timestamp,
      });
      print("✅ DeviceService: Saved to devices/$deviceId (global)");

      // 4️⃣ Link FCM token to the device
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

  // 📋 GET DEVICES (stream from user's list)
  static DatabaseReference getDevices() {
    return userDevicesRef;
  }

  // ✏️ UPDATE DEVICE
  static Future<String?> updateDevice({
    required String oldDeviceId,
    required String newDeviceId,
    required String deviceName,
  }) async {
    try {
      print("🔄 DeviceService: Updating device $oldDeviceId");

      final currentDevice = await userDevicesRef.child(oldDeviceId).get();
      final isActive = currentDevice.child('isActive').value ?? true;

      if (oldDeviceId != newDeviceId) {
        // Check if new ID already exists
        final snapshot = await userDevicesRef.child(newDeviceId).get();
        if (snapshot.exists) {
          return "Device with this ID already exists";
        }

        // Remove old from user's list
        await userDevicesRef.child(oldDeviceId).remove();

        // Remove old from global devices (tokens stay under old ID - leave them)
        // Only update name in global if same deviceId used in hardware

        // Create new in user's list
        await userDevicesRef.child(newDeviceId).set({
          'deviceId': newDeviceId,
          'deviceName': deviceName,
          'createdAt': ServerValue.timestamp,
          'isActive': isActive,
        });

        // ✅ Also update global devices node
        await globalDevicesRef.child(newDeviceId).update({
          'deviceId': newDeviceId,
          'deviceName': deviceName,
          'isActive': isActive,
        });
      } else {
        // Only update name in user's list
        await userDevicesRef.child(oldDeviceId).update({
          'deviceName': deviceName,
        });

        // ✅ Also update name in global devices node
        await globalDevicesRef.child(oldDeviceId).update({
          'deviceName': deviceName,
        });
      }

      print("✅ DeviceService: Device updated successfully");
      return null;
    } catch (e) {
      print("❌ DeviceService: Error updating device - $e");
      return e.toString();
    }
  }

  // 🗑️ DEACTIVATE DEVICE
  static Future<String?> deleteDevice({
    required String deviceId,
  }) async {
    try {
      print("🔄 DeviceService: Deactivating device $deviceId");

      // Mark inactive in user's list
      await userDevicesRef.child(deviceId).update({
        'isActive': false,
        'deactivatedAt': ServerValue.timestamp,
      });

      // ✅ Also mark inactive in global devices node
      await globalDevicesRef.child(deviceId).update({
        'isActive': false,
        'deactivatedAt': ServerValue.timestamp,
      });

      print("✅ DeviceService: Device marked as inactive in both paths");
      return null;
    } catch (e) {
      print("❌ DeviceService: Error deactivating device - $e");
      return e.toString();
    }
  }
}