import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:globalshop/notifications/fcm_service.dart';

/// 🔧 ONE-TIME MIGRATION HELPER
/// 
/// Run this ONCE to fix the old token structure.
/// 
/// OLD (WRONG):
///   /devices/{deviceId}/tokens: "single_token_string"
/// 
/// NEW (CORRECT):
///   /devices/{deviceId}/tokens/
///     uid1: "token1"
///     uid2: "token2"
/// 
/// HOW TO USE:
/// 1. Add this file to your project
/// 2. Import it in main.dart or any screen
/// 3. Call: await TokenMigrationHelper.migrateTokenStructure();
/// 4. Delete this file after migration is complete
class TokenMigrationHelper {
  
  static Future<void> migrateTokenStructure() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ Migration: User not logged in");
        return;
      }

      final uid = user.uid;
      final db = FirebaseDatabase.instance.ref();

      print("🔄 Starting token migration for user: $uid");

      // 1️⃣ Get current FCM token
      final token = await FCMService.getToken();
      if (token == null || token.isEmpty) {
        print("❌ Migration: Could not get FCM token");
        return;
      }

      // 2️⃣ Get all devices linked to this user
      final devicesSnap = await db
          .child('users')
          .child(uid)
          .child('devices')
          .get();

      if (!devicesSnap.exists) {
        print("ℹ️ Migration: No devices found for user");
        return;
      }

      final devicesData = devicesSnap.value;
      if (devicesData == null) return;

      final Map<dynamic, dynamic> devices = 
          devicesData as Map<dynamic, dynamic>;

      print("📱 Found ${devices.length} device(s) to migrate");

      // 3️⃣ For each device, fix the token structure
      for (final deviceId in devices.keys) {
        final deviceIdStr = deviceId.toString();
        
        // Check current token structure
        final tokensRef = db.child('devices').child(deviceIdStr).child('tokens');
        final tokensSnap = await tokensRef.get();

        if (tokensSnap.exists) {
          final tokensData = tokensSnap.value;
          
          // If it's a STRING, that's the old structure - needs migration
          if (tokensData is String) {
            print("⚠️ Device $deviceIdStr has OLD structure (string token)");
            print("   Converting to new object structure...");
            
            // Remove the old string token
            await tokensRef.remove();
            
            // Save as proper object structure
            await tokensRef.child(uid).set(token);
            
            print("   ✅ Migrated to: devices/$deviceIdStr/tokens/$uid");
          } 
          // If it's already an object/map, check if this user's token exists
          else if (tokensData is Map) {
            print("✅ Device $deviceIdStr already has correct structure");
            
            // Just update/add this user's token
            await tokensRef.child(uid).set(token);
            print("   ✅ Updated token for uid: $uid");
          }
        } else {
          // No tokens at all, create fresh
          print("➕ Device $deviceIdStr has no tokens, creating new...");
          await tokensRef.child(uid).set(token);
          print("   ✅ Created: devices/$deviceIdStr/tokens/$uid");
        }
      }

      print("");
      print("✅✅✅ MIGRATION COMPLETE ✅✅✅");
      print("Total devices processed: ${devices.length}");
      print("You can now delete this migration file.");
      
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }

  /// Alternative: Migrate specific device only
  static Future<void> migrateDevice(String deviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ User not logged in");
        return;
      }

      final uid = user.uid;
      final token = await FCMService.getToken();
      if (token == null || token.isEmpty) {
        print("❌ Could not get FCM token");
        return;
      }

      final db = FirebaseDatabase.instance.ref();
      final tokensRef = db.child('devices').child(deviceId).child('tokens');
      final tokensSnap = await tokensRef.get();

      if (tokensSnap.exists && tokensSnap.value is String) {
        // Old structure
        await tokensRef.remove();
        await tokensRef.child(uid).set(token);
        print("✅ Device $deviceId migrated");
      } else {
        // New structure or doesn't exist
        await tokensRef.child(uid).set(token);
        print("✅ Token saved for device $deviceId");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }
} 