import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ScheduleService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Database References
  static DatabaseReference userScheduleRef(String deviceId) => _db
      .child('users')
      .child(_uid)
      .child('devices')
      .child(deviceId)
      .child('schedules')
      .child('senseTimes');

  static DatabaseReference deviceScheduleRef(String deviceId) => _db
      .child('devices')
      .child(deviceId)
      .child('schedules')
      .child('senseTimes');

  // 💾 SAVE SCHEDULE (Multiple users ke times merge honge)
  static Future<void> saveSchedules({
    required String deviceId,
    required List<String> times,
  }) async {
    // Step 1: Device se existing times load karo
    final snapshot = await deviceScheduleRef(deviceId).get();
    
    List<String> existingTimes = [];
    
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      
      if (data is List) {
        existingTimes = data
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      } else if (data is Map) {
        existingTimes = data.values
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Step 2: Current user ke purane times nikalo
    final userSnapshot = await userScheduleRef(deviceId).get();
    List<String> userOldTimes = [];
    
    if (userSnapshot.exists && userSnapshot.value != null) {
      final userData = userSnapshot.value;
      
      if (userData is List) {
        userOldTimes = userData
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      } else if (userData is Map) {
        userOldTimes = userData.values
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Step 3: Existing times se current user ke purane times remove karo
    existingTimes.removeWhere((time) => userOldTimes.contains(time));

    // Step 4: Naye times ko existing times ke saath merge karo
    final allTimes = [...existingTimes, ...times];
    
    // Step 5: Duplicates remove karo
    final uniqueTimes = allTimes.toSet().toList();

    // Step 6: Device data prepare karo
    final Map<String, String> deviceData = {};
    for (int i = 0; i < uniqueTimes.length; i++) {
      deviceData[i.toString()] = uniqueTimes[i];
    }

    // Step 7: User data prepare karo
    final Map<String, String> userData = {};
    for (int i = 0; i < times.length; i++) {
      userData[i.toString()] = times[i];
    }

    // Step 8: Save karo
    await userScheduleRef(deviceId).set(userData);
    await deviceScheduleRef(deviceId).set(deviceData);
  }

  // 📥 LOAD USER'S SCHEDULES (Sirf current user ke times)
  static Future<List<String>> loadUserSchedules(String deviceId) async {
    final snapshot = await userScheduleRef(deviceId).get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value;

    if (data is List) {
      return data
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    if (data is Map) {
      return data.values
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    return [];
  }

  // 📥 LOAD ALL DEVICE SCHEDULES (Sabke combined times)
  static Future<List<String>> loadAllDeviceSchedules(String deviceId) async {
    final snapshot = await deviceScheduleRef(deviceId).get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value;

    if (data is List) {
      return data
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    if (data is Map) {
      return data.values
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    return [];
  }

  // 🗑️ DELETE USER'S SCHEDULES FROM DEVICE
  static Future<void> deleteUserSchedulesFromDevice({
    required String deviceId,
    required List<String> timesToDelete,
  }) async {
    final snapshot = await deviceScheduleRef(deviceId).get();
    
    if (!snapshot.exists || snapshot.value == null) return;

    List<String> allTimes = [];
    final data = snapshot.value;
    
    if (data is List) {
      allTimes = data
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    } else if (data is Map) {
      allTimes = data.values
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    // User ke times remove karo
    allTimes.removeWhere((time) => timesToDelete.contains(time));

    if (allTimes.isEmpty) {
      // Agar koi time nahi bacha to node delete kar do
      await deviceScheduleRef(deviceId).remove();
      return;
    }

    // Updated list save karo
    final Map<String, String> newData = {};
    for (int i = 0; i < allTimes.length; i++) {
      newData[i.toString()] = allTimes[i];
    }

    await deviceScheduleRef(deviceId).set(newData);
  }

  // 🗑️ DELETE ALL USER SCHEDULES (User node + device node dono se)
  static Future<void> deleteAllUserSchedules(String deviceId) async {
    // Pehle user ke times nikalo
    final userTimes = await loadUserSchedules(deviceId);

    if (userTimes.isNotEmpty) {
      // Device se bhi remove karo
      await deleteUserSchedulesFromDevice(
        deviceId: deviceId,
        timesToDelete: userTimes,
      );
    }

    // User node se delete karo
    await userScheduleRef(deviceId).remove();
  }
}