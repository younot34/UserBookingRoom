import 'package:flutter/material.dart';
import '../../models/booking.dart';

class RulesPage extends StatelessWidget {
  final bool isEnglish;
  final Booking? booking;

  const RulesPage({super.key, required this.isEnglish, this.booking});

  @override
  Widget build(BuildContext context) {
    final List<String> defaultRules = isEnglish
        ? [
      ""
    ]
        : [
      ""
    ];

    final String rulesFromBooking = booking?.scanInfo ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? "Room Rules" : "Aturan Ruang"),
        backgroundColor: Colors.white38,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEnglish ? "📌 Room Rules" : "📌 Aturan Ruang",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Tampilkan aturan dari booking jika ada, kalau kosong pakai default
              if (rulesFromBooking.isNotEmpty)
                Text(
                  rulesFromBooking,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                )
              else ...defaultRules.map((rule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(rule, style: const TextStyle(fontSize: 18)),
              )),

              const SizedBox(height: 24),
              Text(
                isEnglish ? "Thank you 🙏" : "Terima kasih 🙏",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}
