// lib/models/company.dart
class Company {
  final String id;
  final String name;
  final String description;
  final String email;
  final String phone;
  final String address;
  final String city;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    required this.description,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.isActive,
  });

  factory Company.fromJson(Map<String, dynamic> json, String documentId) {
    return Company(
      id: documentId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'is_active': isActive,
    };
  }
}