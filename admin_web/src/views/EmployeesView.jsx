import React, { useState } from 'react';
import {
  Search,
  UserCheck,
  UserX,
  Edit2,
  Trash2,
  Mail,
  Shield,
  Briefcase,
  UserPlus,
  RefreshCw,
  AlertCircle,
  CheckCircle2
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { db } from '../firebase/config';
import { doc, updateDoc, deleteDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';

export const EmployeesView = ({ employees = [], setTab }) => {
  const { addToast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [deptFilter, setDeptFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('All');

  // Edit Employee State
  const [editingEmployee, setEditingEmployee] = useState(null);
  const [editFormData, setEditFormData] = useState({});
  const [isUpdating, setIsUpdating] = useState(false);

  // Delete Confirm State
  const [deletingEmployee, setDeletingEmployee] = useState(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Filtered Employees
  const departments = ['All', ...new Set(employees.map((e) => e.department || 'General').filter(Boolean))];

  const filteredEmployees = employees.filter((emp) => {
    const q = searchQuery.toLowerCase().trim();
    const name = (emp.name || '').toLowerCase();
    const email = (emp.email || '').toLowerCase();
    const dept = (emp.department || '').toLowerCase();
    const desig = (emp.designation || '').toLowerCase();

    const matchesQuery = !q || name.includes(q) || email.includes(q) || dept.includes(q) || desig.includes(q);
    const matchesDept = deptFilter === 'All' || emp.department === deptFilter;

    const isActive = emp.isActive !== false && emp.status !== 'deactivated';
    const matchesStatus =
      statusFilter === 'All' ||
      (statusFilter === 'Active' && isActive) ||
      (statusFilter === 'Deactivated' && !isActive);

    return matchesQuery && matchesDept && matchesStatus;
  });

  // Toggle Account Active/Deactivated
  const handleToggleStatus = async (emp) => {
    const currentIsActive = emp.isActive !== false && emp.status !== 'deactivated';
    const newStatus = !currentIsActive;
    const docId = emp.email || emp.id;

    try {
      await updateDoc(doc(db, 'employees', docId), {
        isActive: newStatus,
        status: newStatus ? 'active' : 'deactivated',
      });

      // Send in-app notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: newStatus ? 'Account Activated' : 'Account Deactivated',
        message: newStatus
          ? 'Your employee app access has been activated by the administrator.'
          : 'Your employee app access has been temporarily deactivated by the administrator.',
        requestId: '',
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: emp.email,
      });

      addToast(
        `${emp.name}'s login access is now ${newStatus ? 'ACTIVATED' : 'DEACTIVATED'}`,
        newStatus ? 'success' : 'error'
      );
    } catch (err) {
      addToast(`Failed to update status: ${err.message}`, 'error');
    }
  };

  // Open Edit Modal
  const handleOpenEdit = (emp) => {
    const balances = emp.leaveBalances || {};
    setEditingEmployee(emp);
    setEditFormData({
      name: emp.name || '',
      department: emp.department || '',
      designation: emp.designation || '',
      reportingManagerName: emp.reportingManagerName || '',
      reportingManagerEmail: emp.reportingManagerEmail || '',
      role: emp.role || 'employee',
      annualLeave: balances['Annual / Paid Leave']?.remaining ?? 18,
      casualLeave: balances['Casual Leave']?.remaining ?? 10,
      sickLeave: balances['Sick Leave']?.remaining ?? 10,
    });
  };

  // Save Edit Profile & Quotas
  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editingEmployee) return;
    setIsUpdating(true);

    const docId = editingEmployee.email || editingEmployee.id;

    try {
      const annualRem = parseInt(editFormData.annualLeave, 10) || 18;
      const casualRem = parseInt(editFormData.casualLeave, 10) || 10;
      const sickRem = parseInt(editFormData.sickLeave, 10) || 10;

      const updatedBalances = {
        'Annual / Paid Leave': { total: 18, used: Math.max(0, 18 - annualRem), remaining: annualRem },
        'Casual Leave': { total: 10, used: Math.max(0, 10 - casualRem), remaining: casualRem },
        'Sick Leave': { total: 10, used: Math.max(0, 10 - sickRem), remaining: sickRem },
      };

      await updateDoc(doc(db, 'employees', docId), {
        name: editFormData.name.trim(),
        department: editFormData.department.trim(),
        designation: editFormData.designation.trim(),
        reportingManagerName: editFormData.reportingManagerName.trim(),
        reportingManagerEmail: editFormData.reportingManagerEmail.trim(),
        role: editFormData.role,
        leaveBalances: updatedBalances,
      });

      addToast(`Profile for ${editFormData.name} updated successfully!`, 'success');
      setEditingEmployee(null);
    } catch (err) {
      addToast(`Update failed: ${err.message}`, 'error');
    } finally {
      setIsUpdating(false);
    }
  };

  // Confirm Delete
  const handleConfirmDelete = async () => {
    if (!deletingEmployee) return;
    setIsDeleting(true);
    const docId = deletingEmployee.email || deletingEmployee.id;

    try {
      await deleteDoc(doc(db, 'employees', docId));
      addToast(`Employee profile for ${deletingEmployee.name} deleted.`, 'success');
      setDeletingEmployee(null);
    } catch (err) {
      addToast(`Failed to delete profile: ${err.message}`, 'error');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & Controls */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
            Employee Directory & Access Management
          </h3>
          <p className="text-xs text-slate-500 mt-0.5 font-medium">
            Manage employee records, toggle app login permissions, and modify enterprise leave quotas.
          </p>
        </div>

        <button
          onClick={() => setTab(2)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-xs shrink-0 cursor-pointer"
        >
          <UserPlus className="w-4 h-4" />
          <span>+ Onboard New Employee</span>
        </button>
      </div>

      {/* Filters & Search Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {/* Search */}
        <div className="relative sm:col-span-1">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search name, email, designation..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          />
        </div>

        {/* Department Filter */}
        <div>
          <select
            value={deptFilter}
            onChange={(e) => setDeptFilter(e.target.value)}
            className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            {departments.map((d) => (
              <option key={d} value={d}>
                Department: {d}
              </option>
            ))}
          </select>
        </div>

        {/* Status Filter */}
        <div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            <option value="All">All Statuses</option>
            <option value="Active">Active Login Access</option>
            <option value="Deactivated">Deactivated Access</option>
          </select>
        </div>
      </div>

      {/* Employees Table */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/70 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                <th className="py-4 px-6">Employee</th>
                <th className="py-4 px-6">Department & Role</th>
                <th className="py-4 px-6">Reporting Manager</th>
                <th className="py-4 px-6">Leave Quotas (Rem.)</th>
                <th className="py-4 px-6">App Access</th>
                <th className="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs font-medium">
              {filteredEmployees.length === 0 ? (
                <tr>
                  <td colSpan="6" className="py-12 text-center text-slate-400">
                    No employee records match the current filters.
                  </td>
                </tr>
              ) : (
                filteredEmployees.map((emp) => {
                  const isActive = emp.isActive !== false && emp.status !== 'deactivated';
                  const balances = emp.leaveBalances || {};
                  const annual = balances['Annual / Paid Leave']?.remaining ?? 18;
                  const casual = balances['Casual Leave']?.remaining ?? 10;
                  const sick = balances['Sick Leave']?.remaining ?? 10;

                  return (
                    <tr key={emp.email || emp.id} className="hover:bg-slate-50/60 transition-colors">
                      {/* Name & Email */}
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-blue-100 text-blue-700 font-bold flex items-center justify-center text-xs shrink-0">
                            {(emp.name || 'E').substring(0, 2).toUpperCase()}
                          </div>
                          <div>
                            <p className="font-bold text-slate-900 text-sm">{emp.name || 'Unnamed Employee'}</p>
                            <p className="text-slate-500 text-xs font-mono">{emp.email}</p>
                          </div>
                        </div>
                      </td>

                      {/* Dept & Designation */}
                      <td className="py-4 px-6">
                        <p className="font-bold text-slate-800">{emp.department || 'General'}</p>
                        <p className="text-slate-500 text-[11px]">{emp.designation || 'Staff'}</p>
                      </td>

                      {/* Manager */}
                      <td className="py-4 px-6 text-slate-700">
                        <p className="font-semibold text-slate-900">{emp.reportingManagerName || '—'}</p>
                        <p className="text-slate-400 text-[11px]">{emp.reportingManagerEmail}</p>
                      </td>

                      {/* Leave Quotas */}
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-1.5 font-mono text-[11px]">
                          <span className="px-1.5 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-100" title="Annual Leave">
                            A:{annual}
                          </span>
                          <span className="px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-100" title="Casual Leave">
                            C:{casual}
                          </span>
                          <span className="px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-100" title="Sick Leave">
                            S:{sick}
                          </span>
                        </div>
                      </td>

                      {/* Status Toggle */}
                      <td className="py-4 px-6">
                        <button
                          onClick={() => handleToggleStatus(emp)}
                          className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border transition-colors cursor-pointer ${
                            isActive
                              ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-rose-50 hover:text-rose-700 hover:border-rose-200'
                              : 'bg-rose-50 text-rose-700 border-rose-200 hover:bg-emerald-50 hover:text-emerald-700 hover:border-emerald-200'
                          }`}
                          title="Click to toggle mobile login access"
                        >
                          {isActive ? <UserCheck className="w-3.5 h-3.5" /> : <UserX className="w-3.5 h-3.5" />}
                          <span>{isActive ? 'Active' : 'Deactivated'}</span>
                        </button>
                      </td>

                      {/* Action buttons */}
                      <td className="py-4 px-6 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleOpenEdit(emp)}
                            className="p-1.5 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="Edit Profile & Quotas"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => setDeletingEmployee(emp)}
                            className="p-1.5 text-slate-500 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                            title="Delete Profile"
                          >
                            <Trash2 className="w-4 h-4" />
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

        {/* Footer info */}
        <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500 font-medium">
          <span>Showing {filteredEmployees.length} of {employees.length} employees</span>
          <span>Instant sync with ERMS Mobile App</span>
        </div>
      </div>

      {/* Edit Profile & Quotas Modal */}
      <Modal
        isOpen={!!editingEmployee}
        onClose={() => setEditingEmployee(null)}
        title={`Edit Profile: ${editingEmployee?.name || ''}`}
      >
        <form onSubmit={handleSaveEdit} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Full Name
              </label>
              <input
                type="text"
                value={editFormData.name || ''}
                onChange={(e) => setEditFormData({ ...editFormData, name: e.target.value })}
                required
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Department
              </label>
              <input
                type="text"
                value={editFormData.department || ''}
                onChange={(e) => setEditFormData({ ...editFormData, department: e.target.value })}
                required
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Designation / Job Title
              </label>
              <input
                type="text"
                value={editFormData.designation || ''}
                onChange={(e) => setEditFormData({ ...editFormData, designation: e.target.value })}
                required
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                App Role
              </label>
              <select
                value={editFormData.role || 'employee'}
                onChange={(e) => setEditFormData({ ...editFormData, role: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              >
                <option value="employee">Employee</option>
                <option value="manager">Manager / Lead</option>
                <option value="admin">Administrator</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Reporting Manager Name
              </label>
              <input
                type="text"
                value={editFormData.reportingManagerName || ''}
                onChange={(e) => setEditFormData({ ...editFormData, reportingManagerName: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Reporting Manager Email
              </label>
              <input
                type="email"
                value={editFormData.reportingManagerEmail || ''}
                onChange={(e) => setEditFormData({ ...editFormData, reportingManagerEmail: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>
          </div>

          {/* Leave Quotas Box */}
          <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 mt-2">
            <h4 className="text-xs font-bold text-slate-900 uppercase tracking-wider mb-3">
              Remaining Leave Quotas (Days)
            </h4>
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="block text-[11px] font-bold text-slate-600 mb-1">Annual Leave</label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={editFormData.annualLeave}
                  onChange={(e) => setEditFormData({ ...editFormData, annualLeave: e.target.value })}
                  className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono font-bold text-center"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold text-slate-600 mb-1">Casual Leave</label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={editFormData.casualLeave}
                  onChange={(e) => setEditFormData({ ...editFormData, casualLeave: e.target.value })}
                  className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono font-bold text-center"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold text-slate-600 mb-1">Sick Leave</label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={editFormData.sickLeave}
                  onChange={(e) => setEditFormData({ ...editFormData, sickLeave: e.target.value })}
                  className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono font-bold text-center"
                />
              </div>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
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
              className="px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-xs disabled:opacity-60"
            >
              {isUpdating ? 'Saving Changes...' : 'Save Profile & Quotas'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deletingEmployee}
        onClose={() => setDeletingEmployee(null)}
        title="Delete Employee Profile?"
      >
        <div className="space-y-4">
          <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div className="text-xs text-rose-800">
              <p className="font-bold">Permanent Deletion Warning</p>
              <p className="mt-0.5">
                Are you sure you want to permanently delete the profile of{' '}
                <strong className="font-extrabold">{deletingEmployee?.name}</strong> ({deletingEmployee?.email})?
                They will lose all access, request histories, and leave quotas.
              </p>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={() => setDeletingEmployee(null)}
              className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100"
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={isDeleting}
              onClick={handleConfirmDelete}
              className="px-5 py-2 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-xs disabled:opacity-60"
            >
              {isDeleting ? 'Deleting...' : 'Confirm Delete Profile'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
