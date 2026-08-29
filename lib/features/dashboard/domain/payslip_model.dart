import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../authentication/domain/employee_model.dart';

class PayslipModel {
  final String id;
  final String employeeEmail;
  final String employeeName;
  final String department;
  final String designation;
  final String month;
  final int year;
  final String monthYearStr;
  final double baseSalary;
  final double hraAmount;
  final double allowanceAmount;
  final double monthlyIncentive;
  final double overtimePay;
  final double grossSalary;
  final double pfDeduction;
  final double taxDeduction;
  final double netTakeHomePay;
  final String payStatus;
  final String paymentDate;
  final String transactionId;

  const PayslipModel({
    required this.id,
    required this.employeeEmail,
    required this.employeeName,
    required this.department,
    required this.designation,
    required this.month,
    required this.year,
    required this.monthYearStr,
    required this.baseSalary,
    required this.hraAmount,
    required this.allowanceAmount,
    required this.monthlyIncentive,
    required this.overtimePay,
    required this.grossSalary,
    required this.pfDeduction,
    required this.taxDeduction,
    required this.netTakeHomePay,
    required this.payStatus,
    required this.paymentDate,
    required this.transactionId,
  });

  factory PayslipModel.fromEmployee(EmployeeModel employee, {required int monthsAgo}) {
    final date = DateTime.now().subtract(Duration(days: 30 * monthsAgo));
    final monthName = DateFormat('MMMM').format(date);
    final yearVal = date.year;
    final monthYear = '$monthName $yearVal';

    final base = employee.baseSalary;
    final hra = employee.hraAmount;
    final allow = employee.allowanceAmount;
    final inc = employee.monthlyIncentive;
    final ot = (monthsAgo % 2 == 0) ? 1500.0 : 0.0;
    final gross = base + hra + allow + inc + ot;
    final pf = employee.pfDeduction;
    final tax = (gross > 100000) ? 2500.0 : 0.0;
    final net = gross - pf - tax;

    final payDateStr = DateFormat('yyyy-MM-dd').format(DateTime(yearVal, date.month, 1));
    final txnId = 'TXN-P57-${100000 + (employee.email.hashCode + monthsAgo * 1000).abs() % 899999}';

    return PayslipModel(
      id: 'PAY-$yearVal-${date.month.toString().padLeft(2, '0')}-${employee.email}',
      employeeEmail: employee.email,
      employeeName: employee.name,
      department: employee.department.isNotEmpty ? employee.department : 'Physique 57 Operations',
      designation: employee.designation.isNotEmpty ? employee.designation : 'Team Member',
      month: monthName,
      year: yearVal,
      monthYearStr: monthYear,
      baseSalary: base,
      hraAmount: hra,
      allowanceAmount: allow,
      monthlyIncentive: inc,
      overtimePay: ot,
      grossSalary: gross,
      pfDeduction: pf,
      taxDeduction: tax,
      netTakeHomePay: net,
      payStatus: 'Paid',
      paymentDate: payDateStr,
      transactionId: txnId,
    );
  }

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    final base = (json['baseSalary'] as num?)?.toDouble() ?? 65000.0;
    final hra = (json['hraAmount'] as num?)?.toDouble() ?? (base * 0.40);
    final allow = (json['allowanceAmount'] as num?)?.toDouble() ?? (base * 0.15);
    final inc = (json['monthlyIncentive'] as num?)?.toDouble() ?? 5000.0;
    final ot = (json['overtimePay'] as num?)?.toDouble() ?? 0.0;
    final gross = (json['grossSalary'] as num?)?.toDouble() ?? (base + hra + allow + inc + ot);
    final pf = (json['pfDeduction'] as num?)?.toDouble() ?? (base * 0.08);
    final tax = (json['taxDeduction'] as num?)?.toDouble() ?? 0.0;
    final net = (json['netTakeHomePay'] as num?)?.toDouble() ?? (gross - pf - tax);

    return PayslipModel(
      id: json['id'] as String? ?? 'PAY-${json['year'] ?? 2026}-${json['month'] ?? 'August'}',
      employeeEmail: json['employeeEmail'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      department: json['department'] as String? ?? 'Physique 57 Operations',
      designation: json['designation'] as String? ?? 'Team Specialist',
      month: json['month'] as String? ?? 'August',
      year: (json['year'] as num?)?.toInt() ?? 2026,
      monthYearStr: json['monthYearStr'] as String? ?? '${json['month'] ?? 'August'} ${json['year'] ?? 2026}',
      baseSalary: base,
      hraAmount: hra,
      allowanceAmount: allow,
      monthlyIncentive: inc,
      overtimePay: ot,
      grossSalary: gross,
      pfDeduction: pf,
      taxDeduction: tax,
      netTakeHomePay: net,
      payStatus: json['payStatus'] as String? ?? 'Paid',
      paymentDate: json['paymentDate'] as String? ?? '2026-08-01',
      transactionId: json['transactionId'] as String? ?? 'TXN-P57-882914',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeEmail': employeeEmail,
      'employeeName': employeeName,
      'department': department,
      'designation': designation,
      'month': month,
      'year': year,
      'monthYearStr': monthYearStr,
      'baseSalary': baseSalary,
      'hraAmount': hraAmount,
      'allowanceAmount': allowanceAmount,
      'monthlyIncentive': monthlyIncentive,
      'overtimePay': overtimePay,
      'grossSalary': grossSalary,
      'pfDeduction': pfDeduction,
      'taxDeduction': taxDeduction,
      'netTakeHomePay': netTakeHomePay,
      'payStatus': payStatus,
      'paymentDate': paymentDate,
      'transactionId': transactionId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<PayslipModel> generateLast6Months(EmployeeModel employee) {
    return List.generate(6, (index) => PayslipModel.fromEmployee(employee, monthsAgo: index));
  }
}
