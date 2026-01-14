import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref("users");

  // 🔐 SIGNUP + EMAIL VERIFICATION
  Future<String?> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String deviceId,
  }) async {
    try {
      UserCredential userCred =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 📩 SEND VERIFICATION EMAIL
      await userCred.user!.sendEmailVerification();

      AppUser user = AppUser(
        uid: userCred.user!.uid,
        name: name,
        email: email,
        phone: phone,
        deviceId: deviceId,
      );

      await _db.child(user.uid).set(user.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 🔐 LOGIN (ONLY VERIFIED EMAIL)
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return "Please verify your email first";
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
