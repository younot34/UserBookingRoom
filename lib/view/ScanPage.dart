import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking.dart';
import 'RulesPage.dart';

class ScanPage extends StatefulWidget {
  final Booking booking;
  const ScanPage({super.key, required this.booking});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isEnglish = true;
  String get qrData {
    final info = widget.booking.scanInfo;
    if (info != null && info.isNotEmpty) {
      return info;
    } else {
      // fallback URL
      return isEnglish
          ? "https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf"
          : "https://drive.google.com/file/d/1JSHaTJ_0GXYE5pmshP029kSZIMJpFaPc/view?usp=sharing";
    }
  }


  void openRulesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RulesPage(isEnglish: isEnglish, booking: widget.booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Scan QR Code",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                isEnglish = !isEnglish;
              });
            },
            icon: Icon(
              isEnglish ? Icons.language : Icons.translate,
              color: Colors.black,
            ),
            label: const Text(
              "Translate",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Card(
          color: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR Code
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEnglish
                      ? "Scan QR to view meeting room rules"
                      : "Scan QR untuk melihat aturan ruang meeting",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: openRulesPage,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(isEnglish ? "Open Page" : "Buka Halaman"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}