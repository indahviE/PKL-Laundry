git branch -M mainPRD: SaaS Laundry Management Platform (Flutter + Firebase)
Versi: 2.0 (Flutter & Firebase Edition)
Tanggal: 30 Juni 2026
Status: Final

DAFTAR ISI
Pendahuluan

Solusi & Value Proposition

Lingkup & Fitur (MVP)

Spesifikasi Teknis (Flutter + Firebase)

Database Architecture (User-Based Design)

User Flow & User Experience

Metrik Keberhasilan

Roadmap Pengembangan

Dokumen Pendukung

1. PENDAHULUAN
1.1 Tujuan Produk
Membangun aplikasi SaaS Laundry Management berbasis mobile menggunakan Flutter dengan backend Firebase. Platform ini menggunakan pendekatan User-Based Database Architecture di mana setiap pengguna (user) memiliki database/tabel sendiri yang terisolasi, menggunakan User ID sebagai root identifier untuk semua data.

1.2 Perbedaan dengan Arsitektur Tradisional
Aspek	Arsitektur Tradisional (SQL)	Arsitektur User-Based (Firebase)
Struktur Data	Tabel terpusat dengan RLS	Koleksi per user dengan user_id
Isolasi Data	Row Level Security	Path-based isolation
Skalabilitas	Vertikal (meningkatkan server)	Horizontal (Firebase auto-scale)
Query	SQL Complex Joins	Firestore queries with indexes
Real-time	Memerlukan setup tambahan	Built-in real-time updates
Offline Support	Terbatas	Native offline persistence
1.3 Sasaran Pengguna (Target Audience)
Peran	Deskripsi
Pemilik Bisnis Laundry (Owner)	Individu atau entitas yang memiliki satu atau lebih cabang laundry
Manajer Cabang (Manager)	Bertanggung jawab atas operasional harian di cabang tertentu
Karyawan Laundry (Employee)	Staf yang menangani proses penerimaan, pencucian, dan pengantaran pesanan
Pelanggan (Customer)	Pengguna akhir yang menggunakan jasa laundry
1.4 Pernyataan Masalah (Problem Statement)
Pengelolaan Manual: Proses pencatatan pesanan, pelanggan, dan keuangan yang rentan terhadap kesalahan manusia

Inefisiensi Operasional: Kesulitan dalam melacak status pesanan dan mengelola banyak cabang

Kurangnya Insight Data: Tidak adanya data analitik untuk pengambilan keputusan bisnis

Skalabilitas Terbatas: Sistem lama sulit dikembangkan seiring pertumbuhan bisnis

Mobile Accessibility: Kebutuhan akan akses mobile untuk operasional di lapangan

2. SOLUSI & VALUE PROPOSITION
2.1 Solusi
Aplikasi Flutter + Firebase dengan pendekatan User-Based Database Architecture:

Isolasi Data Total: Setiap user memiliki koleksi data sendiri yang diidentifikasi dengan user_id

Real-time Updates: Semua perubahan data tersinkronisasi secara real-time

Offline First: Aplikasi dapat beroperasi tanpa koneksi internet

Cross-Platform: Satu codebase untuk Android, iOS, dan Web

Scalable: Firebase secara otomatis menangani skalabilitas

2.2 Database Architecture (User-Based Design)
text
Firestore Root
│
├── users/
│   └── {user_id}/                          # Root dokumen per user
│       ├── profile/                        # Profil pengguna
│       │   └── data: {full_name, email, role, ...}
│       │
│       ├── companies/                      # Koleksi perusahaan
│       │   └── {company_id}/
│       │       └── data: {name, address, logo, ...}
│       │
│       ├── laundries/                      # Koleksi cabang
│       │   └── {laundry_id}/
│       │       └── data: {name, code, address, ...}
│       │
│       ├── employees/                      # Koleksi karyawan
│       │   └── {employee_id}/
│       │       └── data: {profile_id, position, salary, ...}
│       │
│       ├── customers/                      # Koleksi pelanggan
│       │   └── {customer_id}/
│       │       └── data: {full_name, phone, email, ...}
│       │
│       ├── service_types/                  # Koleksi jenis layanan
│       │   └── {service_id}/
│       │       └── data: {name, price_per_kg, duration, ...}
│       │
│       ├── orders/                         # Koleksi pesanan
│       │   └── {order_id}/
│       │       └── data: {order_number, customer_id, items, status, ...}
│       │
│       ├── subscriptions/                  # Koleksi langganan
│       │   └── {subscription_id}/
│       │       └── data: {plan_id, status, period_start, ...}
│       │
│       └── transactions/                   # Koleksi transaksi
│           └── {transaction_id}/
│               └── data: {amount, type, status, ...}
2.3 Keunggulan Arsitektur User-Based
Isolasi Data Sempurna: Setiap user hanya bisa mengakses datanya sendiri

Keamanan Inherent: Firebase Security Rules berbasis path

Performa Lebih Baik: Query lebih cepat karena data terpartisi per user

Skalabilitas Horizontal: Firebase menangani scaling otomatis

Backup & Restore: Mudah melakukan backup per user

Multi-tenancy: Setiap user adalah tenant terpisah

3. LINGKUP & FITUR (MVP - MINIMUM VIABLE PRODUCT)
3.1 Manajemen Pengguna & Autentikasi
3.1.1 Autentikasi Firebase
Registrasi dengan Email/Password

Login dengan Email/Password

Login dengan Google (OAuth)

Login dengan Phone Number

Verifikasi Email

Reset Password

Session Management dengan Firebase Auth

3.1.2 Peran Pengguna (Role-Based Access Control)
Role	Hak Akses
Admin	Akses penuh ke semua fitur di semua cabang
Owner	Mengelola perusahaan, cabang, dan semua data bisnis
Manager	Mengelola operasional di cabang yang ditugaskan
Employee	Mengelola pesanan dan pelanggan di cabang yang ditugaskan
3.1.3 Firebase Security Rules
javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Setiap user hanya bisa akses data miliknya sendiri
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function getUserPath() {
      return /databases/$(database)/documents/users/$(request.auth.uid);
    }

    match /users/{userId}/{document=**} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/profile/{document} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/companies/{companyId} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/laundries/{laundryId} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/employees/{employeeId} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/customers/{customerId} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/orders/{orderId} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/subscriptions/{subscriptionId} {
      allow read, write: if isOwner(userId);
    }

    match /users/{userId}/transactions/{transactionId} {
      allow read, write: if isOwner(userId);
    }
  }
}
3.2 Onboarding & Setup Perusahaan
3.2.1 Pembuatan Profil User
Setelah registrasi, user membuat profil:

text
users/{user_id}/profile/
{
  full_name: "John Doe",
  email: "john@email.com",
  phone: "+6281234567890",
  avatar_url: "https://...",
  role: "owner",
  created_at: Timestamp,
  updated_at: Timestamp
}
3.2.2 Pembuatan Perusahaan
text
users/{user_id}/companies/{company_id}/
{
  name: "Laundry Bersih Sentosa",
  description: "Laundry terpercaya di Jakarta",
  logo_url: "https://...",
  website: "https://...",
  email: "info@laundrybersih.com",
  phone: "+6281234567890",
  address: "Jl. Merdeka No. 123, Jakarta",
  city: "Jakarta",
  province: "DKI Jakarta",
  postal_code: "12345",
  tax_number: "12.345.678.9-123.456",
  business_license: "123456789",
  is_active: true,
  settings: {
    currency: "IDR",
    timezone: "Asia/Jakarta",
    notification_preferences: {...}
  },
  created_at: Timestamp,
  updated_at: Timestamp
}
3.2.3 Manajemen Cabang
text
users/{user_id}/laundries/{laundry_id}/
{
  company_id: "company_id_reference",
  name: "Cabang Merdeka",
  code: "JKT001",
  address: "Jl. Merdeka No. 123, Jakarta",
  city: "Jakarta",
  province: "DKI Jakarta",
  phone: "+6281234567890",
  email: "cabang@laundrybersih.com",
  manager_id: "profile_id_reference",
  operating_hours: {
    monday: {open: "08:00", close: "20:00"},
    tuesday: {open: "08:00", close: "20:00"},
    // ... semua hari
  },
  capacity: 100,
  is_active: true,
  location: {
    lat: -6.2088,
    lng: 106.8456
  },
  created_at: Timestamp,
  updated_at: Timestamp
}
3.3 Manajemen Data Master
3.3.1 Manajemen Pelanggan
text
users/{user_id}/customers/{customer_id}/
{
  company_id: "company_id_reference",
  customer_code: "CUST001",
  full_name: "Jane Smith",
  email: "jane@email.com",
  phone: "+6289876543210",
  address: "Jl. Sudirman No. 45, Jakarta",
  city: "Jakarta",
  postal_code: "12345",
  date_of_birth: "1990-01-01",
  gender: "female",
  membership_type: "gold",
  total_orders: 45,
  total_spent: 2500000.00,
  loyalty_points: 500,
  notes: "Pelanggan premium",
  is_active: true,
  created_at: Timestamp,
  updated_at: Timestamp
}
3.3.2 Manajemen Karyawan
text
users/{user_id}/employees/{employee_id}/
{
  profile_id: "profile_id_reference",
  laundry_id: "laundry_id_reference",
  company_id: "company_id_reference",
  employee_code: "EMP001",
  position: "Manager",
  salary: 5000000.00,
  commission_rate: 2.5,
  hire_date: "2024-01-01",
  termination_date: null,
  is_active: true,
  permissions: {
    can_create_order: true,
    can_manage_customer: true,
    can_view_report: true,
    // ... permission lainnya
  },
  created_at: Timestamp,
  updated_at: Timestamp
}
3.3.3 Manajemen Jenis Layanan
text
users/{user_id}/service_types/{service_id}/
{
  company_id: "company_id_reference",
  name: "Cuci Kering Setrika",
  description: "Layanan cuci dan setrika",
  price_per_kg: 15000.00,
  price_per_item: null,
  pricing_type: "per_kg",
  estimated_duration: 24, // dalam jam
  is_active: true,
  sort_order: 1,
  created_at: Timestamp,
  updated_at: Timestamp
}
3.4 Manajemen Pesanan (Core Feature)
3.4.1 Struktur Data Pesanan
text
users/{user_id}/orders/{order_id}/
{
  company_id: "company_id_reference",
  laundry_id: "laundry_id_reference",
  customer_id: "customer_id_reference",
  employee_id: "employee_id_reference",
  order_number: "JKT001-20260630-0001",

  items: [
    {
      service_type_id: "service_id",
      service_name: "Cuci Kering Setrika",
      quantity: 5,
      weight: 3.5,
      price_per_unit: 15000.00,
      total_price: 52500.00,
      notes: "Baju putih jangan dicampur"
    }
  ],

  total_weight: 3.5,
  total_items: 5,
  subtotal: 52500.00,
  discount_amount: 0.00,
  tax_amount: 0.00,
  total_amount: 52500.00,

  status: "pending", // pending, confirmed, in_progress, washing, drying, ironing, quality_check, ready, completed, cancelled
  status_history: [
    {
      status: "pending",
      timestamp: Timestamp,
      note: "Pesanan dibuat"
    }
  ],

  order_date: Timestamp,
  pickup_date: Timestamp,
  estimated_completion: Timestamp,
  actual_completion: null,
  delivery_date: null,

  payment_status: "pending", // pending, partial, paid, refunded
  payment_method: "cash",
  paid_amount: 0.00,

  notes: "Pesanan regular",
  special_instructions: "Harap cuci dengan air dingin",
  priority_level: "normal",

  created_at: Timestamp,
  updated_at: Timestamp
}
3.4.2 Status Pesanan Flow
text
pending → confirmed → in_progress → washing → drying → ironing → quality_check → ready → completed
                                                                                    ↓
                                                                              cancelled
3.4.3 Generate Order Number (Cloud Function)
javascript
// Firebase Cloud Function
exports.generateOrderNumber = functions.firestore
  .document('users/{userId}/orders/{orderId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const orderData = snap.data();
    const laundryId = orderData.laundryId;

    // Get laundry code
    const laundryDoc = await admin.firestore()
      .doc(`users/${userId}/laundries/${laundryId}`)
      .get();
    const laundryCode = laundryDoc.data().code;

    // Get today's sequence
    const today = new Date();
    const dateStr = today.toISOString().slice(0,10).replace(/-/g, '');

    const ordersRef = admin.firestore()
      .collection(`users/${userId}/orders`);

    const query = await ordersRef
      .where('order_date', '>=', new Date(today.setHours(0,0,0,0)))
      .get();

    const sequence = query.size + 1;
    const orderNumber = `${laundryCode}-${dateStr}-${String(sequence).padStart(4, '0')}`;

    // Update order with order number
    await snap.ref.update({ order_number: orderNumber });
  });
3.5 Sistem Pembayaran & Penagihan
3.5.1 Struktur Data Transaksi
text
users/{user_id}/transactions/{transaction_id}/
{
  company_id: "company_id_reference",
  order_id: "order_id_reference", // optional
  subscription_id: "subscription_id_reference", // optional
  stripe_payment_intent_id: "pi_xxx",

  amount: 52500.00,
  currency: "IDR",
  transaction_type: "order_payment", // order_payment, subscription_payment, refund
  payment_method: "cash",

  status: "succeeded", // pending, processing, succeeded, failed, canceled, refunded

  metadata: {
    payment_date: "2026-06-30",
    reference: "INV-001"
  },
  notes: "Pembayaran pesanan JKT001-20260630-0001",
  processed_by: "profile_id_reference",

  created_at: Timestamp,
  updated_at: Timestamp
}
3.6 Pricing Strategy & Manajemen Langganan
3.6.1 Paket Berlangganan (Pre-defined)
Fitur	Starter	Professional	Enterprise
Harga Bulanan	Rp 99.000	Rp 199.000	Rp 399.000
Harga Tahunan	Rp 990.000	Rp 1.990.000	Rp 3.990.000
Maksimal Cabang	1	5	Unlimited
Maksimal Karyawan	5	25	Unlimited
Maksimal Order/Bulan	500	2.000	Unlimited
3.6.2 Struktur Data Langganan
text
users/{user_id}/subscriptions/{subscription_id}/
{
  company_id: "company_id_reference",
  plan_id: "starter", // starter, professional, enterprise
  plan_name: "Starter",

  stripe_subscription_id: "sub_xxx",
  stripe_customer_id: "cus_xxx",

  status: "active", // trialing, active, past_due, canceled, unpaid, incomplete

  current_period_start: Timestamp,
  current_period_end: Timestamp,
  trial_start: Timestamp,
  trial_end: Timestamp,
  canceled_at: null,

  billing_cycle: "monthly", // monthly, yearly

  features: ["Order Management", "Customer Database", "Basic Reports"],
  limits: {
    max_laundries: 1,
    max_employees: 5,
    max_orders_per_month: 500
  },

  created_at: Timestamp,
  updated_at: Timestamp
}
3.6.3 Fitur Pembatasan (Feature Gating)
dart
class SubscriptionService {
  Future<bool> canAddLaundry(String userId) async {
    final subscription = await getSubscription(userId);
    final maxLaundries = subscription.limits['max_laundries'];
    if (maxLaundries == -1) return true; // Unlimited

    final laundryCount = await getLaundryCount(userId);
    return laundryCount < maxLaundries;
  }

  Future<bool> canAddEmployee(String userId) async {
    final subscription = await getSubscription(userId);
    final maxEmployees = subscription.limits['max_employees'];
    if (maxEmployees == -1) return true;

    final employeeCount = await getEmployeeCount(userId);
    return employeeCount < maxEmployees;
  }

  Future<bool> hasFeature(String userId, String feature) async {
    final subscription = await getSubscription(userId);
    return subscription.features.contains(feature);
  }
}
3.7 Dashboard & Analitik
3.7.1 Dashboard Data
dart
class DashboardData {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int totalCustomers;
  final double totalRevenue;
  final double todayRevenue;
  final Map<String, double> revenueByDay;
  final Map<String, int> ordersByStatus;
  final List<Order> recentOrders;
  final List<Map<String, dynamic>> topServices;
  final Map<int, int> ordersByHour; // Peak hours
}
3.7.2 Query untuk Dashboard
dart
class DashboardService {
  Future<DashboardData> getDashboardData(String userId) async {
    final ordersRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders');

    // Get total orders
    final totalOrders = await ordersRef.count().get();

    // Get active orders
    final activeOrders = await ordersRef
      .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
      .count()
      .get();

    // Get today's revenue
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayOrders = await ordersRef
      .where('created_at', isGreaterThanOrEqualTo: todayStart)
      .where('payment_status', isEqualTo: 'paid')
      .get();

    double todayRevenue = 0;
    for (var doc in todayOrders.docs) {
      todayRevenue += doc.data()['total_amount'] ?? 0;
    }

    // Get top services
    final snapshot = await ordersRef.get();
    Map<String, double> serviceUsage = {};
    for (var doc in snapshot.docs) {
      final items = List.from(doc.data()['items'] ?? []);
      for (var item in items) {
        final serviceName = item['service_name'];
        final totalPrice = item['total_price'] ?? 0;
        serviceUsage[serviceName] = (serviceUsage[serviceName] ?? 0) + totalPrice;
      }
    }

    final topServices = serviceUsage.entries
      .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DashboardData(
      totalOrders: totalOrders.count ?? 0,
      activeOrders: activeOrders.count ?? 0,
      completedOrders: 0, // Calculate
      totalCustomers: 0, // Calculate
      totalRevenue: 0, // Calculate
      todayRevenue: todayRevenue,
      revenueByDay: {},
      ordersByStatus: {},
      recentOrders: [],
      topServices: topServices.take(5).toList(),
      ordersByHour: {},
    );
  }
}
4. SPESIFIKASI TEKNIS (FLUTTER + FIREBASE)
4.1 Arsitektur Aplikasi
text
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                            │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (UI)                                   │
│  ├── Screens (Login, Dashboard, Orders, Customers, etc)   │
│  ├── Widgets (Reusable Components)                        │
│  └── Theme & Styling                                      │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (BLoC / Riverpod)                   │
│  ├── Auth Bloc                                            │
│  ├── Order Bloc                                           │
│  ├── Customer Bloc                                        │
│  ├── Subscription Bloc                                    │
│  └── Dashboard Bloc                                       │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Repository Pattern)                          │
│  ├── Auth Repository                                      │
│  ├── Order Repository                                     │
│  ├── Customer Repository                                  │
│  ├── Subscription Repository                              │
│  └── Dashboard Repository                                 │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                            │
│  ├── Firebase Auth Service                                │
│  ├── Firebase Firestore Service                           │
│  ├── Firebase Storage Service                            │
│  ├── Firebase Cloud Messaging                            │
│  └── Stripe Payment Service                              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      FIREBASE                              │
├─────────────────────────────────────────────────────────────┤
│  Firebase Auth                                            │
│  Firebase Firestore (User-Based Collections)              │
│  Firebase Storage (For Images/Files)                     │
│  Firebase Cloud Functions (Serverless)                   │
│  Firebase Cloud Messaging (Notifications)                │
└─────────────────────────────────────────────────────────────┘
4.2 Tech Stack Detailed
Komponen	Teknologi	Alasan
Frontend Framework	Flutter 3.x	Cross-platform (iOS, Android, Web), performa tinggi
State Management	Riverpod / BLoC	Reactive, testable, scalable
Backend	Firebase	Backend-as-a-Service, real-time, scalable
Database	Cloud Firestore	NoSQL, real-time, offline support
Authentication	Firebase Auth	Multi-provider auth, secure
Storage	Firebase Storage	File upload, scalable
Payments	Stripe	Global payment processing
Notifications	Firebase Cloud Messaging	Push notifications
Serverless	Firebase Cloud Functions	Backend logic, webhooks
Analytics	Firebase Analytics	User behavior tracking
4.3 Firebase Project Setup
4.3.1 Firebase Configuration
dart
// lib/core/config/firebase_config.dart
class FirebaseConfig {
  static const String apiKey = "YOUR_API_KEY";
  static const String appId = "YOUR_APP_ID";
  static const String messagingSenderId = "YOUR_MESSAGING_SENDER_ID";
  static const String projectId = "YOUR_PROJECT_ID";
  static const String authDomain = "YOUR_PROJECT_ID.firebaseapp.com";
  static const String storageBucket = "YOUR_PROJECT_ID.appspot.com";
  static const String measurementId = "YOUR_MEASUREMENT_ID";
}
4.3.2 Firebase Initialization
dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Auth
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  // Initialize Firestore with offline persistence
  await FirebaseFirestore.instance
    .enablePersistence(
      PersistenceSettings(synchronizeTabs: true),
    );

  runApp(MyApp());
}
4.4 Data Models & Repositories
4.4.1 Base Model
dart
// lib/models/base_model.dart
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();
  factory BaseModel.fromJson(String id, Map<String, dynamic> json);
}
4.4.2 Order Model
dart
// lib/models/order.dart
class Order extends BaseModel {
  final String companyId;
  final String laundryId;
  final String customerId;
  final String? employeeId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalWeight;
  final int totalItems;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final OrderStatus status;
  final List<StatusHistory> statusHistory;
  final DateTime orderDate;
  final DateTime? pickupDate;
  final DateTime? estimatedCompletion;
  final DateTime? actualCompletion;
  final DateTime? deliveryDate;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final double paidAmount;
  final String? notes;
  final String? specialInstructions;
  final PriorityLevel priorityLevel;

  Order({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.companyId,
    required this.laundryId,
    required this.customerId,
    this.employeeId,
    required this.orderNumber,
    required this.items,
    required this.totalWeight,
    required this.totalItems,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.statusHistory,
    required this.orderDate,
    this.pickupDate,
    this.estimatedCompletion,
    this.actualCompletion,
    this.deliveryDate,
    required this.paymentStatus,
    this.paymentMethod,
    required this.paidAmount,
    this.notes,
    this.specialInstructions,
    required this.priorityLevel,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'laundry_id': laundryId,
      'customer_id': customerId,
      'employee_id': employeeId,
      'order_number': orderNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'total_weight': totalWeight,
      'total_items': totalItems,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': status.name,
      'status_history': statusHistory.map((e) => e.toJson()).toList(),
      'order_date': orderDate.toIso8601String(),
      'pickup_date': pickupDate?.toIso8601String(),
      'estimated_completion': estimatedCompletion?.toIso8601String(),
      'actual_completion': actualCompletion?.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod?.name,
      'paid_amount': paidAmount,
      'notes': notes,
      'special_instructions': specialInstructions,
      'priority_level': priorityLevel.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromJson(String id, Map<String, dynamic> json) {
    return Order(
      id: id,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      companyId: json['company_id'],
      laundryId: json['laundry_id'],
      customerId: json['customer_id'],
      employeeId: json['employee_id'],
      orderNumber: json['order_number'],
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      totalWeight: json['total_weight']?.toDouble() ?? 0.0,
      totalItems: json['total_items'] ?? 0,
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      discountAmount: json['discount_amount']?.toDouble() ?? 0.0,
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      statusHistory: (json['status_history'] as List)
          .map((e) => StatusHistory.fromJson(e))
          .toList(),
      orderDate: DateTime.parse(json['order_date']),
      pickupDate: json['pickup_date'] != null
          ? DateTime.parse(json['pickup_date'])
          : null,
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.parse(json['estimated_completion'])
          : null,
      actualCompletion: json['actual_completion'] != null
          ? DateTime.parse(json['actual_completion'])
          : null,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['payment_method'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      paidAmount: json['paid_amount']?.toDouble() ?? 0.0,
      notes: json['notes'],
      specialInstructions: json['special_instructions'],
      priorityLevel: PriorityLevel.values.firstWhere(
        (e) => e.name == json['priority_level'],
        orElse: () => PriorityLevel.normal,
      ),
    );
  }
}

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  washing,
  drying,
  ironing,
  qualityCheck,
  ready,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  partial,
  paid,
  refunded,
}

enum PaymentMethod {
  cash,
  card,
  transfer,
  ewallet,
}

enum PriorityLevel {
  low,
  normal,
  high,
  urgent,
}
4.4.3 Order Repository
dart
// lib/repositories/order_repository.dart
class OrderRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  OrderRepository({required this.userId})
      : _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef =>
      _firestore.collection('users').doc(userId).collection('orders');

  // Create Order
  Future<Order> createOrder(Order order) async {
    final docRef = _ordersRef.doc();
    final newOrder = order.copyWith(id: docRef.id);

    await docRef.set(newOrder.toJson());
    return newOrder;
  }

  // Get Order by ID
  Future<Order?> getOrder(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return null;
    return Order.fromJson(doc.id, doc.data()!);
  }

  // Get All Orders
  Stream<List<Order>> getAllOrders() {
    return _ordersRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Get Orders by Status
  Stream<List<Order>> getOrdersByStatus(OrderStatus status) {
    return _ordersRef
        .where('status', isEqualTo: status.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Get Orders by Customer
  Stream<List<Order>> getOrdersByCustomer(String customerId) {
    return _ordersRef
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Update Order Status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus,
      {String? note}) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order not found');

    final statusHistory = [
      ...order.statusHistory,
      StatusHistory(
        status: newStatus,
        timestamp: DateTime.now(),
        note: note,
      ),
    ];

    await _ordersRef.doc(orderId).update({
      'status': newStatus.name,
      'status_history': statusHistory.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Update Payment Status
  Future<void> updatePaymentStatus(
    String orderId,
    PaymentStatus newStatus,
    double amount,
  ) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order not found');

    final newPaidAmount = order.paidAmount + amount;

    await _ordersRef.doc(orderId).update({
      'payment_status': newStatus.name,
      'paid_amount': newPaidAmount,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Get Orders Count by Status
  Future<int> getOrdersCountByStatus(OrderStatus status) async {
    final query = await _ordersRef
        .where('status', isEqualTo: status.name)
        .count()
        .get();
    return query.count ?? 0;
  }

  // Get Today's Orders
  Stream<List<Order>> getTodayOrders() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    return _ordersRef
        .where('created_at',
            isGreaterThanOrEqualTo: todayStart.toIso8601String())
        .where('created_at', isLessThan: todayEnd.toIso8601String())
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Delete Order (Soft Delete or Hard Delete)
  Future<void> deleteOrder(String orderId) async {
    await _ordersRef.doc(orderId).delete();
  }

  // Search Orders
  Future<List<Order>> searchOrders(String query) async {
    // Firestore doesn't support full-text search natively
    // Use Algolia or similar for production
    // Simple search on order_number
    final snapshot = await _ordersRef
        .orderBy('order_number')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();

    return snapshot.docs
        .map((doc) => Order.fromJson(doc.id, doc.data()))
        .toList();
  }
}

class StatusHistory {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }
}

class OrderItem {
  final String serviceTypeId;
  final String serviceName;
  final int quantity;
  final double weight;
  final double pricePerUnit;
  final double totalPrice;
  final String? notes;

  OrderItem({
    required this.serviceTypeId,
    required this.serviceName,
    required this.quantity,
    required this.weight,
    required this.pricePerUnit,
    required this.totalPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'service_type_id': serviceTypeId,
    'service_name': serviceName,
    'quantity': quantity,
    'weight': weight,
    'price_per_unit': pricePerUnit,
    'total_price': totalPrice,
    'notes': notes,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      serviceTypeId: json['service_type_id'],
      serviceName: json['service_name'],
      quantity: json['quantity'] ?? 0,
      weight: json['weight']?.toDouble() ?? 0.0,
      pricePerUnit: json['price_per_unit']?.toDouble() ?? 0.0,
      totalPrice: json['total_price']?.toDouble() ?? 0.0,
      notes: json['notes'],
    );
  }
}
4.5 Firebase Security Rules (Complete)
javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function getUserPath() {
      return /databases/$(database)/documents/users/$(request.auth.uid);
    }

    function hasRole(role) {
      let profile = get(/databases/$(database)/documents/users/$(request.auth.uid)/profile/$(request.auth.uid));
      return profile != null && profile.data.role == role;
    }

    function isAdmin() {
      return hasRole('admin');
    }

    // User root path
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow write: if isAuthenticated() && isOwner(userId);
    }

    // Profile
    match /users/{userId}/profile/{document} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Companies
    match /users/{userId}/companies/{companyId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Laundries
    match /users/{userId}/laundries/{laundryId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Employees
    match /users/{userId}/employees/{employeeId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Customers
    match /users/{userId}/customers/{customerId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Service Types
    match /users/{userId}/service_types/{serviceId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Orders
    match /users/{userId}/orders/{orderId} {
      allow read, write: if isAuthenticated() && isOwner(userId);

      // Validate order data on create
      allow create: if isAuthenticated() && isOwner(userId)
        && request.resource.data.keys().hasAll([
          'company_id', 'laundry_id', 'customer_id', 'items',
          'total_amount', 'status', 'order_date'
        ])
        && request.resource.data.status in [
          'pending', 'confirmed', 'in_progress', 'washing',
          'drying', 'ironing', 'quality_check', 'ready',
          'completed', 'cancelled'
        ];

      // Validate status update
      allow update: if isAuthenticated() && isOwner(userId)
        && (
          (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'status_history', 'updated_at'])) ||
          (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['payment_status', 'paid_amount', 'updated_at']))
        );
    }

    // Subscriptions
    match /users/{userId}/subscriptions/{subscriptionId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Transactions
    match /users/{userId}/transactions/{transactionId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Deny all other accesses
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
4.6 Firebase Cloud Functions
javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);

admin.initializeApp();

// Generate Order Number
exports.generateOrderNumber = functions.firestore
  .document('users/{userId}/orders/{orderId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const orderData = snap.data();
    const laundryId = orderData.laundryId;

    // Get laundry code
    const laundryDoc = await admin.firestore()
      .doc(`users/${userId}/laundries/${laundryId}`)
      .get();
    const laundryCode = laundryDoc.data().code;

    // Get today's sequence
    const today = new Date();
    const dateStr = today.toISOString().slice(0,10).replace(/-/g, '');

    const ordersRef = admin.firestore()
      .collection(`users/${userId}/orders`);

    const query = await ordersRef
      .where('order_date', '>=', new Date(today.setHours(0,0,0,0)))
      .get();

    const sequence = query.size + 1;
    const orderNumber = `${laundryCode}-${dateStr}-${String(sequence).padStart(4, '0')}`;

    await snap.ref.update({ order_number: orderNumber });
  });

// Create Stripe Checkout Session
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { planId, userId, successUrl, cancelUrl } = data;

  // Get plan details
  const planDoc = await admin.firestore()
    .collection('subscription_plans')
    .doc(planId)
    .get();

  const plan = planDoc.data();

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [{
      price: plan.stripe_price_id,
      quantity: 1,
    }],
    mode: 'subscription',
    success_url: successUrl,
    cancel_url: cancelUrl,
    metadata: {
      userId: userId,
      planId: planId,
    },
    client_reference_id: userId,
  });

  return { sessionId: session.id, url: session.url };
});

// Handle Stripe Webhook
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      functions.config().stripe.webhook_secret
    );
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object;
      await handleSuccessfulPayment(session);
      break;
    case 'customer.subscription.updated':
      const subscription = event.data.object;
      await handleSubscriptionUpdate(subscription);
      break;
    case 'customer.subscription.deleted':
      const deletedSubscription = event.data.object;
      await handleSubscriptionCancel(deletedSubscription);
      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});

async function handleSuccessfulPayment(session) {
  const userId = session.client_reference_id;
  const planId = session.metadata.planId;
  const stripeSubscriptionId = session.subscription;

  // Get subscription details
  const subscription = await stripe.subscriptions.retrieve(stripeSubscriptionId);

  // Update user's subscription in Firestore
  await admin.firestore()
    .collection(`users/${userId}/subscriptions`)
    .add({
      plan_id: planId,
      stripe_subscription_id: stripeSubscriptionId,
      stripe_customer_id: session.customer,
      status: subscription.status,
      current_period_start: new Date(subscription.current_period_start * 1000),
      current_period_end: new Date(subscription.current_period_end * 1000),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
}

async function handleSubscriptionUpdate(subscription) {
  const userId = subscription.metadata.userId;

  // Find and update the subscription in Firestore
  const subscriptionsRef = admin.firestore()
    .collection(`users/${userId}/subscriptions`);

  const query = await subscriptionsRef
    .where('stripe_subscription_id', '==', subscription.id)
    .get();

  query.docs.forEach(async (doc) => {
    await doc.ref.update({
      status: subscription.status,
      current_period_start: new Date(subscription.current_period_start * 1000),
      current_period_end: new Date(subscription.current_period_end * 1000),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function handleSubscriptionCancel(subscription) {
  const userId = subscription.metadata.userId;

  const subscriptionsRef = admin.firestore()
    .collection(`users/${userId}/subscriptions`);

  const query = await subscriptionsRef
    .where('stripe_subscription_id', '==', subscription.id)
    .get();

  query.docs.forEach(async (doc) => {
    await doc.ref.update({
      status: 'canceled',
      canceled_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}
5. USER FLOW & USER EXPERIENCE
5.1 Alur Pendaftaran & Onboarding
text
Step 1: Registrasi
User → Aplikasi Mobile → Halaman Register → Isi Form (Email, Password, Nama) → Submit

Step 2: Verifikasi Email
Sistem → Kirim Email Verifikasi → User Klik Link Verifikasi → Akun Aktif

Step 3: Setup Profile
Login Pertama Kali → Halaman Setup Profile → Isi Data Profile → Simpan
→ Data tersimpan di: users/{user_id}/profile/

Step 4: Setup Perusahaan
→ Halaman Setup Perusahaan → Isi Data Perusahaan → Simpan
→ Data tersimpan di: users/{user_id}/companies/{company_id}/

Step 5: Pilih Paket
→ Halaman Pricing → Pilih Paket (Starter/Professional/Enterprise)
→ Pilih Periode (Monthly/Yearly) → Lanjut ke Payment

Step 6: Pembayaran
→ Stripe Checkout → Input Data Kartu → Konfirmasi → Stripe Webhook
→ Status langganan tersimpan di: users/{user_id}/subscriptions/

Step 7: Setup Awal
→ Dashboard → Mulai Setup Cabang → Tambahkan Karyawan → Tambahkan Layanan
→ Siap digunakan!
5.2 Alur Pembuatan Pesanan
text
Step 1: Akses Halaman Pesanan
Login → Dashboard → Floating Action Button "Buat Pesanan Baru"

Step 2: Pilih Pelanggan
→ Cari Pelanggan Existing (Live Search)
→ Atau Tambahkan Pelanggan Baru dengan Form

Step 3: Pilih Layanan & Item
→ Pilih Jenis Layanan dari Service Types
→ Input Berat/Jumlah Item
→ Tambahkan Item Lainnya (Multiple Items)
→ Tambahkan Catatan Khusus

Step 4: Review & Konfirmasi
→ Preview Order Summary (List Items, Total Berat, Total Harga)
→ Pilih Metode Pembayaran (Cash, Card, Transfer, E-Wallet)
→ Input Status Pembayaran Awal

Step 5: Submit & Save
→ Klik "Submit Order"
→ Sistem Generate Order Number
→ Data Tersimpan di: users/{user_id}/orders/{order_id}/
→ Tampilkan Detail Pesanan
5.3 Alur Update Status Pesanan
text
Dashboard → Tab "Pesanan" → List Pesanan (Filter by Status)
→ Tap Pesanan → Halaman Detail Pesanan
→ Swipe/Tap Tombol "Update Status" (Bottom Sheet)
→ Pilih Status Baru (Flow yang diizinkan)
→ Tambahkan Catatan (Opsional) → Submit
→ Status History Tersimpan di: users/{user_id}/orders/{order_id}/status_history
→ Update di: users/{user_id}/orders/{order_id}/status
→ Notifikasi Real-time ke Pelanggan (Jika Diaktifkan)
5.4 Alur Manajemen Pelanggan
text
Menu "Pelanggan" (Tab atau Navigasi)
→ Tampilkan List Pelanggan (Search, Filter, Sort)
→ Floating Action Button "Tambah Pelanggan"
→ Form Isi Data Pelanggan (Nama, Telepon, Email, Alamat, dll)
→ Submit → Data Tersimpan di: users/{user_id}/customers/{customer_id}/
→ Tap Pelanggan → Halaman Detail Pelanggan
→ Tampilkan: Profile, Histori Pesanan, Total Belanja, Poin Loyalitas
→ Edit Pelanggan → Update Data
6. METRIK KEBERHASILAN
6.1 Metrik Utama
Metrik	Deskripsi	Target
Adopsi Pengguna	Jumlah user terdaftar dan aktif	500+ dalam 6 bulan pertama
Retensi Pelanggan	Persentase user yang memperpanjang langganan	> 75% retention rate
Efisiensi Operasional	Waktu yang dihemat dalam pembuatan pesanan	> 50% pengurangan waktu
Kepuasan Pengguna	Rating App Store/Play Store	> 4.5 bintang
Revenue	Monthly Recurring Revenue (MRR)	MRR > Rp 50 juta di bulan ke-6
6.2 Metrik Teknis
Metrik	Deskripsi	Target
App Performance	Waktu startup dan navigasi	< 2 detik
Offline Capability	Fitur berfungsi tanpa koneksi	100% untuk operasi dasar
Sync Success Rate	Sinkronisasi data berhasil	> 99.9%
Crash Rate	Aplikasi crash per session	< 0.5%
Database Read/Writes	Efisiensi query Firestore	Optimasi indeks
6.3 Metrik Bisnis
Metrik	Deskripsi	Target
MRR Growth	Pertumbuhan pendapatan bulanan	20% per bulan
Customer Acquisition Cost	Biaya perolehan pelanggan	< Rp 50.000
Lifetime Value	Nilai pelanggan seumur hidup	> Rp 2.000.000
Churn Rate	Tingkat berhenti berlangganan	< 5% per bulan
7. ROADMAP PENGEMBANGAN
Fase 1: Foundation & MVP (Bulan 1-3)
Sprint 1-2: Setup & Autentikasi
Setup Flutter project (Android, iOS, Web)

Setup Firebase project (Auth, Firestore, Storage)

Implementasi Firebase Security Rules

Implementasi Autentikasi (Email, Google, Phone)

Implementasi User Profile Management

Testing Autentikasi & Security

Sprint 3-4: Database & Data Master
Setup Firestore Collections Structure

Implementasi Models & Repositories

CRUD untuk Companies dan Laundries

CRUD untuk Employees

CRUD untuk Customers

CRUD untuk Service Types

Sprint 5-6: Core Features
CRUD untuk Orders dengan status tracking

Generate order number otomatis (Cloud Function)

Sistem pembayaran dasar (Offline)

Dashboard overview (Statistik dasar)

Integrasi Stripe untuk subscription (Cloud Functions)

Sprint 7-8: Testing & Deployment
Unit testing & Widget testing

Integration testing

Firebase Performance Monitoring

Deployment ke Play Store & App Store (Beta)

Dokumentasi & Panduan Pengguna

Fase 2: Enhancement & User Experience (Bulan 4-6)
Sprint 9-10: Real-time & Notifications
Implementasi Firestore Real-time Listeners

Push Notifications (Firebase Cloud Messaging)

Email notification system (Firebase Extensions)

In-app notification center

Sprint 11-12: Offline & Performance
Implementasi Offline Persistence (Firestore)

Data sync conflict resolution

Image upload & optimization (Firebase Storage)

Search & filter optimization (Firestore indexes)

Sprint 13-14: Analytics & Reports
Laporan keuangan (Pendapatan, Pengeluaran)

Laporan performa karyawan

Laporan popularitas layanan

Export laporan ke PDF/CSV

Firebase Analytics implementation

Fase 3: Ekspansi & Fitur Lanjutan (Bulan 7+)
Sprint 15-16: Customer Portal
Portal pelanggan (Login, Histori, Tracking)

QR Code untuk tracking pesanan

Fitur pickup & delivery scheduling

Program loyalitas & reward (Loyalty Points)

Sprint 17-18: Advanced Features
Manajemen inventaris (Supplies)

Manajemen mesin laundry (Maintenance)

WhatsApp Business API integration

Multi-language support (Indonesia, English)

Sprint 19-20: Enterprise Features
Custom branding (White-label)

API publik untuk integrasi

Advanced analytics & AI predictions

Role-based permissions yang lebih granular

Audit log untuk compliance

8. DOKUMEN PENDUKUNG & REFERENSI
8.1 Teknologi & Tools
Teknologi	URL	Deskripsi
Flutter	https://flutter.dev	UI framework cross-platform
Firebase	https://firebase.google.com	Backend-as-a-Service
Firestore	https://firebase.google.com/docs/firestore	NoSQL database
Stripe	https://stripe.com	Payment processing
Riverpod	https://riverpod.dev	State management
Dart	https://dart.dev	Programming language
8.2 Dependencies
Library	URL	Fungsi
firebase_core	pub.dev/packages/firebase_core	Firebase core
firebase_auth	pub.dev/packages/firebase_auth	Authentication
cloud_firestore	pub.dev/packages/cloud_firestore	Firestore database
firebase_storage	pub.dev/packages/firebase_storage	File storage
firebase_messaging	pub.dev/packages/firebase_messaging	Push notifications
stripe_flutter	pub.dev/packages/stripe_flutter	Stripe payment UI
riverpod	pub.dev/packages/riverpod	State management
freezed	pub.dev/packages/freezed	Code generation
8.3 Firebase Console Configuration
8.3.1 Authentication Providers
text
- Email/Password (Enabled)
- Google (Enabled with OAuth 2.0)
- Phone (Enabled)
8.3.2 Firestore Database
text
Location: asia-southeast2 (Jakarta)
Security Rules: Custom (See section 4.5)
Indexes: Create as needed for queries
8.3.3 Storage
text
Location: asia-southeast2 (Jakarta)
Security Rules: Custom for user-based access
8.3.4 Cloud Functions
text
Runtime: Node.js 18
Region: asia-southeast2
8.3.5 Stripe Configuration
text
Webhook Endpoint: https://your-domain.com/stripe-webhook
Events: checkout.session.completed, customer.subscription.updated, customer.subscription.deleted
9. LAMPIRAN
Lampiran A: Firebase Firestore Data Structure
text
users/
  └── {user_id}/
      ├── profile/
      │   └── {user_id}: {
      │         full_name: "John Doe",
      │         email: "john@email.com",
      │         phone: "+6281234567890",
      │         role: "owner",
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── companies/
      │   └── {company_id}: {
      │         name: "Laundry Bersih",
      │         address: "Jl. Merdeka No. 123",
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── laundries/
      │   └── {laundry_id}: {
      │         company_id: "company_id",
      │         name: "Cabang Merdeka",
      │         code: "JKT001",
      │         is_active: true,
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── employees/
      │   └── {employee_id}: {
      │         profile_id: "profile_id",
      │         laundry_id: "laundry_id",
      │         position: "Manager",
      │         is_active: true,
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── customers/
      │   └── {customer_id}: {
      │         full_name: "Jane Smith",
      │         phone: "+6289876543210",
      │         membership_type: "gold",
      │         total_orders: 45,
      │         total_spent: 2500000.00,
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── service_types/
      │   └── {service_id}: {
      │         name: "Cuci Kering Setrika",
      │         price_per_kg: 15000.00,
      │         estimated_duration: 24,
      │         is_active: true,
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── orders/
      │   └── {order_id}: {
      │         order_number: "JKT001-20260630-0001",
      │         customer_id: "customer_id",
      │         items: [...],
      │         total_amount: 52500.00,
      │         status: "pending",
      │         payment_status: "pending",
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      ├── subscriptions/
      │   └── {subscription_id}: {
      │         plan_id: "starter",
      │         status: "active",
      │         stripe_subscription_id: "sub_xxx",
      │         current_period_end: Timestamp,
      │         created_at: Timestamp,
      │         updated_at: Timestamp
      │       }
      │
      └── transactions/
          └── {transaction_id}: {
                order_id: "order_id",
                amount: 52500.00,
                type: "order_payment",
                status: "succeeded",
                created_at: Timestamp,
                updated_at: Timestamp
              }
Lampiran B: Flutter Project Structure
text
lib/
├── main.dart
├── core/
│   ├── config/
│   │   ├── firebase_config.dart
│   │   ├── app_config.dart
│   │   └── routes.dart
│   ├── themes/
│   │   ├── app_theme.dart
│   │   └── color_scheme.dart
│   └── utils/
│       ├── constants.dart
│       ├── formatters.dart
│       └── validators.dart
│
├── models/
│   ├── base_model.dart
│   ├── user.dart
│   ├── company.dart
│   ├── laundry.dart
│   ├── employee.dart
│   ├── customer.dart
│   ├── service_type.dart
│   ├── order.dart
│   ├── subscription.dart
│   └── transaction.dart
│
├── repositories/
│   ├── auth_repository.dart
│   ├── company_repository.dart
│   ├── laundry_repository.dart
│   ├── employee_repository.dart
│   ├── customer_repository.dart
│   ├── service_repository.dart
│   ├── order_repository.dart
│   ├── subscription_repository.dart
│   └── transaction_repository.dart
│
├── services/
│   ├── firebase/
│   │   ├── firebase_auth_service.dart
│   │   ├── firebase_firestore_service.dart
│   │   ├── firebase_storage_service.dart
│   │   └── firebase_messaging_service.dart
│   ├── payment/
│   │   └── stripe_service.dart
│   └── notification/
│       └── notification_service.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── order_provider.dart
│   ├── customer_provider.dart
│   ├── subscription_provider.dart
│   └── dashboard_provider.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── verify_email_screen.dart
│   ├── onboarding/
│   │   ├── setup_profile_screen.dart
│   │   ├── setup_company_screen.dart
│   │   └── choose_plan_screen.dart
│   ├── main/
│   │   ├── main_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── bottom_navigation.dart
│   ├── orders/
│   │   ├── orders_list_screen.dart
│   │   ├── order_detail_screen.dart
│   │   ├── create_order_screen.dart
│   │   └── update_order_status_screen.dart
│   ├── customers/
│   │   ├── customers_list_screen.dart
│   │   ├── customer_detail_screen.dart
│   │   └── create_customer_screen.dart
│   ├── employees/
│   │   ├── employees_list_screen.dart
│   │   ├── employee_detail_screen.dart
│   │   └── create_employee_screen.dart
│   ├── laundries/
│   │   ├── laundries_list_screen.dart
│   │   ├── laundry_detail_screen.dart
│   │   └── create_laundry_screen.dart
│   ├── services/
│   │   ├── services_list_screen.dart
│   │   └── create_service_screen.dart
│   ├── reports/
│   │   ├── reports_screen.dart
│   │   └── report_detail_screen.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── profile_screen.dart
│       └── subscription_screen.dart
│
├── widgets/
│   ├── common/
│   │   ├── app_button.dart
│   │   ├── app_input.dart
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   └── empty_state_widget.dart
│   ├── order/
│   │   ├── order_card.dart
│   │   ├── order_status_badge.dart
│   │   └── order_item_card.dart
│   ├── customer/
│   │   ├── customer_card.dart
│   │   └── customer_search.dart
│   └── dashboard/
│       ├── stats_card.dart
│       ├── revenue_chart.dart
│       └── recent_orders.dart
│
└── styles/
    ├── text_styles.dart
    ├── spacing.dart
    └── animations.dart
