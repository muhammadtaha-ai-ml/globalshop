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

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await _auth.signInWithCredential(credential);

      final uid = userCred.user!.uid;

      final snapshot = await _db.child(uid).get();
      if (!snapshot.exists) {
        await _auth.signOut();
        await googleSignIn.signOut();
        return "This Google account is not registered. Please sign up first.";
      }

      await saveFCMTokenToDevices(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔔 SAVE FCM TOKEN TO ALL DEVICES
  Future<void> saveFCMTokenToDevices(String uid) async {
    try {
      final token = await FCMService.getToken();
      if (token == null || token.isEmpty) {
        print("⚠️ FCM token is null or empty, skipping save");
        return;
      }

      await _db.child(uid).child('fcmToken').set(token);
      print("✅ Token saved in user record: users/$uid/fcmToken");

      final devicesSnap = await _db.child(uid).child('devices').get();
      if (!devicesSnap.exists) {
        print("ℹ️ No devices linked to user: $uid");
        return;
      }

      final devicesData = devicesSnap.value;
      if (devicesData == null) return;

      final Map<dynamic, dynamic> devices =
          devicesData as Map<dynamic, dynamic>;

      for (final deviceId in devices.keys) {
        await _devicesDb
            .child(deviceId.toString())
            .child('tokens')
            .child(uid)
            .set(token);

        print("✅ Token saved: devices/$deviceId/tokens/$uid");
      }
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  /// 📱 LINK A DEVICE TO THE CURRENT USER
  ///
  /// ✅✅ FIXED: Doesn't overwrite device info
  Future<String?> linkDevice({required String deviceId}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "User not logged in";

      print("🔄 Starting device link process for: $deviceId");

      // 1️⃣ Check if device exists in global devices database
      final deviceSnap = await _devicesDb.child(deviceId).get();
      if (!deviceSnap.exists) {
        return "Device not found. Please check the device ID.";
      }

      // 2️⃣ ✅ Verify device info exists (already saved by DeviceService)
      final userDeviceSnap = await _db.child(uid).child('devices').child(deviceId).get();
      if (!userDeviceSnap.exists) {
        print("⚠️ Warning: Device info not found in user record");
      } else {
        print("✅ Device already linked to user: users/$uid/devices/$deviceId");
      }

      // 3️⃣ ✅ Get FCM token
      print("🔄 Fetching FCM token...");
      String? token = await FCMService.getToken();

      if (token == null || token.isEmpty) {
        print("⚠️ First attempt: Token is null, trying to refresh...");
        await Future.delayed(const Duration(milliseconds: 500));
        token = await FCMService.refreshAndGetToken();
      }

      if (token == null || token.isEmpty) {
        print("❌ ERROR: FCM token is STILL null after refresh attempt!");
        return "Device linked but notifications may not work. Please restart the app.";
      }

      print("✅ Token fetched successfully: ${token.substring(0, 20)}...");

      // 4️⃣ ✅ Save token IMMEDIATELY
      await _devicesDb
          .child(deviceId)
          .child('tokens')
          .child(uid)
          .set(token);

      print("✅✅ TOKEN SAVED IMMEDIATELY: devices/$deviceId/tokens/$uid");
      print("   Full token length: ${token.length} characters");

      // 5️⃣ Update user's main fcmToken
      await _db.child(uid).child('fcmToken').set(token);
      print("✅ Token also saved in user record: users/$uid/fcmToken");

      return null;
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

      await _db.child(uid).child('devices').child(deviceId).remove();
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