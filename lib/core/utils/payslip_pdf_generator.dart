import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/dashboard/domain/payslip_model.dart';

class PayslipPdfGenerator {
  static Future<Uint8List> generatePdfBytes(PayslipModel payslip) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber,
                  border: pw.Border.all(color: PdfColors.black, width: 2.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PHYSIQUE 57 ERMS',
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                        pw.Text(
                          'OFFICIAL SALARY PAYSLIP • ${payslip.monthYearStr.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.greenAccent700,
                        border: pw.Border.all(color: PdfColors.black, width: 1.5),
                      ),
                      child: pw.Text(
                        payslip.payStatus.toUpperCase(),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Employee Info Table
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Employee Name: ${payslip.employeeName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Email: ${payslip.employeeEmail}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Department: ${payslip.department}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Designation: ${payslip.designation}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment Date: ${payslip.paymentDate}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Transaction Reference: ${payslip.transactionId}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Earnings & Deductions Headers
              pw.Text('ITEMIZED COMPENSATION BREAKDOWN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('EARNINGS / ALLOWANCES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('DEDUCTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Row 1
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Basic Salary', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.baseSalary), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Provident Fund (PF 8%)', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.pfDeduction), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Row 2
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('House Rent Allowance (HRA 40%)', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.hraAmount), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tax / TDS Deduction', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.taxDeduction), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Row 3
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Special Allowances (15%)', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.allowanceAmount), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. 0', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Row 4
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Performance Incentive', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.monthlyIncentive), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('', style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  if (payslip.overtimePay > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Overtime Compensation', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.overtimePay), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('', style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  // Totals
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('GROSS EARNINGS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.grossSalary), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('TOTAL DEDUCTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(payslip.pfDeduction + payslip.taxDeduction), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Net Take Home Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  border: pw.Border.all(color: PdfColors.black, width: 2.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NET TAKE-HOME PAY FOR ${payslip.monthYearStr.toUpperCase()}:',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                    pw.Text(
                      currencyFormat.format(payslip.netTakeHomePay),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer Verification Stamp
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Physique 57 ERMS Automated Payroll System', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('This is a computer-generated payslip and does not require a physical signature.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text('Verified • Approved by HR & Finance', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> downloadAndPrintPdf(PayslipModel payslip) async {
    final pdfBytes = await generatePdfBytes(payslip);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Payslip_${payslip.monthYearStr.replaceAll(' ', '_')}_${payslip.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> sharePdf(PayslipModel payslip) async {
    final pdfBytes = await generatePdfBytes(payslip);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Payslip_${payslip.monthYearStr.replaceAll(' ', '_')}_${payslip.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }
}
