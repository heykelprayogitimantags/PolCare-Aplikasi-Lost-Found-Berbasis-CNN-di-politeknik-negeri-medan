import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 🔹 Daftar akun baru
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Buat akun Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil FCM token device pengguna
      String? token = await _messaging.getToken();

      // Simpan data pengguna di Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'fcmToken': token, // 🔥 simpan token
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  /// 🔹 Login pengguna
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Perbarui FCM token saat user login
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(cred.user!.uid).update({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  /// 🔹 Logout pengguna
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 🔹 Ambil user aktif
  User? get currentUser => _auth.currentUser;

  /// 🔹 Tangani error FirebaseAuth
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      default:
        return 'Terjadi kesalahan (${e.message}).';
    }
  }
}
