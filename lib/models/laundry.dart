class Laundry {
  final String id;
  final String companyId;
  final String name;
  final String address;
  final String phone;
  final bool isActive;

  Laundry({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  factory Laundry.fromJson(Map<String, dynamic> json, String documentId) {
    return Laundry(
      id: documentId,
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'address': address,
      'phone': phone,
      'is_active': isActive,
    };
  }
}