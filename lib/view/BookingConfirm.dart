
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingConfirmationPage extends StatelessWidget {
  final Booking booking;
  const BookingConfirmationPage({super.key, required this.booking});

  Future<void> _handleConfirm(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color(0xFF168757),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 16),
                // Optional text
                Text(
                  "Saving booking...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    try {
      await BookingService().saveBooking(booking);
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("successfully")),
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed to save: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoItems = <Map<String, dynamic>>[
      {"icon": Icons.meeting_room, "title": "Room", "value": booking.roomName},
      {"icon": Icons.calendar_today, "title": "Date", "value": booking.date},
      {
        "icon": Icons.access_time,
        "title": "Time & Duration",
        "value": booking.duration != null
            ? "${booking.time} • ${booking.duration} minutes"
            : booking.time
      },
      if (booking.numberOfPeople != null)
        {
          "icon": Icons.people,
          "title": "Attendees",
          "value": "${booking.numberOfPeople} people"
        },
      if (booking.equipment.isNotEmpty)
        {
          "icon": Icons.devices,
          "title": "Equipment",
          "value": booking.equipment.join(", ")
        },
      {"icon": Icons.person, "title": "Host Name", "value": booking.hostName},
      {"icon": Icons.title, "title": "Meeting Title", "value": booking.meetingTitle},
      {
        "icon": Icons.qr_code_scanner,
        "title": "Scan Me Status",
        "value": booking.isScanEnabled ? "Enabled" : "Disabled"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF168757),
      appBar: AppBar(
        title: const Text(
          'Booking Confirmation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF168757),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Review Your Booking",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF168757),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // hitung aspect ratio berdasarkan lebar available
                  final itemWidth = (constraints.maxWidth / 2) - 10;
                  final itemHeight = 80.0; // tinggi default card
                  final aspectRatio = itemWidth / itemHeight;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: infoItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final item = infoItems[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: Row(
                            children: [
                              Icon(item['icon'], color: const Color(0xFF168757), size: 26),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AutoSizeText(
                                      item['title'],
                                      maxLines: 1,
                                      minFontSize: 12,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AutoSizeText(
                                      item['value'],
                                      maxLines: 1,
                                      minFontSize: 10,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF168757),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                onPressed: () {
                  _handleConfirm(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}