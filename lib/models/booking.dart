class Booking {
  final String id;
  final String roomName;
  final String date;
  final String time;
  final String duration;
  final int numberOfPeople;
  final List<String> equipment;
  final String hostName;
  final String meetingTitle;
  final bool isScanEnabled;
  final String? scanInfo;
  final String? status;
  String? location;

  Booking({
    required this.id,
    required this.roomName,
    required this.date,
    required this.time,
    required this.duration,
    required this.numberOfPeople,
    required this.equipment,
    required this.hostName,
    required this.meetingTitle,
    required this.isScanEnabled,
    this.scanInfo,
    this.status,
    this.location,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      roomName: json['room_name'],
      date: json['date'],
      time: json['time'],
      duration: json['duration'],
      numberOfPeople: json['number_of_people'],
      equipment: List<String>.from(json['equipment'] ?? []),
      hostName: json['host_name'],
      meetingTitle: json['meeting_title'],
      isScanEnabled: json['is_scan_enabled'] ?? false,
      scanInfo: json['scan_info'],
      status: json['status'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
    'room_name': roomName,
    'date': date,
    'time': time,
    'duration': duration,
    'number_of_people': numberOfPeople,
    'equipment': equipment,
    'host_name': hostName,
    'meeting_title': meetingTitle,
    'is_scan_enabled': isScanEnabled,
    'scan_info': scanInfo,
    'status': status,
    'location': location,
  };
}