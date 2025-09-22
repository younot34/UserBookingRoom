import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordPage({super.key, required this.email, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;

  Future<void> _resetPassword() async {
    setState(() => loading = true);

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/reset-password"),
      headers: ApiConfig.headers,
      body: jsonEncode({
        "email": widget.email,
        "token": widget.token,
        "password": passwordController.text.trim(),
        "password_confirmation": confirmController.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password berhasil diubah")),
      );
      Navigator.pop(context); // kembali ke halaman login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal reset password: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Konfirmasi Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _resetPassword,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}
