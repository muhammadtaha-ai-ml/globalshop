import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔑 Auth State Changes Stream Provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 👤 Current Authenticated User Stream Provider
final userStreamProvider = StreamProvider<Map<dynamic, dynamic>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value({});
  return FirebaseDatabase.instance.ref('users').child(uid).onValue.map((event) {
    return (event.snapshot.value as Map? ?? {});
  });
});

/// 📱 Linked Devices Stream Provider
final devicesStreamProvider = StreamProvider<Map<dynamic, dynamic>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value({});
  return FirebaseDatabase.instance.ref('users').child(uid).child('devices').onValue.map((event) {
    return (event.snapshot.value as Map? ?? {});
  });
});

/// 🔔 Unread Notifications Count Stream Provider
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);
  return FirebaseDatabase.instance.ref('users').child(uid).child('notifications').onValue.map((event) {
    if (!event.snapshot.exists || event.snapshot.value == null) return 0;
    final Map all = event.snapshot.value as Map;
    int count = 0;
    all.forEach((key, value) {
      if (value is Map && value['isRead'] == false) {
        count++;
      }
    });
    return count;
  });
});

/// 📋 Sorted Alerts & Notifications Stream Provider
final notificationsStreamProvider = StreamProvider<List<Map<dynamic, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseDatabase.instance.ref('users').child(uid).child('notifications').orderByChild('timestamp').onValue.map((event) {
    if (!event.snapshot.exists || event.snapshot.value == null) return [];
    final Map rawData = event.snapshot.value as Map;
    final List<Map<dynamic, dynamic>> list = [];
    rawData.forEach((key, value) {
      if (value is Map) {
        list.add(value);
      }
    });
    list.sort((a, b) {
      final int tA = a['timestamp'] ?? 0;
      final int tB = b['timestamp'] ?? 0;
      return tB.compareTo(tA);
    });
    return list;
  });
});

/// 🌐 Firebase Connection Status Provider
final databaseConnectionProvider = StreamProvider<bool>((ref) {
  return FirebaseDatabase.instance.ref('.info/connected').onValue.map((event) {
    return event.snapshot.value as bool? ?? false;
  });
});

/// 🌗 Theme Mode State Provider with Persistence (Light / Dark)
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initial) : super(initial);

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ThemeMode.light),
);
