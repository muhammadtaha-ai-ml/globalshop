import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:globalshop/notifications/fcm_service.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _devicesDb = FirebaseDatabase.instance.ref("devices");

  /// 🔐 EMAIL SIGNUP
  Future<String?> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCred.user!.sendEmailVerification();

      AppUser user = AppUser(
        uid: userCred.user!.uid,
        name: name,
        email: email,
        phone: phone,
      );

      await _db.child(user.uid).set(user.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔐 EMAIL LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return "Please verify your email first";
      }

      // ✅ Save token to ALL devices on every login
      await saveFCMTokenToDevices(cred.user!.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔐 GOOGLE SIGN-IN
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return "Google sign-in cancelled";
      }

      // 🛑 PRE-CHECK: Ensure the user has actually signed up in our app first.
      // This prevents Firebase Auth from auto-creating a user and instantly logging them in.
      final query = await _db.orderByChild('email').equalTo(googleUser.email).once();
      if (!query.snapshot.exists) {
        await googleSignIn.signOut();
        return "This Google account is not registered. Please sign up first.";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await _auth.signInWithCredential(credential);

      // 🛑 VERIFICATION CHECK
      if (!userCred.user!.emailVerified) {
        await _auth.signOut();
        await googleSignIn.signOut();
        return "Please verify your email first before logging in.";
      }

      final uid = userCred.user!.uid;

      // We already checked the DB above, no need to check again.
      await saveFCMTokenToDevices(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔔 SAVE FCM TOKEN TO ALL LINKED DEVICES
  /// Called on login — updates token for every device user has
  Future<void> saveFCMTokenToDevices(String uid) async {
    try {
      print("🔄 saveFCMTokenToDevices: Starting for uid=$uid");

      // ✅ Get token with retry
      String? token = await FCMService.getToken();
      if (token == null || token.isEmpty) {
        print("⚠️ Token null on first try, refreshing...");
        await Future.delayed(const Duration(seconds: 1));
        token = await FCMService.refreshAndGetToken();
      }

      if (token == null || token.isEmpty) {
        print("❌ saveFCMTokenToDevices: Could not get FCM token");
        return;
      }

      print("✅ Token obtained: ${token.substring(0, 20)}...");

      // Save token in user record
      await _db.child(uid).child('fcmToken').set(token);
      print("✅ Token saved: users/$uid/fcmToken");

      // Get all devices linked to this user
      final devicesSnap = await _db.child(uid).child('devices').get();
      if (!devicesSnap.exists || devicesSnap.value == null) {
        print("ℹ️ No devices linked to user: $uid");
        return;
      }

      final Map<dynamic, dynamic> devices =
          devicesSnap.value as Map<dynamic, dynamic>;

      int savedCount = 0;
      for (final entry in devices.entries) {
        final deviceId = entry.key.toString();
        final deviceData = entry.value;

        // Skip inactive devices
        if (deviceData is Map && deviceData['isActive'] == false) {
          print("⏭️ Skipping inactive device: $deviceId");
          continue;
        }

        // ✅ Save token under global devices/{deviceId}/tokens/{uid}
        // This is where Cloud Functions read from
        await _devicesDb
            .child(deviceId)
            .child('tokens')
            .child(uid)
            .set(token);

        savedCount++;
        print("✅ Token saved: devices/$deviceId/tokens/$uid");
      }

      print("✅ saveFCMTokenToDevices: Done. Saved for $savedCount device(s)");
    } catch (e) {
      print("❌ Error in saveFCMTokenToDevices: $e");
    }
  }

  /// 📱 LINK A DEVICE & SAVE FCM TOKEN
  /// Called when user adds a new device
  Future<String?> linkDevice({required String deviceId}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "User not logged in";

      print("🔄 linkDevice: Linking device $deviceId for uid=$uid");

      // ✅ FIXED: Check global devices node (not user's list)
      // DeviceService already saved to devices/{deviceId} before calling this
      final deviceSnap = await _devicesDb.child(deviceId).get();
      if (!deviceSnap.exists) {
        // ✅ This shouldn't happen since DeviceService saves first
        // but if it does, we create the entry
        print("⚠️ linkDevice: Device not in global node, creating...");
        await _devicesDb.child(deviceId).update({
          'deviceId': deviceId,
          'isActive': true,
        });
      }

      // ✅ Get FCM token with retry logic
      print("🔄 linkDevice: Getting FCM token...");
      String? token = await FCMService.getToken();

      if (token == null || token.isEmpty) {
        print("⚠️ linkDevice: Token null, waiting 1s and retrying...");
        await Future.delayed(const Duration(seconds: 1));
        token = await FCMService.getToken();
      }

      if (token == null || token.isEmpty) {
        print("⚠️ linkDevice: Still null, forcing refresh...");
        token = await FCMService.refreshAndGetToken();
      }

      if (token == null || token.isEmpty) {
        print("❌ linkDevice: Could not get FCM token after all retries");
        // ✅ Don't fail completely — device is added, token will update on next login
        return null;
      }

      print("✅ linkDevice: Token ready: ${token.substring(0, 20)}...");

      // ✅ Save token under global devices/{deviceId}/tokens/{uid}
      await _devicesDb
          .child(deviceId)
          .child('tokens')
          .child(uid)
          .set(token);
      print("✅ linkDevice: Token saved at devices/$deviceId/tokens/$uid");

      // ✅ Also update user's fcmToken record
      await _db.child(uid).child('fcmToken').set(token);
      print("✅ linkDevice: Token saved at users/$uid/fcmToken");

      return null; // Success
    } catch (e) {
      print("❌ CRITICAL ERROR in linkDevice: $e");
      return e.toString();
    }
  }

  /// 🔓 UNLINK A DEVICE
  Future<String?> unlinkDevice({required String deviceId}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "User not logged in";

      // Remove from user's list
      await _db.child(uid).child('devices').child(deviceId).remove();

      // Remove token from global devices
      await _devicesDb.child(deviceId).child('tokens').child(uid).remove();

      print("✅ Device unlinked: $deviceId");
      return null;
    } catch (e) {
      print("❌ Error unlinking device: $e");
      return e.toString();
    }
  }

  /// 🔁 RESET PASSWORD
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}