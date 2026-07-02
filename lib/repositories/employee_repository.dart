import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addEmployee(Employee employee) async {
    await _firestore.collection('employees').add(employee.toJson());
  }

  Stream<List<Employee>> streamEmployees() {
    return _firestore.collection('employees').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Employee.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});