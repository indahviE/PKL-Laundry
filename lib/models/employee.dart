class Employee {
  final String id;
  final String companyId;
  final String laundryId; 
  final String fullName;
  final String role; 
  final bool isActive;

  Employee({
    required this.id,
    required this.companyId,
    required this.laundryId,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json, String documentId) {
    return Employee(
      id: documentId,
      companyId: json['company_id'] ?? '',
      laundryId: json['laundry_id'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'cashier',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'laundry_id': laundryId,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
    };
  }
}