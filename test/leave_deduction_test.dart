import 'package:flutter_test/flutter_test.dart';
import 'package:physique57/features/authentication/domain/employee_model.dart';

void main() {
  group('EmployeeModel & Automated Leave Management Tests', () {
    test('mayurailead@gmail.com is identified as Administrator', () {
      const admin = EmployeeModel(
        id: 'ADMIN-001',
        name: 'System Admin',
        email: 'mayurailead@gmail.com',
        department: 'Administration',
        designation: 'System Administrator',
        reportingManagerName: 'Board',
        reportingManagerEmail: 'board@company.com',
        photoUrl: '',
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
    });

    test('Regular employee has default leave balances', () {
      final employee = EmployeeModel(
        id: 'EMP-1001',
        name: 'Jane Doe',
        email: 'jane.doe@company.com',
        department: 'Engineering',
        designation: 'Software Engineer',
        reportingManagerName: 'Manager',
        reportingManagerEmail: 'manager@company.com',
        photoUrl: '',
        role: 'employee',
        leaveBalances: EmployeeModel.defaultLeaveBalances(),
      );

      expect(employee.isAdmin, isFalse);
      expect(employee.getRemainingLeave('Annual / Paid Leave'), equals(18));
      expect(employee.getTotalLeave('Annual / Paid Leave'), equals(18));
      expect(employee.getUsedLeave('Annual / Paid Leave'), equals(0));

      expect(employee.getRemainingLeave('Sick Leave'), equals(10));
      expect(employee.getRemainingLeave('Casual Leave'), equals(10));
    });

    test('Automated leave deduction calculation updates balances correctly', () {
      final initialBalances = EmployeeModel.defaultLeaveBalances();
      final emp = EmployeeModel(
        id: 'EMP-1002',
        name: 'Bob Smith',
        email: 'bob@company.com',
        department: 'Marketing',
        designation: 'Marketing Lead',
        reportingManagerName: 'Director',
        reportingManagerEmail: 'dir@company.com',
        photoUrl: '',
        role: 'employee',
        leaveBalances: initialBalances,
      );

      // Simulate approving 3 days of Annual Leave
      final updatedBalances = Map<String, dynamic>.from(emp.leaveBalances);
      final quota = Map<String, dynamic>.from(updatedBalances['Annual / Paid Leave']);
      const daysToDeduct = 3;

      final remaining = (quota['remaining'] as int) - daysToDeduct;
      final used = (quota['used'] as int) + daysToDeduct;

      quota['remaining'] = remaining;
      quota['used'] = used;
      updatedBalances['Annual / Paid Leave'] = quota;

      final updatedEmp = emp.copyWith(leaveBalances: updatedBalances);

      expect(updatedEmp.getRemainingLeave('Annual / Paid Leave'), equals(15));
      expect(updatedEmp.getUsedLeave('Annual / Paid Leave'), equals(3));
      expect(updatedEmp.getTotalLeave('Annual / Paid Leave'), equals(18));
    });
  });
}
