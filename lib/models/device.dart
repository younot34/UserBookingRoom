class Device {
  final String id;
  final String deviceName;
  final String roomName;
  final String location;
  final DateTime? installDate;
  final int? capacity;
  final List<String> equipment;
  final bool isOn;

  Device({
    required this.id,
    required this.deviceName,
    required this.roomName,
    required this.location,
    required this.installDate,
    this.capacity,
    this.equipment = const [],
    this.isOn = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      deviceName: json['device_name'] ?? '',
      roomName: json['room_name'] ?? 'Unknown Room',
      location: json['location'] ?? '',
      installDate: json['install_date'] != null && json['install_date'] != ''
          ? DateTime.tryParse(json['install_date'])
          : null,
      capacity: json['capacity'],
      equipment: List<String>.from(json['equipment'] ?? []),
      isOn: json['is_on'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'device_name': deviceName,
    'room_name': roomName,
    'location': location,
    'install_date': installDate?.toIso8601String(),
    'capacity': capacity,
    'equipment': equipment,
    'is_on': isOn,
  };
}