import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/device_service.dart';
import 'package:intl/intl.dart';

import 'RoomDetail.dart';
import 'ScanPage.dart';

class HomePage extends StatefulWidget {
  final String roomName;
  const HomePage({super.key, required this.roomName});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isScanEnabled = false;
  bool isAvailable = true;
  late Timer _timer;
  late StreamSubscription _bookingSubscription;
  DateTime _currentTime = DateTime.now();
  List<Booking> bookings = [];
  final GlobalKey _leftCardKey = GlobalKey();
  double _leftCardHeight = 0;
  double buttonWidth = 220;
  int _logoTapCount = 0;
  Timer? _tapResetTimer;
  final BookingService bookingService = BookingService();
  String deviceLocation = "Loading...";
  final DeviceFirestoreService deviceService = DeviceFirestoreService();
  Map<String, String> roomLocations = {};

  Route<T> _noAnimationRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  bool get isMeetNowAllowed {
    for (var b in bookings) {
      final parts = b.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final start = DateTime(
        int.parse(b.date.split('/')[2]),
        int.parse(b.date.split('/')[1]),
        int.parse(b.date.split('/')[0]),
        hour,
        minute,
      );
      final diff = start.difference(_currentTime).inMinutes;
      if (diff > 0 && diff < 35) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _listenBookings();
    _fetchDeviceLocation();
    _fetchDeviceLocationByRoom(widget.roomName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLeftCardHeight();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _updateAvailability();
        _updateBookingStatus();
      });
    });
  }

  Future<void> _fetchDeviceLocationByRoom(String roomName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('roomName', isEqualTo: roomName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final location = data['location'] as String?;
      setState(() {
        deviceLocation = location ?? 'Unknown';
        // update lokasi di semua booking yang sesuai
        for (var b in bookings) {
          if (b.roomName == roomName) {
            b.location = deviceLocation;
          }
        }
      });
    } else {
      setState(() {
        deviceLocation = 'Unknown';
      });
    }
  }

  void _listenBookings() {
    bookings = [];
    _bookingSubscription = bookingService
        .streamBookingsByRoom(widget.roomName)
        .listen((list) {
      for (var b in list) {
        b.location = roomLocations[b.roomName];
      }
      setState(() {
        bookings = list;
        _updateAvailability();
      });
    });
  }

  Future<void> _fetchDeviceLocation() async {
    final location = await deviceService.getLocation(widget.roomName);
    setState(() {
      deviceLocation = location;
    });
  }

  Future<void> _editBooking(Booking booking) async {
    final result = await Navigator.push<Booking>(
      context,
      _noAnimationRoute(
        RoomDetailPage(
          roomName: widget.roomName,
          existingBookings: bookings,
          isMeetNow: false,
          meetNowDate: null,
          bookingToEdit: booking,
        ),
      ),
    );

    if (result != null) {
      final updated = await bookingService.updateBooking(result);
      setState(() {
        final index = bookings.indexWhere((b) => b.id == updated.id);
        if (index != -1) {
          bookings[index] = updated; // replace booking lama
        }
      });
      Fluttertoast.showToast(msg: "Booking updated");
    }
  }

  void _updateLeftCardHeight() {
    final ctx = _leftCardKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox;
      setState(() {
        _leftCardHeight = box.size.height;
      });
    }
  }

  String formatBookingTime(String startTime, String date, String? duration) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final start = DateTime(
      int.parse(date.split('/')[2]),
      int.parse(date.split('/')[1]),
      int.parse(date.split('/')[0]),
      hour,
      minute,
    );
    final dur = int.tryParse(duration ?? '30') ?? 30;
    final end = start.add(Duration(minutes: dur));

    final formatter = DateFormat("HH:mm");
    return "${formatter.format(start)}-${formatter.format(end)} | ${dur}m";
  }

  void _updateAvailability() {
    isAvailable = true;
    for (var b in bookings) {
      final parts = b.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final start = DateTime(
        int.parse(b.date.split('/')[2]),
        int.parse(b.date.split('/')[1]),
        int.parse(b.date.split('/')[0]),
        hour,
        minute,
      );
      final dur = int.tryParse(b.duration ?? '30') ?? 30;
      final end = start.add(Duration(minutes: dur));
      if (_currentTime.isAfter(start) && _currentTime.isBefore(end)) {
        isAvailable = false;
        break;
      }
    }
  }

  void _updateBookingStatus() async {
    final now = DateTime.now();

    for (var b in List<Booking>.from(bookings)) { // copy biar aman saat remove
      final parts = b.time.split(':');
      final start = DateTime(
        int.parse(b.date.split('/')[2]),
        int.parse(b.date.split('/')[1]),
        int.parse(b.date.split('/')[0]),
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final dur = int.tryParse(b.duration ?? '30') ?? 30;
      final end = start.add(Duration(minutes: dur));

      if (now.isAfter(end)) {
        setState(() {
          bookings.remove(b);
        });
      }
    }
  }

  Booking? get currentMeeting {
    for (var b in bookings) {
      final parts = b.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final start = DateTime(
        int.parse(b.date.split('/')[2]),
        int.parse(b.date.split('/')[1]),
        int.parse(b.date.split('/')[0]),
        hour,
        minute,
      );
      final dur = int.tryParse(b.duration ?? '30') ?? 30;
      final end = start.add(Duration(minutes: dur));
      if (_currentTime.isAfter(start) && _currentTime.isBefore(end)) {
        return b;
      }
    }
    return null;
  }

  String get formattedTime => DateFormat('hh:mm a').format(_currentTime);
  String get formattedDate => DateFormat('EEEE, MMMM d, y').format(_currentTime);

  void _openRoomDetail({bool meetNow = false}) async {
    DateTime? meetNowDate;
    if (meetNow) meetNowDate = _currentTime;
    final result = await Navigator.push<Booking>(
      context,
      _noAnimationRoute(
        RoomDetailPage(
          roomName: widget.roomName,
          existingBookings: bookings,
          isMeetNow: meetNow,
          meetNowDate: meetNowDate,
        ),
      ),
    );

    if (result != null) {
      final saved = await bookingService.saveBooking(result);
      setState(() {
        bookings.add(saved);
        isScanEnabled = saved.isScanEnabled;
      });
    }
  }

  Widget buildLogo(String? assetPath, {double? width, double? height}) {
    if (assetPath == null || assetPath.isEmpty) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () async {
        _logoTapCount++;
        _tapResetTimer?.cancel();
        _tapResetTimer = Timer(const Duration(seconds: 2), () {
          _logoTapCount = 0;
        });
        if (_logoTapCount >= 10) {
          _logoTapCount = 0;
          _tapResetTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("App unpinned")),
          );
        }
      },
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
  @override
  void dispose() {
    _timer.cancel();
    _bookingSubscription.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: const Color(0xFF168757),
        foregroundColor: Colors.white,
        title: Text(
          widget.roomName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            label: const Text("Meet Now", style: TextStyle(color: Colors.white)),
            onPressed: (isAvailable && isMeetNowAllowed)
                ? () => _openRoomDetail(meetNow: true)
                : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.schedule, color: Colors.white),
            label: const Text("Meet Later", style: TextStyle(color: Colors.white)),
            onPressed: () => _openRoomDetail(meetNow: false),
          ),
          TextButton.icon(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text("Scan Me", style: TextStyle(color: Colors.white)),
            onPressed: (currentMeeting?.isScanEnabled ?? false)
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanPage(booking: currentMeeting!),
                ),
              );
            } : null,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFEFF3F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBookingList(),
      ),
    );
  }

  Widget _buildBookingList() {
    Map<String, List<Booking>> grouped = {};
    for (var b in bookings) {
      grouped.putIfAbsent(b.date, () => []).add(b);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = DateFormat("dd/MM/yyyy").parse(a);
        final db = DateFormat("dd/MM/yyyy").parse(b);
        return da.compareTo(db);
      });

    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        final aDate = DateFormat("dd/MM/yyyy HH:mm")
            .parse("${a.date} ${a.time}");
        final bDate = DateFormat("dd/MM/yyyy HH:mm")
            .parse("${b.date} ${b.time}");
        return aDate.compareTo(bDate);
      });
    }

    return ListView.builder(
      itemCount: sortedKeys.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, idx) {
        final dateKey = sortedKeys[idx];
        final list = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                DateFormat("EEEE, dd MMM yyyy")
                    .format(DateFormat("dd/MM/yyyy").parse(dateKey)),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF168757),
                ),
              ),
            ),
            ...list.map((b) {
              return
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event, color: Color(0xFF168757)),
                          title: Text(
                            b.meetingTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "${formatBookingTime(b.time, b.date, b.duration)}"
                                " • ${b.hostName}"
                                "${b.numberOfPeople != null ? " • ${b.numberOfPeople}p" : ""}"
                                "${b.location != null ? " • ${b.location}" : ""}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          // trailing: IconButton(
                          //   icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          //   tooltip: "Edit Booking",
                          //   onPressed: () => _editBooking(b),
                          // ),
                        ),
                        if (b.equipment.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 4, bottom: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: b.equipment.map((e) {
                                return Chip(
                                  label: Text(
                                    e,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF168757),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
            }),
          ],
        );
      },
    );
  }
}