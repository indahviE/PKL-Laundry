import 'base_model.dart';
 
class CompanySettings {
  final String currency;
  final String timezone;
  final Map<String, dynamic> notificationPreferences;
 
  CompanySettings({
    this.currency = 'IDR',
    this.timezone = 'Asia/Jakarta',
    this.notificationPreferences = const {},
  });
 
  factory CompanySettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CompanySettings();
    return CompanySettings(
      currency: json['currency'] ?? 'IDR',
      timezone: json['timezone'] ?? 'Asia/Jakarta',
      notificationPreferences:
          Map<String, dynamic>.from(json['notification_preferences'] ?? {}),
    );
  }
 
  Map<String, dynamic> toJson() => {
        'currency': currency,
        'timezone': timezone,
        'notification_preferences': notificationPreferences,
      };
}
 
class Company extends BaseModel {
  final String name;
  final String description;
  final String logoUrl;
  final String website;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final String taxNumber;
  final String businessLicense;
  final bool isActive;
  final CompanySettings settings;
 
  Company({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.description,
    this.logoUrl = '',
    this.website = '',
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    this.province = '',
    this.postalCode = '',
    this.taxNumber = '',
    this.businessLicense = '',
    required this.isActive,
    CompanySettings? settings,
  }) : settings = settings ?? CompanySettings();
 
  factory Company.fromJson(Map<String, dynamic> json, String documentId) {
    return Company(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      website: json['website'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      taxNumber: json['tax_number'] ?? '',
      businessLicense: json['business_license'] ?? '',
      isActive: json['is_active'] ?? true,
      settings: CompanySettings.fromJson(json['settings']),
    );
  }
 
  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'website': website,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'tax_number': taxNumber,
      'business_license': businessLicense,
      'is_active': isActive,
      'settings': settings.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
 