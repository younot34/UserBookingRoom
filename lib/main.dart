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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uri = Uri.base;
        debugPrint("WEB DeepLink: $uri");
        if (uri.path == '/reset-password') {
          final token = uri.queryParameters['token'] ?? '';
          final email = uri.queryParameters['email'] ?? '';
          if (token.isNotEmpty && email.isNotEmpty) {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ResetPasswordPage(email: email, token: token),
                ),
              );
            }
          }
        }
      });
    } else {
      _sub = uriLinkStream.listen((Uri? uri) {
        debugPrint("MOBILE DeepLink: $uri");
        if (uri != null && uri.path == '/reset-password') {
          final token = uri.queryParameters['token'] ?? '';
          final email = uri.queryParameters['email'] ?? '';
          if (token.isNotEmpty && email.isNotEmpty) {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ResetPasswordPage(email: email, token: token),
                ),
              );
            }
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Booking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        if (uri.path == '/reset-password') {
          final token = uri.queryParameters['token'] ?? '';
          final email = uri.queryParameters['email'] ?? '';
          return MaterialPageRoute(
            builder: (_) => ResetPasswordPage(email: email, token: token),
          );
        }

        // default route → login
        return MaterialPageRoute(builder: (_) => const LoginPage());
      },
    );
  }
}