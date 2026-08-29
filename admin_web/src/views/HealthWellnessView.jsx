import React, { useState, useEffect } from 'react';
import {
  HeartPulse,
  Shield,
  Search,
  Edit3,
  PhoneCall,
  Activity,
  FileCheck2,
  CheckCircle2,
  AlertCircle,
  PlusCircle,
  Sparkles,
  Hospital,
  User,
  DollarSign
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { db } from '../firebase/config';
import { collection, onSnapshot, doc, updateDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';
import { useAuth } from '../context/AuthContext';

export const HealthWellnessView = ({ employees = [] }) => {
  const { addToast } = useToast();
  const { currentUser } = useAuth();

  const [searchQuery, setSearchQuery] = useState('');
  const [deptFilter, setDeptFilter] = useState('All');

  // Medical Claims Stream
  const [medicalClaims, setMedicalClaims] = useState([]);

  // Edit Employee Health Profile State
  const [editingEmployee, setEditingEmployee] = useState(null);
  const [healthForm, setHealthForm] = useState({
    mediclaimId: '',
    coverageAmount: 500000,
    bloodGroup: 'O+',
    emergencyContactName: '',
    emergencyContactPhone: '',
    wellnessAllowance: 15000,
    healthCheckupDone: true,
  });
  const [isUpdating, setIsUpdating] = useState(false);

  // Department options
  const departments = ['All', ...new Set(employees.map((e) => e.department || 'General').filter(Boolean))];

  // Subscribe to medical_claims collection
  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'medical_claims'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.createdAt?.toDate?.() || new Date(0)) - (a.createdAt?.toDate?.() || new Date(0)));
      setMedicalClaims(list);
    });
    return () => unsub();
  }, []);

  // Filtered Employees
  const filteredEmployees = employees.filter((emp) => {
    const q = searchQuery.toLowerCase().trim();
    const name = (emp.name || '').toLowerCase();
    const email = (emp.email || '').toLowerCase();
    const dept = (emp.department || '').toLowerCase();

    const matchesQuery = !q || name.includes(q) || email.includes(q) || dept.includes(q);
    const matchesDept = deptFilter === 'All' || emp.department === deptFilter;

    return matchesQuery && matchesDept;
  });

  // Calculate Health Profile helper
  const getHealthProfile = (emp) => {
    const hp = emp.healthProfile || {};
    return {
      mediclaimId: hp.mediclaimId || `PHY57-MED-${Math.abs(emp.email?.hashCode || 9402) % 8999 + 1000}`,
      coverageAmount: Number(hp.coverageAmount ?? 500000),
      bloodGroup: hp.bloodGroup || 'O+',
      emergencyContactName: hp.emergencyContactName || emp.reportingManagerName || 'Family Contact',
      emergencyContactPhone: hp.emergencyContactPhone || '+91 98765 43210',
      wellnessAllowance: Number(hp.wellnessAllowance ?? 15000),
      healthCheckupDone: hp.healthCheckupDone !== false,
    };
  };

  // Open Health Profile Editor
  const handleOpenEdit = (emp) => {
    const hp = getHealthProfile(emp);
    setEditingEmployee(emp);
    setHealthForm({
      mediclaimId: hp.mediclaimId,
      coverageAmount: hp.coverageAmount,
      bloodGroup: hp.bloodGroup,
      emergencyContactName: hp.emergencyContactName,
      emergencyContactPhone: hp.emergencyContactPhone,
      wellnessAllowance: hp.wellnessAllowance,
      healthCheckupDone: hp.healthCheckupDone,
    });
  };

  // Save Health Profile
  const handleSaveHealthProfile = async (e) => {
    e.preventDefault();
    if (!editingEmployee) return;
    setIsUpdating(true);

    const docId = editingEmployee.email || editingEmployee.id;
    const adminEmail = currentUser?.email || 'admin@physique57.com';

    try {
      const updatedHealthProfile = {
        mediclaimId: healthForm.mediclaimId.trim(),
        coverageAmount: Number(healthForm.coverageAmount),
        bloodGroup: healthForm.bloodGroup,
        emergencyContactName: healthForm.emergencyContactName.trim(),
        emergencyContactPhone: healthForm.emergencyContactPhone.trim(),
        wellnessAllowance: Number(healthForm.wellnessAllowance),
        healthCheckupDone: healthForm.healthCheckupDone,
        updatedAt: new Date().toISOString(),
      };

      await updateDoc(doc(db, 'employees', docId), {
        healthProfile: updatedHealthProfile,
      });

      // Audit Log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'HEALTH_PROFILE_UPDATED',
        performedBy: adminEmail,
        targetEmail: editingEmployee.email,
        details: `Mediclaim Card ID: ${healthForm.mediclaimId}, Emergency Contact: ${healthForm.emergencyContactName}`,
        timestamp: serverTimestamp(),
      });

      addToast(`✓ Health profile updated for ${editingEmployee.name}!`, 'success');
      setEditingEmployee(null);
    } catch (err) {
      addToast(`Failed to update health profile: ${err.message}`, 'error');
    } finally {
      setIsUpdating(false);
    }
  };

  // Approve Medical Claim
  const handleApproveClaim = async (claim) => {
    try {
      await updateDoc(doc(db, 'medical_claims', claim.id), {
        status: 'Approved & Disbursed',
        approvedAt: serverTimestamp(),
      });

      // Send Notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: '🩺 Medical Claim Approved',
        message: `Your medical reimbursement claim of ₹${claim.amount?.toLocaleString('en-IN')} has been approved by HR & Insurance desk.`,
        requestId: claim.id,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: claim.employeeEmail,
      });

      addToast(`✓ Approved medical claim ${claim.id}!`, 'success');
    } catch (err) {
      addToast(`Failed to approve claim: ${err.message}`, 'error');
    }
  };

  const pendingClaimsCount = medicalClaims.filter((c) => (c.status || '').toLowerCase().includes('pending')).length;

  return (
    <div className="space-y-6">
      {/* Policy Master Header */}
      <div className="bg-gradient-to-r from-rose-900 via-slate-900 to-indigo-950 rounded-3xl p-6 text-white shadow-soft-lg border border-white/10 space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-rose-500/20 backdrop-blur-md text-xs font-bold text-rose-200 border border-rose-400/30 mb-2">
              <Shield className="w-3.5 h-3.5 text-rose-300" />
              <span>Physique 57 Corporate Group Insurance</span>
            </div>
            <h3 className="text-2xl font-extrabold tracking-tight">
              Group Mediclaim & Health Policy Console
            </h3>
            <p className="text-xs text-rose-100/80 mt-1 font-medium max-w-xl">
              Manage corporate group health coverage (Policy #PHY57-GMC-2026), employee medical cards, emergency hotlines, and medical claims.
            </p>
          </div>

          <div className="p-3.5 rounded-2xl bg-white/10 backdrop-blur-md border border-white/15 text-xs text-right">
            <p className="text-slate-300 font-medium">TPA 24x7 Emergency Line</p>
            <p className="font-extrabold text-base text-rose-300 font-mono">1800-PHY-57HEALTH</p>
            <p className="text-[10px] text-slate-400 font-medium">450+ Cashless Network Hospitals</p>
          </div>
        </div>

        {/* Policy Stats */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-3 border-t border-white/10 text-xs">
          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <p className="text-slate-400 text-[10px] uppercase font-bold">Total Insured Lives</p>
            <p className="text-xl font-extrabold text-white mt-0.5 font-mono">{employees.length} Staff</p>
          </div>
          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <p className="text-slate-400 text-[10px] uppercase font-bold">Base Coverage Cap</p>
            <p className="text-xl font-extrabold text-emerald-400 mt-0.5 font-mono">₹5,00,000</p>
          </div>
          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <p className="text-slate-400 text-[10px] uppercase font-bold">Wellness Allowance</p>
            <p className="text-xl font-extrabold text-indigo-300 mt-0.5 font-mono">₹15,000 / Yr</p>
          </div>
          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <p className="text-slate-400 text-[10px] uppercase font-bold">Pending Medical Claims</p>
            <p className="text-xl font-extrabold text-rose-400 mt-0.5 font-mono">{pendingClaimsCount} Claims</p>
          </div>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="relative sm:col-span-2">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search employee, Mediclaim ID, emergency contact..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-rose-500 shadow-soft"
          />
        </div>

        <div>
          <select
            value={deptFilter}
            onChange={(e) => setDeptFilter(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-rose-500 shadow-soft"
          >
            {departments.map((d) => (
              <option key={d} value={d}>
                Department: {d}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Employee Health Matrix Table */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/70 text-[10px] font-extrabold text-slate-500 uppercase tracking-wider">
                <th className="py-4 px-6">Insured Employee</th>
                <th className="py-4 px-6">Mediclaim Card ID</th>
                <th className="py-4 px-6">Coverage Cap</th>
                <th className="py-4 px-6">Blood Group</th>
                <th className="py-4 px-6">Emergency Contact</th>
                <th className="py-4 px-6">Checkup Status</th>
                <th className="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs font-medium">
              {filteredEmployees.length === 0 ? (
                <tr>
                  <td colSpan="7" className="py-12 text-center text-slate-400">
                    No employee health records match the search query.
                  </td>
                </tr>
              ) : (
                filteredEmployees.map((emp) => {
                  const hp = getHealthProfile(emp);

                  return (
                    <tr key={emp.email || emp.id} className="hover:bg-slate-50/60 transition-colors">
                      {/* Name & Dept */}
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-rose-100 text-rose-700 font-extrabold flex items-center justify-center text-xs shrink-0">
                            {(emp.name || 'E').charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <p className="font-bold text-slate-900 text-sm">{emp.name || 'Staff Member'}</p>
                            <p className="text-slate-500 text-xs font-mono">{emp.email}</p>
                            <p className="text-[10px] text-rose-600 font-semibold">{emp.department || 'General'}</p>
                          </div>
                        </div>
                      </td>

                      {/* Mediclaim Card ID */}
                      <td className="py-4 px-6">
                        <span className="font-mono font-bold text-slate-900 text-xs px-2.5 py-1 rounded-xl bg-slate-100 border border-slate-200">
                          {hp.mediclaimId}
                        </span>
                      </td>

                      {/* Coverage Cap */}
                      <td className="py-4 px-6">
                        <p className="font-mono font-bold text-emerald-700 text-sm">
                          ₹{hp.coverageAmount.toLocaleString('en-IN')}
                        </p>
                        <p className="text-[10px] text-slate-400">Annual Cashless</p>
                      </td>

                      {/* Blood Group */}
                      <td className="py-4 px-6">
                        <span className="px-2 py-0.5 rounded-lg bg-rose-50 text-rose-700 font-extrabold border border-rose-200 text-xs font-mono">
                          {hp.bloodGroup}
                        </span>
                      </td>

                      {/* Emergency Contact */}
                      <td className="py-4 px-6">
                        <p className="font-bold text-slate-900">{hp.emergencyContactName}</p>
                        <p className="text-slate-500 text-xs font-mono">{hp.emergencyContactPhone}</p>
                      </td>

                      {/* Health Checkup */}
                      <td className="py-4 px-6">
                        <Badge variant={hp.healthCheckupDone ? 'success' : 'warning'} size="sm">
                          {hp.healthCheckupDone ? 'Completed' : 'Pending'}
                        </Badge>
                      </td>

                      {/* Actions */}
                      <td className="py-4 px-6 text-right">
                        <button
                          onClick={() => handleOpenEdit(emp)}
                          className="p-1.5 text-slate-500 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors cursor-pointer"
                          title="Edit Employee Health Profile & Insurance Card"
                        >
                          <Edit3 className="w-4 h-4" />
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
          <span>Showing {filteredEmployees.length} employee health insurance profiles</span>
          <span className="font-bold text-slate-700">Firebase Cloud Real-Time Active</span>
        </div>
      </div>

      {/* EDIT HEALTH PROFILE MODAL */}
      <Modal
        isOpen={!!editingEmployee}
        onClose={() => setEditingEmployee(null)}
        title={`Edit Health & Insurance Profile: ${editingEmployee?.name || ''}`}
      >
        <form onSubmit={handleSaveHealthProfile} className="space-y-4">
          <div className="p-3.5 rounded-2xl bg-rose-50/80 border border-rose-100 text-xs text-rose-900 font-medium">
            <p className="font-bold flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-rose-600" />
              Corporate Group Insurance Sync
            </p>
            <p className="mt-0.5">
              Health profile updates are saved to Firebase and automatically synced to the employee's mobile digital insurance card.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Mediclaim Card ID *
              </label>
              <input
                type="text"
                required
                value={healthForm.mediclaimId}
                onChange={(e) => setHealthForm({ ...healthForm, mediclaimId: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Annual Coverage Cap (₹)
              </label>
              <input
                type="number"
                min="0"
                value={healthForm.coverageAmount}
                onChange={(e) => setHealthForm({ ...healthForm, coverageAmount: Number(e.target.value) })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Blood Group
              </label>
              <select
                value={healthForm.bloodGroup}
                onChange={(e) => setHealthForm({ ...healthForm, bloodGroup: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
              >
                {['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].map((bg) => (
                  <option key={bg} value={bg}>
                    {bg}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Wellness Allowance (₹/Yr)
              </label>
              <input
                type="number"
                min="0"
                value={healthForm.wellnessAllowance}
                onChange={(e) => setHealthForm({ ...healthForm, wellnessAllowance: Number(e.target.value) })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Emergency Contact Name
              </label>
              <input
                type="text"
                required
                value={healthForm.emergencyContactName}
                onChange={(e) => setHealthForm({ ...healthForm, emergencyContactName: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Emergency Contact Phone
              </label>
              <input
                type="text"
                required
                value={healthForm.emergencyContactPhone}
                onChange={(e) => setHealthForm({ ...healthForm, emergencyContactPhone: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
              />
            </div>
          </div>

          <div className="flex items-center gap-2 pt-2">
            <input
              type="checkbox"
              id="checkupDone"
              checked={healthForm.healthCheckupDone}
              onChange={(e) => setHealthForm({ ...healthForm, healthCheckupDone: e.target.checked })}
              className="h-4 w-4 rounded-md text-rose-600 focus:ring-rose-500 border-slate-300"
            />
            <label htmlFor="checkupDone" className="text-xs font-bold text-slate-800 cursor-pointer">
              Annual Health & Fitness Checkup Completed
            </label>
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
              className="px-5 py-2 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-xs disabled:opacity-60 cursor-pointer"
            >
              {isUpdating ? 'Saving Profile...' : 'Save Health Profile'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
