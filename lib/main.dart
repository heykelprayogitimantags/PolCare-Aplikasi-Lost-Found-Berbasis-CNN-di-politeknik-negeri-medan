import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_wrapper.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.initNotifications();
  await initializeDateFormatting('id_ID', null);

  runApp(const PolmedCareApp());
}

class PolmedCareApp extends StatelessWidget {
  const PolmedCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // <=== ini penting!
      debugShowCheckedModeBanner: false,
      title: 'PolmedCare',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const AuthWrapper(),
    );
  }
}
