import 'base_model.dart';
 
/// Blueprint keeps a fixed set of common permission flags plus room for
/// more ("... permission lainnya"), so this wraps a Map but exposes the
/// documented flags as convenient getters.
class EmployeePermissions {
  final Map<String, bool> _raw;
 
  EmployeePermissions([Map<String, bool>? raw]) : _raw = raw ?? {};
 
  bool get canCreateOrder => _raw['can_create_order'] ?? false;
  bool get canManageCustomer => _raw['can_manage_customer'] ?? false;
  bool get canViewReport => _raw['can_view_report'] ?? false;
 
  bool has(String key) => _raw[key] ?? false;
 
  factory EmployeePermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return EmployeePermissions();
    return EmployeePermissions(
      json.map((key, value) => MapEntry(key, value == true)),
    );
  }
 
  Map<String, dynamic> toJson() => _raw;
}
 
class Employee extends BaseModel {
  final String companyId;
  final String laundryId;
  final String profileId;
  final String employeeCode;
  final String fullName;
  final String position;
  final double salary;
  final double commissionRate;
  final DateTime? hireDate;
  final DateTime? terminationDate;
  final bool isActive;
  final EmployeePermissions permissions;
 
  Employee({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.laundryId,
    required this.profileId,
    this.employeeCode = '',
    this.fullName = '',
    required this.position,
    this.salary = 0,
    this.commissionRate = 0,
    this.hireDate,
    this.terminationDate,
    required this.isActive,
    EmployeePermissions? permissions,
  }) : permissions = permissions ?? EmployeePermissions();
 
  factory Employee.fromJson(Map<String, dynamic> json, String documentId) {
    return Employee(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      companyId: json['company_id'] ?? '',
      laundryId: json['laundry_id'] ?? '',
      profileId: json['profile_id'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      fullName: json['full_name'] ?? '',
      position: json['position'] ?? 'cashier',
      salary: (json['salary'] ?? 0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      hireDate: dateTimeFromSnapshotOrNull(json['hire_date']),
      terminationDate: dateTimeFromSnapshotOrNull(json['termination_date']),
      isActive: json['is_active'] ?? true,
      permissions: EmployeePermissions.fromJson(json['permissions']),
    );
  }
 
  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'laundry_id': laundryId,
      'profile_id': profileId,
      'employee_code': employeeCode,
      'full_name': fullName,
      'position': position,
      'salary': salary,
      'commission_rate': commissionRate,
      'hire_date': hireDate,
      'termination_date': terminationDate,
      'is_active': isActive,
      'permissions': permissions.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}