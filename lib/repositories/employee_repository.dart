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