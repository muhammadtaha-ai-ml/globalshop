import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static DatabaseReference get userDevicesRef =>
      _db.child('users').child(_uid).child('devices');
 
  // ➕ ADD DEVICE
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

  // 📋 GET DEVICES
  static DatabaseReference getDevices() {
    return userDevicesRef;
  }
}
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';

// class DeviceService {
//   static final DatabaseReference _db = FirebaseDatabase.instance.ref();

//   static String get _uid => FirebaseAuth.instance.currentUser!.uid;

//   static DatabaseReference get userDevicesRef =>
//       _db.child('users').child(_uid).child('devices');

//   static DatabaseReference userScheduleRef(String deviceId) =>
//       userDevicesRef.child(deviceId).child('schedules').child('senseTimes');

//   static DatabaseReference deviceScheduleRef(String deviceId) => _db
//       .child('devices')
//       .child(deviceId)
//       .child('schedules')
//       .child('senseTimes');
 
//   // ➕ ADD DEVICE
//   static Future<void> addDevice({
//     required String deviceId,
//     required String deviceName,
//   }) async {
//     await userDevicesRef.child(deviceId).set({
//       'deviceId': deviceId,
//       'deviceName': deviceName,
//       'createdAt': ServerValue.timestamp,
//     });
//   }

//   static DatabaseReference getDevices() {
//     return userDevicesRef;
//   }

//   // 💾 SAVE SCHEDULE (UPDATED - Ab purane data ke saath merge hoga)
//   static Future<void> saveSchedules({
//     required String deviceId,
//     required List<String> times,
//   }) async {
//     // Pehle device se existing times load karo
//     final snapshot = await deviceScheduleRef(deviceId).get();
    
//     List<String> existingTimes = [];
    
//     if (snapshot.exists && snapshot.value != null) {
//       final data = snapshot.value;
      
//       if (data is List) {
//         existingTimes = data.where((e) => e != null).map((e) => e.toString()).toList();
//       } else if (data is Map) {
//         existingTimes = data.values
//             .where((e) => e != null)
//             .map((e) => e.toString())
//             .toList();
//       }
//     }

//     // Naye times ko existing times ke saath merge karo
//     final allTimes = [...existingTimes, ...times];
    
//     // Duplicates remove karo (optional)
//     final uniqueTimes = allTimes.toSet().toList();

//     // Map mein convert karo for Firebase
//     final Map<String, String> data = {};
//     for (int i = 0; i < uniqueTimes.length; i++) {
//       data[i.toString()] = uniqueTimes[i];
//     }

//     // User ke schedule mein save karo
//     await userScheduleRef(deviceId).set({
//       for (int i = 0; i < times.length; i++)
//         i.toString(): times[i]
//     });
    
//     // Device ke schedule mein merge karke save karo
//     await deviceScheduleRef(deviceId).set(data);
//   }

//   // 📥 LOAD SCHEDULE (User-specific)
//   static Future<List<String>> loadSchedules(String deviceId) async {
//     final snapshot = await userScheduleRef(deviceId).get();

//     if (!snapshot.exists || snapshot.value == null) return [];

//     final data = snapshot.value;

//     // ✅ CASE 1: Firebase returns LIST
//     if (data is List) {
//       return data.where((e) => e != null).map((e) => e.toString()).toList();
//     }

//     // ✅ CASE 2: Firebase returns MAP
//     if (data is Map) {
//       return data.values
//           .where((e) => e != null)
//           .map((e) => e.toString())
//           .toList();
//     }

//     return [];
//   }

//   // 📥 LOAD ALL SCHEDULES FROM DEVICE (Sabke combined times)
//   static Future<List<String>> loadAllDeviceSchedules(String deviceId) async {
//     final snapshot = await deviceScheduleRef(deviceId).get();

//     if (!snapshot.exists || snapshot.value == null) return [];

//     final data = snapshot.value;

//     if (data is List) {
//       return data.where((e) => e != null).map((e) => e.toString()).toList();
//     }

//     if (data is Map) {
//       return data.values
//           .where((e) => e != null)
//           .map((e) => e.toString())
//           .toList();
//     }

//     return [];
//   }

//   // 🗑️ DELETE USER'S SCHEDULES FROM DEVICE
//   static Future<void> deleteUserSchedules({
//     required String deviceId,
//     required List<String> timesToDelete,
//   }) async {
//     final snapshot = await deviceScheduleRef(deviceId).get();
    
//     if (!snapshot.exists || snapshot.value == null) return;

//     List<String> allTimes = [];
//     final data = snapshot.value;
    
//     if (data is List) {
//       allTimes = data.where((e) => e != null).map((e) => e.toString()).toList();
//     } else if (data is Map) {
//       allTimes = data.values
//           .where((e) => e != null)
//           .map((e) => e.toString())
//           .toList();
//     }

//     // Remove user's times
//     allTimes.removeWhere((time) => timesToDelete.contains(time));

//     // Save updated list
//     final Map<String, String> newData = {};
//     for (int i = 0; i < allTimes.length; i++) {
//       newData[i.toString()] = allTimes[i];
//     }

//     await deviceScheduleRef(deviceId).set(newData);
//   }
// }

