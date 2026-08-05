import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import '../providers/auth_provider.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  EmployeeRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _employeesRef =>
      _firestore.collection('users').doc(userId).collection('employees');

  Future<Employee> addEmployee(Employee employee) async {
    final docRef = _employeesRef.doc();
    final now = DateTime.now();
    final newEmployee = Employee(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      companyId: employee.companyId,
      laundryId: employee.laundryId,
      profileId: employee.profileId,
      employeeCode: employee.employeeCode,
      position: employee.position,
      phone: employee.phone,
      email: employee.email,
      address: employee.address,
      salary: employee.salary,
      commissionRate: employee.commissionRate,
      hireDate: employee.hireDate ?? now,
      terminationDate: employee.terminationDate,
      isActive: employee.isActive,
      permissions: employee.permissions,
    );
    await docRef.set(newEmployee.toJson());
    return newEmployee;
  }

  Future<Employee?> getEmployee(String employeeId) async {
    final doc = await _employeesRef.doc(employeeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Employee.fromJson(doc.data()!, doc.id);
  }

  /// Stream satu dokumen karyawan (real-time), dipakai halaman detail.
  Stream<Employee?> streamEmployee(String employeeId) {
    return _employeesRef.doc(employeeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Employee.fromJson(doc.data()!, doc.id);
    });
  }

  Stream<List<Employee>> streamEmployees() {
    return _employeesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Employee.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Employee>> streamEmployeesByLaundry(String laundryId) {
    return _employeesRef
        .where('laundry_id', isEqualTo: laundryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Employee.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> updateEmployee(String employeeId, Map<String, dynamic> data) async {
    await _employeesRef.doc(employeeId).update({
      ...data,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> terminateEmployee(String employeeId) async {
    await _employeesRef.doc(employeeId).update({
      'is_active': false,
      'termination_date': DateTime.now(),
      'updated_at': DateTime.now(),
    });
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _employeesRef.doc(employeeId).delete();
  }

  /// Tahap proses operasional biasa + aktivitas kurir
  static const _trackedActivityStages = {
    'washing',
    'drying',
    'ironing',
    'qualityCheck',
    'delivered',
    'delivery',
    'courier'
  };

  /// Riwayat aktivitas pengerjaan tahap proses & pengantaran kurir milik 1 karyawan
  Stream<List<EmployeeActivityEntry>> streamEmployeeActivityLog(
    String employeeId, {
    int orderLimit = 60,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('updated_at', descending: true)
        .limit(orderLimit)
        .snapshots()
        .map((snapshot) {
      final entries = <EmployeeActivityEntry>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final orderNumber = (data['order_number'] ?? doc.id) as String;
        final rawHistory = (data['status_history'] as List?) ?? [];
        final courierId = data['courier_id'] ?? data['courierId'];

        // 1. Cek dari status_history (Operator Cuci, Pengering, Setrika, QC, & Kurir jika dicatatkan di history)
        for (final raw in rawHistory) {
          final map = Map<String, dynamic>.from(raw as Map);
          final status = (map['status'] ?? '') as String;
          final empId = map['employee_id'] ?? map['employeeId'];

          if (empId == employeeId && _trackedActivityStages.contains(status)) {
            final ts = map['timestamp'];
            entries.add(EmployeeActivityEntry(
              status: status == 'delivered' || status == 'delivery' ? 'courier' : status,
              orderNumber: orderNumber,
              timestamp: ts is Timestamp ? ts.toDate() : null,
            ));
          }
        }

        // 2. Cek khusus aktivitas kurir berdasarkan courierId di order (misal lewat markDelivered)
        if (courierId == employeeId) {
          final orderStatus = (data['status'] ?? '') as String;
          final deliveredAt = data['delivery_date'] ?? data['delivered_at'] ?? data['deliveredAt'];
          if (orderStatus == 'delivered' || orderStatus == 'completed' || deliveredAt != null) {
            final ts = data['delivered_at'] ?? data['updated_at'];
            // Hindari duplikasi jika sudah ter-track di status_history
            final isAlreadyAdded = entries.any((e) => e.orderNumber == orderNumber && e.status == 'courier');
            if (!isAlreadyAdded) {
              entries.add(EmployeeActivityEntry(
                status: 'courier',
                orderNumber: orderNumber,
                timestamp: ts is Timestamp ? ts.toDate() : null,
              ));
            }
          }
        }
      }

      entries.sort((a, b) {
        final ta = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return entries;
    });
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return EmployeeRepository(userId: userId);
});

final employeeDetailProvider = StreamProvider.family<Employee?, String>((ref, employeeId) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.streamEmployee(employeeId);
});

class EmployeeActivityEntry {
  final String status; // 'washing' | 'drying' | 'ironing' | 'qualityCheck' | 'courier'
  final String orderNumber;
  final DateTime? timestamp;

  const EmployeeActivityEntry({
    required this.status,
    required this.orderNumber,
    required this.timestamp,
  });
}

final employeeActivityLogProvider =
    StreamProvider.family<List<EmployeeActivityEntry>, String>((ref, employeeId) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.streamEmployeeActivityLog(employeeId);
});