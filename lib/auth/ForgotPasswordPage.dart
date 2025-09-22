import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;

  Future<void> _sendResetLink() async {
    setState(() => loading = true);
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/forgot-password"),
      headers: ApiConfig.headers,
      body: jsonEncode({"email": emailController.text.trim()}),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link reset password dikirim ke email")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal kirim reset password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Masukkan Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _sendResetLink,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Kirim Link Reset"),
            ),
          ],
        ),
      ),
    );
  }
}
