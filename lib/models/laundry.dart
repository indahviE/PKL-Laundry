import 'base_model.dart';
 
class DayHours {
  final String open;
  final String close;
 
  DayHours({required this.open, required this.close});
 
  factory DayHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DayHours(open: '08:00', close: '20:00');
    return DayHours(
      open: json['open'] ?? '08:00',
      close: json['close'] ?? '20:00',
    );
  }
 
  Map<String, dynamic> toJson() => {'open': open, 'close': close};
}
 
class OperatingHours {
  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;
  final DayHours sunday;
 
  OperatingHours({
    DayHours? monday,
    DayHours? tuesday,
    DayHours? wednesday,
    DayHours? thursday,
    DayHours? friday,
    DayHours? saturday,
    DayHours? sunday,
  })  : monday = monday ?? DayHours(open: '08:00', close: '20:00'),
        tuesday = tuesday ?? DayHours(open: '08:00', close: '20:00'),
        wednesday = wednesday ?? DayHours(open: '08:00', close: '20:00'),
        thursday = thursday ?? DayHours(open: '08:00', close: '20:00'),
        friday = friday ?? DayHours(open: '08:00', close: '20:00'),
        saturday = saturday ?? DayHours(open: '08:00', close: '20:00'),
        sunday = sunday ?? DayHours(open: '08:00', close: '20:00');
 
  factory OperatingHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OperatingHours();
    return OperatingHours(
      monday: DayHours.fromJson(json['monday']),
      tuesday: DayHours.fromJson(json['tuesday']),
      wednesday: DayHours.fromJson(json['wednesday']),
      thursday: DayHours.fromJson(json['thursday']),
      friday: DayHours.fromJson(json['friday']),
      saturday: DayHours.fromJson(json['saturday']),
      sunday: DayHours.fromJson(json['sunday']),
    );
  }
 
  Map<String, dynamic> toJson() => {
        'monday': monday.toJson(),
        'tuesday': tuesday.toJson(),
        'wednesday': wednesday.toJson(),
        'thursday': thursday.toJson(),
        'friday': friday.toJson(),
        'saturday': saturday.toJson(),
        'sunday': sunday.toJson(),
      };
}
 
class LaundryLocation {
  final double lat;
  final double lng;
 
  LaundryLocation({required this.lat, required this.lng});
 
  factory LaundryLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LaundryLocation(lat: 0.0, lng: 0.0);
    return LaundryLocation(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
 
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}
 
class Laundry extends BaseModel {
  final String companyId;
  final String name;
  final String code;
  final String address;
  final String city;
  final String province;
  final String phone;
  final String email;
  final String? managerId;
  final OperatingHours operatingHours;
  final int capacity;
  final bool isActive;
  final LaundryLocation location;
 
  Laundry({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.name,
    required this.code,
    required this.address,
    this.city = '',
    this.province = '',
    required this.phone,
    this.email = '',
    this.managerId,
    OperatingHours? operatingHours,
    this.capacity = 0,
    required this.isActive,
    LaundryLocation? location,
  })  : operatingHours = operatingHours ?? OperatingHours(),
        location = location ?? LaundryLocation(lat: 0.0, lng: 0.0);
 
  factory Laundry.fromJson(Map<String, dynamic> json, String documentId) {
    return Laundry(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      managerId: json['manager_id'],
      operatingHours: OperatingHours.fromJson(json['operating_hours']),
      capacity: json['capacity'] ?? 0,
      isActive: json['is_active'] ?? true,
      location: LaundryLocation.fromJson(json['location']),
    );
  }
 
  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'province': province,
      'phone': phone,
      'email': email,
      'manager_id': managerId,
      'operating_hours': operatingHours.toJson(),
      'capacity': capacity,
      'is_active': isActive,
      'location': location.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
 