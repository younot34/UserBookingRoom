import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null &&
          userCredential.user!.email == "admin@gmail.com") {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: "blocked-user",
          message: "Email ini tidak diperbolehkan login.",
        );
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.message}");
      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
  static User? get currentUser => _auth.currentUser;
}
