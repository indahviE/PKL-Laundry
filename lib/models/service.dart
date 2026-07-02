class Service {
  final String id;
  final String companyId;
  final String name;
  final double price;
  final String unit; 
  final bool isActive;

  Service({
    required this.id,
    required this.companyId,
    required this.name,
    required this.price,
    required this.unit,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json, String documentId) {
    return Service(
      id: documentId,
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kilo',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'price': price,
      'unit': unit,
      'is_active': isActive,
    };
  }
}