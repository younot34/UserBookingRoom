import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/booking.dart';
import 'BookingConfirm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RoomDetailPage extends StatefulWidget {
  final String roomName;
  final List<Booking>? existingBookings;
  final bool isMeetNow;
  final DateTime? meetNowDate;
  final Booking? bookingToEdit;

  const RoomDetailPage({
    super.key,
    required this.roomName,
    this.existingBookings,
    this.isMeetNow = false,
    this.meetNowDate,
    this.bookingToEdit,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  bool isScanEnabled = false;
  String? scanInfo;
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  String? selectedHour;
  String? selectedMinute;
  String? selectedDuration;
  List<String> selectedEquipment = [];
  String? userName;
  String editableTitle = "Title Of Event";
  int timePage = 0;
  double _calendarHeight = 400;
  final int timesPerPage = 6;
  final GlobalKey _calendarKey = GlobalKey();
  late List<String> times;
  final List<int> durations = [30, 45, 60, 90, 120, 150, 180, 210];
  List<String> hours = [];
  List<String> minutes = [];
  int? numberOfPeople;
  int? capacity; // kapasitas dari device
  List<String> equipment = []; // override list statis
  final Map<String, IconData> equipmentIcons = {
    "Meja": Icons.table_bar,
    "Kursi": Icons.chair,
    "Whiteboard": Icons.border_color,
    "Flipchart": Icons.edit_note,
    "Microphone": Icons.mic,
    "Speaker": Icons.speaker,
    "Sound System": Icons.surround_sound,
    "Headset": Icons.headset,
    "Proyektor": Icons.present_to_all,
    "Layar Proyektor": Icons.theaters,
    "TV": Icons.tv,
    "Video Conference": Icons.videocam,
    "Laptop": Icons.laptop_mac,
    "PC": Icons.computer,
    "Tablet": Icons.tablet,
    "HP": Icons.phone_android,
    "Printer": Icons.print,
    "WiFi": Icons.wifi,
    "LAN": Icons.settings_ethernet,
    "HDMI": Icons.cable,
    "Charger": Icons.power,
    "AC": Icons.ac_unit,
    "Lampu": Icons.light,
    "Jam": Icons.access_time,
    "Tirai": Icons.window,
    "Remote": Icons.settings_remote,
    "Name Tag": Icons.badge,
    "Air Minum": Icons.local_drink,
    "Snack": Icons.fastfood,
    "Dokumen": Icons.folder,
  };
  List<String> get visibleTimes {
    final available = getAvailableTimes(selectedDate);
    final start = timePage * timesPerPage;
    final end = (start + timesPerPage) > available.length ? available.length : (start + timesPerPage);
    return available.sublist(start, end);
  }
  void nextPage() {
    if ((timePage + 1) * timesPerPage < times.length) {
      setState(() => timePage++);
    }
  }
  void previousPage() {
    if (timePage > 0) setState(() => timePage--);
  }
  @override
  void initState() {
    super.initState();
    hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));
    if (widget.isMeetNow && widget.meetNowDate != null) {
      selectedDate = widget.meetNowDate!;
      selectedHour = selectedDate.hour.toString().padLeft(2, '0');
      selectedMinute = selectedDate.minute.toString().padLeft(2, '0');
      selectedTime = "$selectedHour:$selectedMinute";
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      final email = currentUser.email!;
      // ambil sebelum @
      final host = email.split('@').first;
      setState(() {
        userName = host;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCalendarHeight());
    _loadDeviceData();
    if (widget.bookingToEdit != null) {
      final b = widget.bookingToEdit!;
      editableTitle = b.meetingTitle;
      userName = b.hostName;
      numberOfPeople = b.numberOfPeople;
      selectedEquipment = List.from(b.equipment);
      isScanEnabled = b.isScanEnabled;
      scanInfo = b.scanInfo;

      // date
      final partsDate = b.date.split('/');
      selectedDate = DateTime(
        int.parse(partsDate[2]),
        int.parse(partsDate[1]),
        int.parse(partsDate[0]),
      );

      // time
      final partsTime = b.time.split(':');
      selectedHour = partsTime[0];
      selectedMinute = partsTime[1];
      selectedTime = "${partsTime[0]}:${partsTime[1]}";

      // duration
      selectedDuration = b.duration;
    }
  }
  void _getCalendarHeight() {
    final renderBox = _calendarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _calendarHeight = renderBox.size.height;
      });
    }
  }
  bool isSelectedTimeValid(String h, String m) {
    final selectedDur = int.tryParse(selectedDuration ?? '30') ?? 30;
    final checkTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(h),
      int.parse(m),
    );
    final checkEnd = checkTime.add(Duration(minutes: selectedDur));
    if (checkTime.isBefore(DateTime.now())) return false;
    const minBufferMinutes = 30;
    if (widget.existingBookings != null) {
      for (var b in widget.existingBookings!) {
        if (b.date == "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}") {
          final bookedParts = b.time.split(':');
          final bookedHour = int.parse(bookedParts[0]);
          final bookedMinute = int.parse(bookedParts[1]);
          final bookedDur = int.tryParse(b.duration ?? '30') ?? 30;
          final bookedStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, bookedHour, bookedMinute);
          final bookedEnd = bookedStart.add(Duration(minutes: bookedDur));
          // buffer sebelum & sesudah booking
          final bufferStart = bookedStart.subtract(const Duration(minutes: minBufferMinutes));
          final bufferEnd = bookedEnd.add(const Duration(minutes: minBufferMinutes));
          if (checkTime.isBefore(bufferEnd) && checkEnd.isAfter(bufferStart)) {
            return false;
          }
        }
      }
    }
    return true;
  }
  List<String> getAvailableTimes(DateTime date) {
    final now = DateTime.now();
    List<String> available = [];
    for (var t in times) {
      final parts = t.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final checkTime = DateTime(date.year, date.month, date.day, hour, minute);
      if (checkTime.isBefore(now)) continue;
      bool conflict = false;
      if (widget.existingBookings != null) {
        for (var b in widget.existingBookings!) {
          if (b.date == "${date.day}/${date.month}/${date.year}") {
            final bookedParts = b.time.split(':');
            final bookedHour = int.parse(bookedParts[0]);
            final bookedMinute = int.parse(bookedParts[1]);
            final duration = int.tryParse(b.duration ?? '30') ?? 30;
            final bookedStart = DateTime(date.year, date.month, date.day, bookedHour, bookedMinute);
            final bookedEnd = bookedStart.add(Duration(minutes: duration));

            // buffer sebelum & sesudah booking
            final bufferStart = bookedStart.subtract(const Duration(minutes: 30));
            final bufferEnd = bookedEnd.add(const Duration(minutes: 30));

            if (checkTime.isAfter(bufferStart) && checkTime.isBefore(bufferEnd)) {
              conflict = true;
              break;
            }
          }
        }
      }

      if (!conflict && isSelectedTimeValid(hour.toString().padLeft(2, '0'), minute.toString().padLeft(2, '0'))) {
        available.add(t);
      }
    }
    return available;
  }
  Future<void> _loadDeviceData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('roomName', isEqualTo: widget.roomName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        capacity = data['capacity'];
        equipment = List<String>.from(data['equipment'] ?? []);
      });
    }
  }
  Future<String?> _showScanInfoDialog() async {
    final controller = TextEditingController(text: scanInfo);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan Me Info / Rules"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Enter information or rules...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
    return result;
  }
  Widget buildCalendar() {
    final calendar =
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        key: _calendarKey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!widget.isMeetNow) {
                setState(() {
                  selectedDate = selectedDay;
                  _getCalendarHeight();
                });
              }
            },
            enabledDayPredicate: (day) {
              final today = DateTime.now();
              return !day.isBefore(DateTime(today.year, today.month, today.day));
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xAA168757),
                shape: BoxShape.circle,
              ),
              disabledTextStyle: TextStyle(
                color: Color(0xFF8C8C8C),
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.black),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                if (day.weekday == DateTime.sunday) {
                  return const Center(
                    child: Text(
                      'Sun',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
              defaultBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
              outsideBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
    if (widget.isMeetNow) {
      return IgnorePointer(
        ignoring: true,
        child: Opacity(
          opacity: 0.5,
          child: calendar,
        ),
      );
    }
    return calendar;
  }
  Widget buildCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
  double timesDurationSpacing = 18;
  Widget buildTimesAndDuration() {
    List<int> availableDurations = durations;
    if (widget.isMeetNow && widget.meetNowDate != null && widget.existingBookings != null) {
      final now = widget.meetNowDate!;
      DateTime? nearestBooking;
      for (var b in widget.existingBookings!) {
        final bookedParts = b.time.split(':');
        final bookedHour = int.parse(bookedParts[0]);
        final bookedMinute = int.parse(bookedParts[1]);
        final bookedStart = DateTime(now.year, now.month, now.day, bookedHour, bookedMinute);
        if (bookedStart.isAfter(now)) {
          if (nearestBooking == null || bookedStart.isBefore(nearestBooking)) {
            nearestBooking = bookedStart;
          }
        }
      }
      if (nearestBooking != null) {
        final diffMinutes = nearestBooking.difference(now).inMinutes;
        availableDurations = durations.where((d) => d <= diffMinutes).toList();
      }
    }
    final hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    final minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));
    if (selectedHour != null && selectedMinute != null) {
      final checkTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(selectedHour!),
        int.parse(selectedMinute!),
      );

      availableDurations = durations.where((d) {
        final checkEnd = checkTime.add(Duration(minutes: d));

        if (widget.existingBookings != null) {
          for (var b in widget.existingBookings!) {
            if (b.date == "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}") {
              final bookedParts = b.time.split(':');
              final bookedHour = int.parse(bookedParts[0]);
              final bookedMinute = int.parse(bookedParts[1]);
              final bookedDur = int.tryParse(b.duration ?? '30') ?? 30;
              final bookedStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, bookedHour, bookedMinute);
              final bookedEnd = bookedStart.add(Duration(minutes: bookedDur));

              final bufferStart = bookedStart.subtract(const Duration(minutes: 30));
              final bufferEnd = bookedEnd.add(const Duration(minutes: 30));

              if (checkTime.isBefore(bufferEnd) && checkEnd.isAfter(bufferStart)) {
                return false;
              }
            }
          }
        }
        return true;
      }).toList();
    }
    return Column(
      children: [
        buildCard(
          title: "Select Time",
          child: widget.isMeetNow
              ? ListTile(
            leading: const Icon(Icons.access_time, color: Color(0xFF168757)),
            title: Text(
              selectedTime ?? "Now",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            enabled: false,
          )
              : Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("Hour"),
                  value: selectedHour,
                  items: hours.map((h) {
                    final disabled = selectedMinute != null && !isSelectedTimeValid(h, selectedMinute!);
                    return DropdownMenuItem(
                      value: h,
                      enabled: !disabled,
                      child: Text(
                        h,
                        style: TextStyle(color: disabled ? Colors.grey : Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedHour = value;
                      if (selectedMinute != null) selectedTime = "$selectedHour:$selectedMinute";
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("Minute"),
                  value: selectedMinute,
                  items: minutes
                      .where((m) => selectedHour == null || isSelectedTimeValid(selectedHour!, m))
                      .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedMinute = value;
                      if (selectedHour != null) selectedTime = "$selectedHour:$selectedMinute";
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        if (selectedTime != null || widget.isMeetNow) ...[
          buildCard(
            title: "Select Duration (minutes)",
            child: SizedBox(
              height: 28,
              child: GridView.count(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 2,
                childAspectRatio: 2,
                children: availableDurations.map((duration) {
                  final isSelected = selectedDuration == duration.toString();
                  return GestureDetector(
                    onTap: () => setState(() => selectedDuration = duration.toString()),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF168757) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${duration}m",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
  Widget buildNumberOfPeople() {
    if (capacity == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return
      Padding(
        padding: const EdgeInsets.only(top: 15),
        child: buildCard(
          title: "Number of People",
          child: SizedBox(
            width: double.infinity,
            child: DropdownButton<int>(
              isExpanded: true,
              hint: const Text("Select number of people"),
              value: numberOfPeople,
              items: List.generate(
                capacity!,
                    (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text("${index + 1}"),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  numberOfPeople = value;
                });
              },
            ),
          ),
        ),
      );
  }
  Widget buildEquipment() {
    if (equipment.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 200,
      child: buildCard(
        title: "Available Equipment",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: equipment.map((equip) {
                        final isSelected = selectedEquipment.contains(equip);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedEquipment.remove(equip);
                              } else {
                                selectedEquipment.add(equip);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF168757) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  equipmentIcons[equip] ?? Icons.device_unknown,
                                  size: 20,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  equip,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code, size: 20, color: Colors.black87),
                      const SizedBox(width: 4),
                      const Text("Scan Me"),
                      Switch(
                        value: isScanEnabled,
                        onChanged: (val) async {
                          if (val) {
                            setState(() {
                              isScanEnabled = true;
                            });
                            final result = await _showScanInfoDialog();
                            if (result == null) {
                              setState(() {
                                isScanEnabled = false;
                              });
                            } else {
                              setState(() {
                                scanInfo = result;
                              });
                            }
                          } else {
                            setState(() {
                              isScanEnabled = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: TextEditingController(text: userName),
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Host Name",
                hintText: "Input Host Name",
              ),
              onChanged: (value) {
                setState(() {
                  userName = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget buildSubmitButton() {
    final isFormComplete =
        selectedDate != null &&
            selectedTime != null &&
            selectedDuration != null &&
            numberOfPeople != null &&
            userName != null &&
            userName!.isNotEmpty &&
            selectedEquipment.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF8C8C8C);
              }
              return const Color(0xFFFFD700);
            },
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        onPressed: isFormComplete
            ? () async {
          final booking = Booking(
            id: widget.bookingToEdit?.id ?? "", // kalau edit, pakai id lama
            roomName: widget.roomName,
            date:
            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
            time: "$selectedHour:$selectedMinute",
            duration: selectedDuration,
            numberOfPeople: numberOfPeople,
            equipment: selectedEquipment,
            hostName: userName ?? "",
            meetingTitle: editableTitle,
            isScanEnabled: isScanEnabled,
            scanInfo: scanInfo,
          );

          if (widget.bookingToEdit != null) {
            // EDIT MODE → langsung return ke parent
            Navigator.pop(context, booking);
          } else {
            // CREATE MODE → lanjut ke konfirmasi
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookingConfirmationPage(booking: booking),
              ),
            );
            if (result != null) {
              Navigator.pop(context, result);
            }
          }
        }
            : null,
        child: Text(
          widget.bookingToEdit != null ? 'Save Changes' : 'Next',
          style: const TextStyle(fontSize: 18, color: Color(0xFF242424)),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xAA168757),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              editableTitle,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final controller = TextEditingController(text: editableTitle);
                final newTitle = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Edit Title"),
                    content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter new title")),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
                    ],
                  ),
                );
                if (newTitle != null && newTitle.isNotEmpty) {
                  setState(() {
                    editableTitle = newTitle;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF168757),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (isMobile)
              Column(
                children: [
                  buildCalendar(),
                  const SizedBox(height: 10),
                  buildTimesAndDuration(),
                  const SizedBox(height: 10),
                  buildNumberOfPeople(),
                ],
              )
            else Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: buildCalendar(),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: _calendarHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            child: buildTimesAndDuration(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildNumberOfPeople(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            buildEquipment(),
            const SizedBox(height: 20),
            buildSubmitButton(),
          ],
        ),
      ),
    );
  }
}