import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceService {
  static final _db = FirebaseDatabase.instance.ref();

  static String get _uid =>
      FirebaseAuth.instance.currentUser!.uid;

  static DatabaseReference get userDevicesRef =>
      _db.child('users').child(_uid).child('devices');

  // ➕ Add device (USER SIDE ONLY)
  static Future<void> addDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    await userDevicesRef.child(deviceId).set({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'createdAt': ServerValue.timestamp,
    });
  }

  // 📡 Get user devices
  static DatabaseReference getDevices() {
    return userDevicesRef;
  }
}
