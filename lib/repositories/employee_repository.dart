import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  EmployeeRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _employeesRef =>
      _firestore.collection('users').doc(userId).collection('employees');

  Future<void> addEmployee(Employee employee) async {
    final docRef = _employeesRef.doc();
    final newEmployee = Employee(
      id: docRef.id,
      createdAt: employee.createdAt,
      updatedAt: employee.updatedAt,
      companyId: employee.companyId,
      laundryId: employee.laundryId,
      fullName: employee.fullName,
      role: employee.role,
      isActive: employee.isActive,
    );
    await docRef.set(newEmployee.toJson());
  }

  Stream<List<Employee>> streamEmployees() {
    return _employeesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Employee.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}

final employeeRepositoryProvider = Provider.family<EmployeeRepository, String>((ref, userId) {
  return EmployeeRepository(userId: userId);
});