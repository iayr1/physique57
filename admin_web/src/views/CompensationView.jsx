import React, { useState } from 'react';
import {
  Banknote,
  DollarSign,
  Search,
  Edit3,
  FileText,
  CheckCircle2,
  Clock,
  AlertCircle,
  TrendingUp,
  Award,
  Calendar,
  Sparkles,
  Printer,
  Send
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { db } from '../firebase/config';
import { doc, updateDoc, setDoc, getDoc, getDocs, query, where, collection, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';
import { useAuth } from '../context/AuthContext';

export const CompensationView = ({ employees = [] }) => {
  const { addToast } = useToast();
  const { currentUser } = useAuth();

  const [searchQuery, setSearchQuery] = useState('');
  const [deptFilter, setDeptFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('All');

  // Edit Compensation Modal State
  const [editingEmployee, setEditingEmployee] = useState(null);
  const [compForm, setCompForm] = useState({
    baseSalary: 65000,
    hraPercentage: 40,
    allowancePercentage: 15,
    pfPercentage: 8,
    overtimeRate: 500,
    monthlyIncentive: 5000,
    payStatus: 'Processed',
    payCycle: 'Monthly',
  });
  const [isUpdating, setIsUpdating] = useState(false);

  // Payslip Modal State
  const [payslipEmployee, setPayslipEmployee] = useState(null);
  const [isGeneratingPayslip, setIsGeneratingPayslip] = useState(false);

  // Department options
  const departments = ['All', ...new Set(employees.map((e) => e.department || 'General').filter(Boolean))];

  // Calculate dynamic salary components helper
  const calculateCompensation = (emp) => {
    const base = Number(emp.baseSalary ?? 65000);
    const hraPct = Number(emp.hraPercentage ?? 40);
    const allowPct = Number(emp.allowancePercentage ?? 15);
    const pfPct = Number(emp.pfPercentage ?? 8);
    const incentive = Number(emp.monthlyIncentive ?? 5000);

    const hraAmount = Math.round(base * (hraPct / 100));
    const allowanceAmount = Math.round(base * (allowPct / 100));
    const gross = base + hraAmount + allowanceAmount + incentive;

    const pfDeduction = Math.round(base * (pfPct / 100));
    const netTakeHome = gross - pfDeduction;

    return {
      base,
      hraPct,
      hraAmount,
      allowPct,
      allowanceAmount,
      pfPct,
      pfDeduction,
      incentive,
      gross,
      netTakeHome,
      overtimeRate: Number(emp.overtimeRate ?? 500),
      payStatus: emp.payStatus || 'Processed',
    };
  };

  // Filter employees
  const filteredEmployees = employees.filter((emp) => {
    const q = searchQuery.toLowerCase().trim();
    const name = (emp.name || '').toLowerCase();
    const email = (emp.email || '').toLowerCase();
    const dept = (emp.department || '').toLowerCase();

    const comp = calculateCompensation(emp);
    const matchesQuery = !q || name.includes(q) || email.includes(q) || dept.includes(q);
    const matchesDept = deptFilter === 'All' || emp.department === deptFilter;
    const matchesStatus = statusFilter === 'All' || comp.payStatus === statusFilter;

    return matchesQuery && matchesDept && matchesStatus;
  });

  // KPI Computations
  const totalPayrollBudget = employees.reduce((sum, emp) => sum + calculateCompensation(emp).gross, 0);
  const totalNetDisbursed = employees.reduce((sum, emp) => sum + calculateCompensation(emp).netTakeHome, 0);
  const totalIncentives = employees.reduce((sum, emp) => sum + calculateCompensation(emp).incentive, 0);
  const avgTakeHome = employees.length > 0 ? Math.round(totalNetDisbursed / employees.length) : 0;

  // Open Compensation Editor
  const handleOpenEdit = (emp) => {
    setEditingEmployee(emp);
    setCompForm({
      baseSalary: emp.baseSalary ?? 65000,
      hraPercentage: emp.hraPercentage ?? 40,
      allowancePercentage: emp.allowancePercentage ?? 15,
      pfPercentage: emp.pfPercentage ?? 8,
      overtimeRate: emp.overtimeRate ?? 500,
      monthlyIncentive: emp.monthlyIncentive ?? 5000,
      payStatus: emp.payStatus || 'Processed',
      payCycle: emp.payCycle || 'Monthly',
    });
  };

  // Save Compensation Updates
  const handleSaveCompensation = async (e) => {
    e.preventDefault();
    if (!editingEmployee) return;
    setIsUpdating(true);

    const targetEmail = (editingEmployee.email || '').toLowerCase().trim();
    const adminEmail = currentUser?.email || 'admin@physique57.com';

    try {
      let empRef = doc(db, 'employees', targetEmail);
      let empSnap = await getDoc(empRef);

      if (!empSnap.exists()) {
        const qSnap = await getDocs(query(collection(db, 'employees'), where('email', '==', targetEmail)));
        if (!qSnap.empty) {
          empSnap = qSnap.docs[0];
          empRef = doc(db, 'employees', empSnap.id);
        } else if (editingEmployee.id) {
          const idRef = doc(db, 'employees', editingEmployee.id);
          const idSnap = await getDoc(idRef);
          if (idSnap.exists()) {
            empRef = idRef;
          }
        }
      }

      await updateDoc(empRef, {
        baseSalary: Number(compForm.baseSalary),
        hraPercentage: Number(compForm.hraPercentage),
        allowancePercentage: Number(compForm.allowancePercentage),
        pfPercentage: Number(compForm.pfPercentage),
        overtimeRate: Number(compForm.overtimeRate),
        monthlyIncentive: Number(compForm.monthlyIncentive),
        payStatus: compForm.payStatus,
        payCycle: compForm.payCycle,
        updatedAt: serverTimestamp(),
      });

      // Audit Log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'COMPENSATION_UPDATED',
        performedBy: adminEmail,
        targetEmail: editingEmployee.email,
        details: `Salary set to ₹${compForm.baseSalary.toLocaleString('en-IN')}, Net Pay: ₹${calculateCompensation(compForm).netTakeHome.toLocaleString('en-IN')}`,
        timestamp: serverTimestamp(),
      });

      // Notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: '💰 Compensation Structure Updated',
        message: `Your monthly compensation structure has been updated by management. Net pay: ₹${calculateCompensation(compForm).netTakeHome.toLocaleString('en-IN')}`,
        requestId: '',
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: editingEmployee.email,
      });

      addToast(`✓ Updated compensation structure for ${editingEmployee.name}!`, 'success');
      setEditingEmployee(null);
    } catch (err) {
      addToast(`Failed to update compensation: ${err.message}`, 'error');
    } finally {
      setIsUpdating(false);
    }
  };

      // Audit Log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'COMPENSATION_UPDATED',
        performedBy: adminEmail,
        targetEmail: editingEmployee.email,
        details: `Salary set to ₹${compForm.baseSalary.toLocaleString('en-IN')}, Net Pay: ₹${calculateCompensation(compForm).netTakeHome.toLocaleString('en-IN')}`,
        timestamp: serverTimestamp(),
      });

      // Notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: '💰 Compensation Structure Updated',
        message: `Your monthly compensation structure has been updated by management. Net pay: ₹${calculateCompensation(compForm).netTakeHome.toLocaleString('en-IN')}`,
        requestId: '',
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: editingEmployee.email,
      });

      addToast(`✓ Updated compensation structure for ${editingEmployee.name}!`, 'success');
      setEditingEmployee(null);
    } catch (err) {
      addToast(`Failed to update compensation: ${err.message}`, 'error');
    } finally {
      setIsUpdating(false);
    }
  };

  // Generate & Dispatch Payslip to Employee
  const handleGeneratePayslip = async () => {
    if (!payslipEmployee) return;
    setIsGeneratingPayslip(true);

    const comp = calculateCompensation(payslipEmployee);
    const payrollId = `PAY-${Date.now()}`;
    const period = new Date().toLocaleDateString('en-IN', { month: 'long', year: 'numeric' });
    const adminEmail = currentUser?.email || 'admin@physique57.com';

    try {
      await setDoc(doc(db, 'payroll', payrollId), {
        id: payrollId,
        employeeEmail: payslipEmployee.email,
        employeeName: payslipEmployee.name,
        department: payslipEmployee.department || 'General',
        payPeriod: period,
        baseSalary: comp.base,
        hraAmount: comp.hraAmount,
        allowanceAmount: comp.allowanceAmount,
        incentive: comp.incentive,
        gross: comp.gross,
        pfDeduction: comp.pfDeduction,
        netTakeHome: comp.netTakeHome,
        status: 'Generated & Dispatched',
        createdAt: serverTimestamp(),
        generatedBy: adminEmail,
      });

      // Notify Employee
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `🧾 Digital Payslip Issued: ${period}`,
        message: `Your monthly digital payslip of ₹${comp.netTakeHome.toLocaleString('en-IN')} is ready.`,
        requestId: payrollId,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: payslipEmployee.email,
      });

      addToast(`✓ Digital Payslip issued to ${payslipEmployee.name} for ${period}!`, 'success');
      setPayslipEmployee(null);
    } catch (err) {
      addToast(`Failed to issue payslip: ${err.message}`, 'error');
    } finally {
      setIsGeneratingPayslip(false);
    }
  };

  // Live calculation preview during modal editing
  const previewComp = calculateCompensation(compForm);

  return (
    <div className="space-y-6">
      {/* Header & KPI Summary */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-600 text-white flex items-center justify-center font-bold shadow-xs">
                <Banknote className="w-4 h-4" />
              </div>
              <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
                Compensation & Earnings Automation
              </h3>
            </div>
            <p className="text-xs text-slate-500 mt-1 font-medium">
              Configure dynamic salary structures, allowances, PF deductions, incentives, and issue digital payslips.
            </p>
          </div>
        </div>

        {/* KPI Metrics */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-4 border-t border-slate-100">
          <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
            <p className="text-[11px] font-extrabold text-slate-500 uppercase tracking-wider">Gross Payroll</p>
            <p className="text-xl font-extrabold text-slate-900 mt-0.5 font-mono">
              ₹{totalPayrollBudget.toLocaleString('en-IN')}
            </p>
          </div>

          <div className="p-3.5 rounded-2xl bg-emerald-50/80 border border-emerald-100">
            <p className="text-[11px] font-extrabold text-emerald-700 uppercase tracking-wider">Net Disbursed</p>
            <p className="text-xl font-extrabold text-emerald-800 mt-0.5 font-mono">
              ₹{totalNetDisbursed.toLocaleString('en-IN')}
            </p>
          </div>

          <div className="p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100">
            <p className="text-[11px] font-extrabold text-blue-700 uppercase tracking-wider">Avg. Take-Home</p>
            <p className="text-xl font-extrabold text-blue-800 mt-0.5 font-mono">
              ₹{avgTakeHome.toLocaleString('en-IN')}
            </p>
          </div>

          <div className="p-3.5 rounded-2xl bg-indigo-50/80 border border-indigo-100">
            <p className="text-[11px] font-extrabold text-indigo-700 uppercase tracking-wider">Monthly Incentives</p>
            <p className="text-xl font-extrabold text-indigo-800 mt-0.5 font-mono">
              ₹{totalIncentives.toLocaleString('en-IN')}
            </p>
          </div>
        </div>
      </div>

      {/* Filters & Search Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="relative sm:col-span-1">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search employee name, email, department..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          />
        </div>

        <div>
          <select
            value={deptFilter}
            onChange={(e) => setDeptFilter(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            {departments.map((d) => (
              <option key={d} value={d}>
                Department: {d}
              </option>
            ))}
          </select>
        </div>

        <div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            <option value="All">All Payroll Statuses</option>
            <option value="Processed">Processed</option>
            <option value="Pending">Pending Audit</option>
            <option value="On Hold">On Hold</option>
          </select>
        </div>
      </div>

      {/* Employee Compensation Matrix Table */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/70 text-[10px] font-extrabold text-slate-500 uppercase tracking-wider">
                <th className="py-4 px-6">Employee Profile</th>
                <th className="py-4 px-6">Base Salary</th>
                <th className="py-4 px-6">HRA & Allowances</th>
                <th className="py-4 px-6">Deductions (PF)</th>
                <th className="py-4 px-6">Bonus / Incentive</th>
                <th className="py-4 px-6">Net Take-Home</th>
                <th className="py-4 px-6">Status</th>
                <th className="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs font-medium">
              {filteredEmployees.length === 0 ? (
                <tr>
                  <td colSpan="8" className="py-12 text-center text-slate-400">
                    No employee records match the selected compensation filters.
                  </td>
                </tr>
              ) : (
                filteredEmployees.map((emp) => {
                  const comp = calculateCompensation(emp);

                  return (
                    <tr key={emp.email || emp.id} className="hover:bg-slate-50/60 transition-colors">
                      {/* Name & Dept */}
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-600 text-white font-extrabold flex items-center justify-center text-xs shrink-0 shadow-xs">
                            {(emp.name || 'E').charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <p className="font-bold text-slate-900 text-sm">{emp.name || 'Staff Member'}</p>
                            <p className="text-slate-500 text-xs font-mono">{emp.email}</p>
                            <p className="text-[10px] text-blue-600 font-semibold">{emp.department || 'General'} • {emp.designation || 'Staff'}</p>
                          </div>
                        </div>
                      </td>

                      {/* Base Salary */}
                      <td className="py-4 px-6">
                        <p className="font-mono font-bold text-slate-900 text-sm">
                          ₹{comp.base.toLocaleString('en-IN')}
                        </p>
                        <p className="text-[10px] text-slate-400 font-medium">Monthly Base</p>
                      </td>

                      {/* HRA & Allowances */}
                      <td className="py-4 px-6">
                        <p className="font-mono font-bold text-slate-800">
                          +₹{(comp.hraAmount + comp.allowanceAmount).toLocaleString('en-IN')}
                        </p>
                        <p className="text-[10px] text-slate-500 font-medium">
                          HRA {comp.hraPct}% • Allow {comp.allowPct}%
                        </p>
                      </td>

                      {/* Deductions (PF) */}
                      <td className="py-4 px-6">
                        <p className="font-mono font-bold text-rose-600">
                          -₹{comp.pfDeduction.toLocaleString('en-IN')}
                        </p>
                        <p className="text-[10px] text-slate-400 font-medium">PF {comp.pfPct}%</p>
                      </td>

                      {/* Bonus / Incentive */}
                      <td className="py-4 px-6">
                        <p className="font-mono font-bold text-indigo-600">
                          +₹{comp.incentive.toLocaleString('en-IN')}
                        </p>
                        <p className="text-[10px] text-slate-400 font-medium">Performance</p>
                      </td>

                      {/* Net Take Home */}
                      <td className="py-4 px-6">
                        <div className="px-3 py-1.5 rounded-xl bg-emerald-50 border border-emerald-200/80 inline-block">
                          <p className="font-mono font-extrabold text-emerald-800 text-sm">
                            ₹{comp.netTakeHome.toLocaleString('en-IN')}
                          </p>
                          <p className="text-[9px] font-extrabold text-emerald-600 uppercase tracking-wider">Net Monthly</p>
                        </div>
                      </td>

                      {/* Pay Status */}
                      <td className="py-4 px-6">
                        <Badge size="sm">{comp.payStatus}</Badge>
                      </td>

                      {/* Actions */}
                      <td className="py-4 px-6 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleOpenEdit(emp)}
                            className="p-1.5 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-colors cursor-pointer"
                            title="Edit Compensation Structure"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => setPayslipEmployee(emp)}
                            className="p-1.5 text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 rounded-xl transition-colors cursor-pointer"
                            title="Generate Digital Payslip"
                          >
                            <FileText className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500 font-medium">
          <span>Showing {filteredEmployees.length} of {employees.length} employee compensation records</span>
          <span className="font-bold text-slate-700">Firebase Dynamic Cloud Sync Active</span>
        </div>
      </div>

      {/* EDIT COMPENSATION STRUCTURE MODAL */}
      <Modal
        isOpen={!!editingEmployee}
        onClose={() => setEditingEmployee(null)}
        title={`Configure Compensation: ${editingEmployee?.name || ''}`}
      >
        <form onSubmit={handleSaveCompensation} className="space-y-4">
          <div className="p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100 text-xs text-blue-900 font-medium">
            <p className="font-bold flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-blue-600" />
              Dynamic Firebase Calculation Engine
            </p>
            <p className="mt-0.5">
              Modifications are persisted to Firestore instantly and reflected live on the employee's mobile app dashboard.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Base Monthly Salary (₹) *
              </label>
              <input
                type="number"
                required
                min="0"
                value={compForm.baseSalary}
                onChange={(e) => setCompForm({ ...compForm, baseSalary: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Monthly Bonus / Incentive (₹)
              </label>
              <input
                type="number"
                min="0"
                value={compForm.monthlyIncentive}
                onChange={(e) => setCompForm({ ...compForm, monthlyIncentive: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                House Rent Allowance (HRA %)
              </label>
              <input
                type="number"
                min="0"
                max="100"
                value={compForm.hraPercentage}
                onChange={(e) => setCompForm({ ...compForm, hraPercentage: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Special Allowances %
              </label>
              <input
                type="number"
                min="0"
                max="100"
                value={compForm.allowancePercentage}
                onChange={(e) => setCompForm({ ...compForm, allowancePercentage: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Provident Fund (PF Deduction %)
              </label>
              <input
                type="number"
                min="0"
                max="50"
                value={compForm.pfPercentage}
                onChange={(e) => setCompForm({ ...compForm, pfPercentage: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Overtime Rate (₹/hr)
              </label>
              <input
                type="number"
                min="0"
                value={compForm.overtimeRate}
                onChange={(e) => setCompForm({ ...compForm, overtimeRate: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Payroll Status
              </label>
              <select
                value={compForm.payStatus}
                onChange={(e) => setCompForm({ ...compForm, payStatus: e.target.value })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              >
                <option value="Processed">Processed</option>
                <option value="Pending">Pending Audit</option>
                <option value="On Hold">On Hold</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Pay Cycle
              </label>
              <select
                value={compForm.payCycle}
                onChange={(e) => setCompForm({ ...compForm, payCycle: e.target.value })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              >
                <option value="Monthly">Monthly</option>
                <option value="Bi-Weekly">Bi-Weekly</option>
              </select>
            </div>
          </div>

          {/* Live Calculation Preview Box */}
          <div className="p-4 rounded-2xl bg-slate-900 text-white space-y-2 mt-3 shadow-soft">
            <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400">
              Live Automated Earnings Breakdown
            </p>
            <div className="grid grid-cols-3 gap-2 text-xs">
              <div>
                <p className="text-[10px] text-slate-400">Gross Earnings</p>
                <p className="font-mono font-bold text-emerald-400">₹{previewComp.gross.toLocaleString('en-IN')}</p>
              </div>
              <div>
                <p className="text-[10px] text-slate-400">Total Deductions</p>
                <p className="font-mono font-bold text-rose-400">-₹{previewComp.pfDeduction.toLocaleString('en-IN')}</p>
              </div>
              <div>
                <p className="text-[10px] text-slate-400">Net Take-Home</p>
                <p className="font-mono font-extrabold text-blue-400 text-sm">₹{previewComp.netTakeHome.toLocaleString('en-IN')}</p>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={() => setEditingEmployee(null)}
              className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isUpdating}
              className="px-5 py-2 text-xs font-bold text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 rounded-xl shadow-md shadow-blue-500/20 disabled:opacity-60 cursor-pointer"
            >
              {isUpdating ? 'Saving Structure...' : 'Save & Sync Structure'}
            </button>
          </div>
        </form>
      </Modal>

      {/* GENERATE DIGITAL PAYSLIP MODAL */}
      <Modal
        isOpen={!!payslipEmployee}
        onClose={() => setPayslipEmployee(null)}
        title={`Digital Payslip Preview: ${payslipEmployee?.name || ''}`}
      >
        {payslipEmployee && (() => {
          const comp = calculateCompensation(payslipEmployee);
          const period = new Date().toLocaleDateString('en-IN', { month: 'long', year: 'numeric' });

          return (
            <div className="space-y-4">
              <div className="p-5 rounded-3xl bg-white border border-slate-200 shadow-soft space-y-4 font-sans text-xs">
                {/* Payslip Header */}
                <div className="flex items-center justify-between pb-3 border-b border-slate-200">
                  <div>
                    <h4 className="font-extrabold text-slate-900 text-base">Physique 57 India</h4>
                    <p className="text-slate-500 text-[11px] font-medium">Enterprise Payroll Statement</p>
                  </div>
                  <div className="text-right">
                    <p className="font-bold text-blue-600 text-xs">{period}</p>
                    <Badge size="sm">{comp.payStatus}</Badge>
                  </div>
                </div>

                {/* Employee Details */}
                <div className="grid grid-cols-2 gap-3 p-3 rounded-2xl bg-slate-50 border border-slate-100 text-[11px]">
                  <div>
                    <p className="text-slate-400 font-medium">Employee Name</p>
                    <p className="font-bold text-slate-900">{payslipEmployee.name}</p>
                  </div>
                  <div>
                    <p className="text-slate-400 font-medium">Email Address</p>
                    <p className="font-bold text-slate-900 font-mono">{payslipEmployee.email}</p>
                  </div>
                  <div>
                    <p className="text-slate-400 font-medium">Department</p>
                    <p className="font-bold text-slate-900">{payslipEmployee.department || 'General'}</p>
                  </div>
                  <div>
                    <p className="text-slate-400 font-medium">Designation</p>
                    <p className="font-bold text-slate-900">{payslipEmployee.designation || 'Staff'}</p>
                  </div>
                </div>

                {/* Earnings Breakdown */}
                <div className="space-y-2">
                  <p className="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Earnings Breakdown</p>
                  <div className="space-y-1.5 font-mono text-xs">
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-600 font-sans">Basic Salary</span>
                      <span className="font-bold text-slate-900">₹{comp.base.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-600 font-sans">House Rent Allowance (HRA {comp.hraPct}%)</span>
                      <span className="font-bold text-slate-900">₹{comp.hraAmount.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-600 font-sans">Special Allowances ({comp.allowPct}%)</span>
                      <span className="font-bold text-slate-900">₹{comp.allowanceAmount.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-600 font-sans">Monthly Performance Bonus</span>
                      <span className="font-bold text-indigo-600">₹{comp.incentive.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="flex justify-between py-1 font-bold text-slate-900">
                      <span className="font-sans">Total Gross Earnings</span>
                      <span className="text-emerald-700">₹{comp.gross.toLocaleString('en-IN')}</span>
                    </div>
                  </div>
                </div>

                {/* Deductions Breakdown */}
                <div className="space-y-2 pt-2 border-t border-slate-200">
                  <p className="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Statutory Deductions</p>
                  <div className="flex justify-between font-mono text-xs text-rose-700">
                    <span className="font-sans text-slate-600">Provident Fund (PF {comp.pfPct}%)</span>
                    <span className="font-bold">-₹{comp.pfDeduction.toLocaleString('en-IN')}</span>
                  </div>
                </div>

                {/* Net Take-Home Highlight */}
                <div className="p-4 rounded-2xl bg-gradient-to-r from-slate-900 to-indigo-950 text-white flex items-center justify-between shadow-soft">
                  <div>
                    <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-300">Net Take-Home Pay</p>
                    <p className="text-xs text-slate-300 font-medium">Transferred to Bank Account</p>
                  </div>
                  <p className="text-2xl font-extrabold font-mono text-emerald-400">
                    ₹{comp.netTakeHome.toLocaleString('en-IN')}
                  </p>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setPayslipEmployee(null)}
                  className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={isGeneratingPayslip}
                  onClick={handleGeneratePayslip}
                  className="px-5 py-2 text-xs font-bold text-white bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 rounded-xl shadow-md shadow-emerald-500/20 disabled:opacity-60 cursor-pointer flex items-center gap-1.5"
                >
                  <Send className="w-3.5 h-3.5" />
                  <span>{isGeneratingPayslip ? 'Dispatching...' : 'Issue & Dispatch Digital Payslip'}</span>
                </button>
              </div>
            </div>
          );
        })()}
      </Modal>
    </div>
  );
};
