import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

import 'auth/login.dart';
import 'auth/ResetPasswordPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandler();
  }

  void _initDeepLinkHandler() {
    if (kIsWeb) {
      // --- Web: ambil token/email dari Uri.base
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uri = Uri.base;
        if (uri.path == '/reset-password') {
          final token = uri.queryParameters['token'] ?? '';
          final email = uri.queryParameters['email'] ?? '';
          if (token.isNotEmpty && email.isNotEmpty) {
            Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => ResetPasswordPage(email: email, token: token),
              ),
            );
          }
        }
      });
    } else {
      // --- Mobile: pakai uni_links
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null && uri.path == '/reset-password') {
          final token = uri.queryParameters['token'] ?? '';
          final email = uri.queryParameters['email'] ?? '';
          if (token.isNotEmpty && email.isNotEmpty) {
            Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => ResetPasswordPage(email: email, token: token),
              ),
            );
          }
        }
      }, onError: (err) {
        debugPrint('Deep link error: $err');
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Booking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}