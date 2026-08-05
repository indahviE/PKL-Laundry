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

  /// FIX: previously constructed Employee with `fullName`/`role`, which no
  /// longer exist on the model - blueprint §3.3.2 links an employee to
  /// their profile via `profile_id` and calls the job title `position`.
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

  /// Soft-terminate rather than delete, so historical orders/payroll still
  /// resolve `employee_id` to a real record (matches blueprint's
  /// `termination_date` field, which only makes sense if the doc survives).
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

  /// Tahap proses yang dicatat sebagai aktivitas karyawan - sama persis
  /// dengan _stagesRequiringOperator di OrderDetailScreen.
  static const _trackedActivityStages = {'washing', 'drying', 'ironing', 'qualityCheck'};

  /// Riwayat aktivitas pengerjaan tahap proses milik 1 karyawan, di-derive
  /// dari status_history semua order (bukan koleksi terpisah). Dibatasi ke
  /// [orderLimit] order TERBARU (diurutkan updated_at) supaya tidak perlu
  /// scan seluruh histori order toko - cukup untuk kebutuhan "aktivitas
  /// terkini" di halaman detail karyawan.
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
        for (final raw in rawHistory) {
          final map = Map<String, dynamic>.from(raw as Map);
          if (map['employee_id'] != employeeId) continue;
          final status = (map['status'] ?? '') as String;
          if (!_trackedActivityStages.contains(status)) continue;
          final ts = map['timestamp'];
          entries.add(EmployeeActivityEntry(
            status: status,
            orderNumber: orderNumber,
            timestamp: ts is Timestamp ? ts.toDate() : null,
          ));
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

/// Stream real-time satu dokumen karyawan berdasarkan ID, dipakai oleh
/// EmployeeDetailScreen supaya halaman detail langsung ikut ter-update
/// begitu ada perubahan di Firestore (mis. setelah terminasi).
final employeeDetailProvider = StreamProvider.family<Employee?, String>((ref, employeeId) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.streamEmployee(employeeId);
});

/// Satu entri riwayat pengerjaan tahap proses (washing/drying/ironing/
/// qualityCheck) oleh seorang karyawan, di-derive dari status_history
/// milik order - BUKAN koleksi terpisah, jadi nggak nambah model file.
class EmployeeActivityEntry {
  final String status; // 'washing' | 'drying' | 'ironing' | 'qualityCheck'
  final String orderNumber;
  final DateTime? timestamp;

  const EmployeeActivityEntry({
    required this.status,
    required this.orderNumber,
    required this.timestamp,
  });
}

/// Stream real-time riwayat aktivitas pengerjaan tahap proses milik 1
/// karyawan, dipakai oleh EmployeeDetailScreen.
final employeeActivityLogProvider =
    StreamProvider.family<List<EmployeeActivityEntry>, String>((ref, employeeId) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.streamEmployeeActivityLog(employeeId);
});