import React, { useState } from 'react';
import {
  Calendar,
  Search,
  Edit2,
  PlusCircle,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Sparkles,
  RefreshCw,
  Shield,
  Layers,
  ArrowRight
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { db } from '../firebase/config';
import { doc, updateDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';
import { useAuth } from '../context/AuthContext';

export const LeaveQuotaView = ({ employees = [], setTab }) => {
  const { addToast } = useToast();
  const { currentUser } = useAuth();

  const [searchQuery, setSearchQuery] = useState('');
  const [deptFilter, setDeptFilter] = useState('All');

  // Edit Quotas Modal State
  const [editingEmployee, setEditingEmployee] = useState(null);
  const [quotasForm, setQuotasForm] = useState({
    annualTotal: 18,
    annualRemaining: 18,
    casualTotal: 10,
    casualRemaining: 10,
    sickTotal: 10,
    sickRemaining: 10,
    maternityTotal: 90,
    maternityRemaining: 90,
    bereavementTotal: 5,
    bereavementRemaining: 5,
  });
  const [isUpdating, setIsUpdating] = useState(false);

  const departments = ['All', ...new Set(employees.map((e) => e.department || 'General').filter(Boolean))];

  // Filter employees
  const filteredEmployees = employees.filter((emp) => {
    const q = searchQuery.toLowerCase().trim();
    const name = (emp.name || '').toLowerCase();
    const email = (emp.email || '').toLowerCase();
    const dept = (emp.department || '').toLowerCase();

    const matchesQuery = !q || name.includes(q) || email.includes(q) || dept.includes(q);
    const matchesDept = deptFilter === 'All' || emp.department === deptFilter;

    return matchesQuery && matchesDept;
  });

  // Calculate totals across enterprise
  let totalAllocatedDays = 0;
  let totalUsedDays = 0;
  let lowQuotaCount = 0;

  employees.forEach((emp) => {
    const balances = emp.leaveBalances || {};
    const annual = balances['Annual / Paid Leave'] || { total: 18, used: 0, remaining: 18 };
    const casual = balances['Casual Leave'] || { total: 10, used: 0, remaining: 10 };
    const sick = balances['Sick Leave'] || { total: 10, used: 0, remaining: 10 };

    totalAllocatedDays += (annual.total || 18) + (casual.total || 10) + (sick.total || 10);
    totalUsedDays += (annual.used || 0) + (casual.used || 0) + (sick.used || 0);

    if ((annual.remaining || 18) <= 3 || (sick.remaining || 10) <= 1) {
      lowQuotaCount += 1;
    }
  });

  const totalRemainingDays = totalAllocatedDays - totalUsedDays;
  const utilizationPct = totalAllocatedDays > 0 ? Math.round((totalUsedDays / totalAllocatedDays) * 100) : 0;

  // Open Quotas Editor
  const handleOpenEdit = (emp) => {
    const balances = emp.leaveBalances || {};
    setEditingEmployee(emp);
    setQuotasForm({
      annualTotal: balances['Annual / Paid Leave']?.total ?? 18,
      annualRemaining: balances['Annual / Paid Leave']?.remaining ?? 18,
      casualTotal: balances['Casual Leave']?.total ?? 10,
      casualRemaining: balances['Casual Leave']?.remaining ?? 10,
      sickTotal: balances['Sick Leave']?.total ?? 10,
      sickRemaining: balances['Sick Leave']?.remaining ?? 10,
      maternityTotal: balances['Maternity / Paternity Leave']?.total ?? 90,
      maternityRemaining: balances['Maternity / Paternity Leave']?.remaining ?? 90,
      bereavementTotal: balances['Bereavement Leave']?.total ?? 5,
      bereavementRemaining: balances['Bereavement Leave']?.remaining ?? 5,
    });
  };

  // Save Quotas Updates
  const handleSaveQuotas = async (e) => {
    e.preventDefault();
    if (!editingEmployee) return;
    setIsUpdating(true);

    const docId = editingEmployee.email || editingEmployee.id;
    const adminEmail = currentUser?.email || 'admin@physique57.com';

    try {
      const updatedBalances = {
        'Annual / Paid Leave': {
          total: Number(quotasForm.annualTotal),
          used: Math.max(0, Number(quotasForm.annualTotal) - Number(quotasForm.annualRemaining)),
          remaining: Number(quotasForm.annualRemaining),
        },
        'Casual Leave': {
          total: Number(quotasForm.casualTotal),
          used: Math.max(0, Number(quotasForm.casualTotal) - Number(quotasForm.casualRemaining)),
          remaining: Number(quotasForm.casualRemaining),
        },
        'Sick Leave': {
          total: Number(quotasForm.sickTotal),
          used: Math.max(0, Number(quotasForm.sickTotal) - Number(quotasForm.sickRemaining)),
          remaining: Number(quotasForm.sickRemaining),
        },
        'Maternity / Paternity Leave': {
          total: Number(quotasForm.maternityTotal),
          used: Math.max(0, Number(quotasForm.maternityTotal) - Number(quotasForm.maternityRemaining)),
          remaining: Number(quotasForm.maternityRemaining),
        },
        'Bereavement Leave': {
          total: Number(quotasForm.bereavementTotal),
          used: Math.max(0, Number(quotasForm.bereavementTotal) - Number(quotasForm.bereavementRemaining)),
          remaining: Number(quotasForm.bereavementRemaining),
        },
        'Unpaid Leave': { total: 0, used: 0, remaining: 0 },
      };

      await updateDoc(doc(db, 'employees', docId), {
        leaveBalances: updatedBalances,
        updatedAt: serverTimestamp(),
      });

      // Audit Log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'LEAVE_QUOTAS_UPDATED',
        performedBy: adminEmail,
        targetEmail: editingEmployee.email,
        details: `Updated leave quotas for ${editingEmployee.name}. Annual Rem: ${quotasForm.annualRemaining}/${quotasForm.annualTotal}`,
        timestamp: serverTimestamp(),
      });

      // Notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: '🌴 Leave Quotas Adjusted',
        message: `Your annual leave quota balance has been updated. Annual remaining: ${quotasForm.annualRemaining} days.`,
        requestId: '',
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: editingEmployee.email,
      });

      addToast(`✓ Leave quotas updated for ${editingEmployee.name}!`, 'success');
      setEditingEmployee(null);
    } catch (err) {
      addToast(`Failed to update leave quotas: ${err.message}`, 'error');
    } finally {
      setIsUpdating(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & KPI Summary */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-bold shadow-xs">
                <Calendar className="w-4 h-4" />
              </div>
              <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
                Leave Quota & Accrual Policy Console
              </h3>
            </div>
            <p className="text-xs text-slate-500 mt-1 font-medium">
              Configure employee leave allocations, monitor quota utilization, grant bonus days, and sync live balances to Firebase.
            </p>
          </div>
        </div>

        {/* KPI Metrics */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-4 border-t border-slate-100">
          <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
            <p className="text-[11px] font-extrabold text-slate-500 uppercase tracking-wider">Allocated Days</p>
            <p className="text-xl font-extrabold text-slate-900 mt-0.5 font-mono">{totalAllocatedDays} Days</p>
          </div>

          <div className="p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100">
            <p className="text-[11px] font-extrabold text-blue-700 uppercase tracking-wider">Remaining Days</p>
            <p className="text-xl font-extrabold text-blue-800 mt-0.5 font-mono">{totalRemainingDays} Days</p>
          </div>

          <div className="p-3.5 rounded-2xl bg-indigo-50/80 border border-indigo-100">
            <p className="text-[11px] font-extrabold text-indigo-700 uppercase tracking-wider">Utilization Rate</p>
            <p className="text-xl font-extrabold text-indigo-800 mt-0.5 font-mono">{utilizationPct}%</p>
          </div>

          <div className="p-3.5 rounded-2xl bg-amber-50/80 border border-amber-100">
            <p className="text-[11px] font-extrabold text-amber-700 uppercase tracking-wider">Low Quota Alerts</p>
            <p className="text-xl font-extrabold text-amber-800 mt-0.5 font-mono">{lowQuotaCount} Staff</p>
          </div>
        </div>
      </div>

      {/* Filters & Search Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="relative sm:col-span-2">
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
      </div>

      {/* Employee Quota Matrix Table */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/70 text-[10px] font-extrabold text-slate-500 uppercase tracking-wider">
                <th className="py-4 px-6">Employee Profile</th>
                <th className="py-4 px-6">Annual Leave</th>
                <th className="py-4 px-6">Casual Leave</th>
                <th className="py-4 px-6">Sick Leave</th>
                <th className="py-4 px-6">Maternity / Paternity</th>
                <th className="py-4 px-6">Total Remaining</th>
                <th className="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs font-medium">
              {filteredEmployees.length === 0 ? (
                <tr>
                  <td colSpan="7" className="py-12 text-center text-slate-400">
                    No employee records match the selected leave quota filters.
                  </td>
                </tr>
              ) : (
                filteredEmployees.map((emp) => {
                  const balances = emp.leaveBalances || {};
                  const annual = balances['Annual / Paid Leave'] || { total: 18, used: 0, remaining: 18 };
                  const casual = balances['Casual Leave'] || { total: 10, used: 0, remaining: 10 };
                  const sick = balances['Sick Leave'] || { total: 10, used: 0, remaining: 10 };
                  const maternity = balances['Maternity / Paternity Leave'] || { total: 90, used: 0, remaining: 90 };

                  const totalRem = (annual.remaining || 0) + (casual.remaining || 0) + (sick.remaining || 0);

                  return (
                    <tr key={emp.email || emp.id} className="hover:bg-slate-50/60 transition-colors">
                      {/* Name & Dept */}
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-blue-100 text-blue-700 font-extrabold flex items-center justify-center text-xs shrink-0">
                            {(emp.name || 'E').charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <p className="font-bold text-slate-900 text-sm">{emp.name || 'Staff Member'}</p>
                            <p className="text-slate-500 text-xs font-mono">{emp.email}</p>
                            <p className="text-[10px] text-blue-600 font-semibold">{emp.department || 'General'}</p>
                          </div>
                        </div>
                      </td>

                      {/* Annual */}
                      <td className="py-4 px-6">
                        <span className="px-2.5 py-1 rounded-xl bg-blue-50 text-blue-800 border border-blue-100 font-mono font-bold">
                          {annual.remaining} / {annual.total} Days
                        </span>
                      </td>

                      {/* Casual */}
                      <td className="py-4 px-6">
                        <span className="px-2.5 py-1 rounded-xl bg-amber-50 text-amber-800 border border-amber-100 font-mono font-bold">
                          {casual.remaining} / {casual.total} Days
                        </span>
                      </td>

                      {/* Sick */}
                      <td className="py-4 px-6">
                        <span className="px-2.5 py-1 rounded-xl bg-emerald-50 text-emerald-800 border border-emerald-100 font-mono font-bold">
                          {sick.remaining} / {sick.total} Days
                        </span>
                      </td>

                      {/* Maternity */}
                      <td className="py-4 px-6">
                        <span className="px-2.5 py-1 rounded-xl bg-indigo-50 text-indigo-800 border border-indigo-100 font-mono font-bold">
                          {maternity.remaining} / {maternity.total} Days
                        </span>
                      </td>

                      {/* Total Rem */}
                      <td className="py-4 px-6">
                        <div className="font-mono font-extrabold text-slate-900 text-sm">
                          {totalRem} Days
                        </div>
                      </td>

                      {/* Actions */}
                      <td className="py-4 px-6 text-right">
                        <button
                          onClick={() => handleOpenEdit(emp)}
                          className="p-1.5 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-colors cursor-pointer"
                          title="Edit Leave Quotas & Allocation"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500 font-medium">
          <span>Showing {filteredEmployees.length} employee leave quota records</span>
          <span className="font-bold text-slate-700">Firebase Firestore Stream Connected</span>
        </div>
      </div>

      {/* EDIT LEAVE QUOTAS MODAL */}
      <Modal
        isOpen={!!editingEmployee}
        onClose={() => setEditingEmployee(null)}
        title={`Configure Leave Quotas: ${editingEmployee?.name || ''}`}
      >
        <form onSubmit={handleSaveQuotas} className="space-y-4">
          <div className="p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100 text-xs text-blue-900 font-medium">
            <p className="font-bold flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-blue-600" />
              Dynamic Firebase Quota Adjustment
            </p>
            <p className="mt-0.5">
              Updating these values immediately adjusts the employee's available leave balance in the mobile app.
            </p>
          </div>

          <div className="space-y-3">
            {/* Annual Leave */}
            <div className="p-3 rounded-2xl bg-slate-50 border border-slate-200/80 grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-bold text-slate-700 uppercase mb-1">
                  Annual Total Quota
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={quotasForm.annualTotal}
                  onChange={(e) => setQuotasForm({ ...quotasForm, annualTotal: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-xl text-xs font-mono font-bold"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold text-blue-700 uppercase mb-1">
                  Annual Remaining Days
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={quotasForm.annualRemaining}
                  onChange={(e) => setQuotasForm({ ...quotasForm, annualRemaining: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-blue-300 rounded-xl text-xs font-mono font-bold text-blue-900"
                />
              </div>
            </div>

            {/* Casual Leave */}
            <div className="p-3 rounded-2xl bg-slate-50 border border-slate-200/80 grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-bold text-slate-700 uppercase mb-1">
                  Casual Total Quota
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={quotasForm.casualTotal}
                  onChange={(e) => setQuotasForm({ ...quotasForm, casualTotal: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-xl text-xs font-mono font-bold"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold text-amber-700 uppercase mb-1">
                  Casual Remaining Days
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={quotasForm.casualRemaining}
                  onChange={(e) => setQuotasForm({ ...quotasForm, casualRemaining: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-amber-300 rounded-xl text-xs font-mono font-bold text-amber-900"
                />
              </div>
            </div>

            {/* Sick Leave */}
            <div className="p-3 rounded-2xl bg-slate-50 border border-slate-200/80 grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-bold text-slate-700 uppercase mb-1">
                  Sick Total Quota
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={quotasForm.sickTotal}
                  onChange={(e) => setQuotasForm({ ...quotasForm, sickTotal: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-xl text-xs font-mono font-bold"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold text-emerald-700 uppercase mb-1">
                  Sick Remaining Days
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={quotasForm.sickRemaining}
                  onChange={(e) => setQuotasForm({ ...quotasForm, sickRemaining: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-emerald-300 rounded-xl text-xs font-mono font-bold text-emerald-900"
                />
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
              className="px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-xs disabled:opacity-60 cursor-pointer"
            >
              {isUpdating ? 'Saving Quotas...' : 'Save & Sync Quotas'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
