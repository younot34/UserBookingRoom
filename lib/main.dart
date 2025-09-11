import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user/auth/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // 🔹 konfigurasi Firebase Web
    await Firebase.initializeApp(
      options:
      const FirebaseOptions(
        apiKey: "AIzaSyDBM3JRHlreKsFsYJQtgRtL4KZv2xbh5lk",
        authDomain: "meet-d8070.firebaseapp.com",
        projectId: "meet-d8070",
        storageBucket: "meet-d8070.appspot.com",
        messagingSenderId: "708303731331",
        appId: "1:708303731331:web:b619717cbe421f6013f9b6",
        measurementId: "G-HGW2PK6JG3",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Booking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}