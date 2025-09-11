import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/device_service.dart';
import 'HomePage.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  _ReportingPageState createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final DeviceFirestoreService deviceService = DeviceFirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Device> devices = [];
  List<String> allRooms = [];

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  Future<void> loadDevices() async {
    final devices = await deviceService.getDevices();
    devices.sort((a, b) {
      final regex = RegExp(r'(\d+)');
      final na = int.tryParse(regex.firstMatch(a.roomName)?.group(0) ?? "0") ?? 0;
      final nb = int.tryParse(regex.firstMatch(b.roomName)?.group(0) ?? "0") ?? 0;
      return na.compareTo(nb);
    });
    setState(() {
      this.devices = devices;
      allRooms = devices.map((d) => d.roomName).toList();
    });
  }
  void _showProfileDialog() {
    final currentUser = _auth.currentUser;
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("👤 Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Email: ${currentUser?.email ?? "Unknown"}"),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                  "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Password fields cannot be empty")),
                  );
                  return;
                }
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Passwords do not match")),
                  );
                  return;
                }

                try {
                  await currentUser?.updatePassword(newPassword);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Password updated")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("⚠️ Error: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF168757)),
              child: const Text("Update", style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Booking Room",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF168757),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          Row(
            children: [
              Text(
                _auth.currentUser?.email ?? "",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: _showProfileDialog,
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: allRooms.length,
        itemBuilder: (context, index) {
          final room = allRooms[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF168757),
                child: Icon(Icons.meeting_room, color: Colors.white),
              ),
              title: Text(
                room,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(roomName: room),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}