import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Inisialisasi FCM
  Future<void> initNotifications() async {
    await Firebase.initializeApp();

    // Minta izin notifikasi dari user
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Izin notifikasi diberikan");
      await _saveTokenToFirestore();

      // Listener untuk pesan saat aplikasi terbuka (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 Pesan diterima di foreground: ${message.notification?.title}");
        _showForegroundNotification(message);
      });

      // Listener jika user klik notifikasi dan membuka app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("🚀 User membuka app dari notifikasi: ${message.notification?.title}");
      });
    } else {
      print("❌ Izin notifikasi ditolak");
    }

    // Handler background (wajib static)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Simpan token user ke Firestore
  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print("🔑 Token FCM disimpan ke Firestore: $token");
      }
    } catch (e) {
      debugPrint("❌ Gagal menyimpan token FCM: $e");
    }
  }

  // Tampilkan notifikasi sederhana di foreground
  void _showForegroundNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? 'Pesan Baru';
    final body = message.notification?.body ?? 'Anda menerima notifikasi baru.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

// Handler untuk background message
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📨 Pesan diterima di background: ${message.notification?.title}");
}

// Global key agar kita bisa menampilkan snackbar dari service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
