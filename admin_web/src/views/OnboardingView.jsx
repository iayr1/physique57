import React, { useState } from 'react';
import {
  UserPlus,
  Mail,
  Lock,
  Building,
  Briefcase,
  UserCheck,
  Sparkles,
  CheckCircle2,
  Copy,
  Check,
  ShieldCheck,
  CalendarCheck
} from 'lucide-react';
import { db } from '../firebase/config';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';
import { Modal } from '../components/Modal';

export const OnboardingView = ({ setTab }) => {
  const { addToast } = useToast();

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: 'Password@123',
    department: 'Engineering & Product',
    designation: 'Software Engineer',
    reportingManagerName: 'Management Board',
    reportingManagerEmail: 'admin@gmail.com',
    role: 'employee',
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [successData, setSuccessData] = useState(null);
  const [copied, setCopied] = useState(false);

  const departmentsList = [
    'Engineering & Product',
    'Human Resources (HR)',
    'Finance & Accounting',
    'Operations & Facilities',
    'Sales & Marketing',
    'Customer Experience',
    'Legal & Compliance',
    'Executive Leadership',
  ];

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.email.trim()) {
      addToast('Please fill out all required fields.', 'error');
      return;
    }

    setIsSubmitting(true);
    const cleanEmail = formData.email.trim().toLowerCase();
    const empId = `EMP-${1000 + (Math.abs(cleanEmail.split('').reduce((a, b) => (a << 5) - a + b.charCodeAt(0), 0)) % 8999)}`;

    try {
      const defaultLeaveBalances = {
        'Annual / Paid Leave': { total: 18, used: 0, remaining: 18 },
        'Casual Leave': { total: 10, used: 0, remaining: 10 },
        'Sick Leave': { total: 10, used: 0, remaining: 10 },
      };

      const employeeDoc = {
        id: empId,
        name: formData.name.trim(),
        email: cleanEmail,
        password: formData.password,
        department: formData.department.trim(),
        designation: formData.designation.trim(),
        reportingManagerName: formData.reportingManagerName.trim() || 'Management Board',
        reportingManagerEmail: formData.reportingManagerEmail.trim() || 'admin@gmail.com',
        role: formData.role,
        isActive: true,
        status: 'active',
        leaveBalances: defaultLeaveBalances,
        createdAt: serverTimestamp(),
      };

      // Write to Firestore employees collection
      await setDoc(doc(db, 'employees', cleanEmail), employeeDoc);

      // Create welcome notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `Welcome to Physique 57 ERMS!`,
        message: `Your employee portal account is active. 18 Annual, 10 Casual, and 10 Sick leave quotas allocated.`,
        requestId: empId,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: cleanEmail,
      });

      // Record audit log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'EMPLOYEE_ONBOARDED',
        performedBy: 'admin@gmail.com',
        targetEmail: cleanEmail,
        details: `Name: ${formData.name}, Dept: ${formData.department}, ID: ${empId}`,
        timestamp: serverTimestamp(),
      });

      addToast(`✓ Successfully onboarded ${formData.name}!`, 'success');

      setSuccessData({
        name: formData.name,
        email: cleanEmail,
        password: formData.password,
        id: empId,
        department: formData.department,
      });

      // Reset form
      setFormData({
        name: '',
        email: '',
        password: 'Password@123',
        department: 'Engineering & Product',
        designation: 'Software Engineer',
        reportingManagerName: 'Management Board',
        reportingManagerEmail: 'admin@gmail.com',
        role: 'employee',
      });
    } catch (err) {
      addToast(`Onboarding failed: ${err.message}`, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const copyCredentials = () => {
    if (!successData) return;
    const text = `Physique 57 ERMS Account Details\nName: ${successData.name}\nEmployee ID: ${successData.id}\nEmail: ${successData.email}\nInitial Password: ${successData.password}\nDepartment: ${successData.department}`;
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
    addToast('Credentials copied to clipboard!', 'success');
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Top Banner */}
      <div className="bg-white rounded-3xl p-6 sm:p-8 border border-slate-200/80 shadow-soft flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-bold mb-2 border border-blue-100">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Automated Quota Provisioning Active</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
            Onboard New Organization Staff Member
          </h2>
          <p className="text-xs sm:text-sm text-slate-500 font-medium mt-1">
            Fill in the employee details below. The system automatically initializes standard leave quotas and enables mobile app sign-in.
          </p>
        </div>
      </div>

      {/* Onboarding Form Card */}
      <div className="bg-white rounded-3xl p-6 sm:p-8 border border-slate-200/80 shadow-soft">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Section 1: Basic Identity */}
          <div>
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <UserCheck className="w-4 h-4 text-blue-600" />
              <span>1. Employee Identity & Authentication</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Full Name *
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. Eleanor Vance"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Work Email Address *
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="e.g. eleanor@physique57.com"
                    className="w-full pl-10 pr-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                  />
                </div>
              </div>

              <div className="sm:col-span-2">
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Initial Password
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    required
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    placeholder="Password@123"
                    className="w-full pl-10 pr-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Section 2: Organizational Placement */}
          <div className="pt-4 border-t border-slate-100">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <Building className="w-4 h-4 text-indigo-600" />
              <span>2. Department & Designation</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Department *
                </label>
                <select
                  value={formData.department}
                  onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                >
                  {departmentsList.map((dept) => (
                    <option key={dept} value={dept}>
                      {dept}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Designation / Title *
                </label>
                <input
                  type="text"
                  required
                  value={formData.designation}
                  onChange={(e) => setFormData({ ...formData, designation: e.target.value })}
                  placeholder="e.g. Senior Lead Trainer"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Reporting Manager Name
                </label>
                <input
                  type="text"
                  value={formData.reportingManagerName}
                  onChange={(e) => setFormData({ ...formData, reportingManagerName: e.target.value })}
                  placeholder="e.g. Board of Management"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Reporting Manager Email
                </label>
                <input
                  type="email"
                  value={formData.reportingManagerEmail}
                  onChange={(e) => setFormData({ ...formData, reportingManagerEmail: e.target.value })}
                  placeholder="e.g. admin@gmail.com"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>
            </div>
          </div>

          {/* Section 3: Automatic Leave Quotas Preview */}
          <div className="p-4 sm:p-5 rounded-2xl bg-blue-50/70 border border-blue-100">
            <div className="flex items-center gap-2 mb-3">
              <CalendarCheck className="w-4 h-4 text-blue-700" />
              <h4 className="text-xs font-bold text-blue-950 uppercase tracking-wider">
                Automated Annual Leave Quota Allocation
              </h4>
            </div>
            <div className="grid grid-cols-3 gap-3 text-center">
              <div className="p-3 rounded-xl bg-white border border-blue-200/70 shadow-xs">
                <p className="text-lg font-black text-blue-700">18</p>
                <p className="text-[11px] font-bold text-slate-600 mt-0.5">Annual Leave Days</p>
              </div>
              <div className="p-3 rounded-xl bg-white border border-blue-200/70 shadow-xs">
                <p className="text-lg font-black text-amber-700">10</p>
                <p className="text-[11px] font-bold text-slate-600 mt-0.5">Casual Leave Days</p>
              </div>
              <div className="p-3 rounded-xl bg-white border border-blue-200/70 shadow-xs">
                <p className="text-lg font-black text-emerald-700">10</p>
                <p className="text-[11px] font-bold text-slate-600 mt-0.5">Sick Leave Days</p>
              </div>
            </div>
          </div>

          {/* Submit Action */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <button
              type="button"
              onClick={() => setTab(1)}
              className="px-5 py-2.5 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition-colors"
            >
              Cancel & Return
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-6 py-2.5 text-xs font-bold text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 rounded-xl shadow-md shadow-blue-500/20 disabled:opacity-60 cursor-pointer transition-all flex items-center gap-2"
            >
              <UserPlus className="w-4 h-4" />
              <span>{isSubmitting ? 'Onboarding Employee...' : 'Provision Account & Save'}</span>
            </button>
          </div>
        </form>
      </div>

      {/* Success Modal with Credentials */}
      <Modal
        isOpen={!!successData}
        onClose={() => setSuccessData(null)}
        title="Employee Onboarded Successfully!"
      >
        <div className="space-y-4">
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-900 flex items-start gap-3">
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
            <div>
              <p className="font-bold text-sm">Account Ready for Mobile Sign In</p>
              <p className="mt-0.5 text-emerald-800">
                The employee profile and automated leave quotas have been stored in Firestore. Share these credentials with the employee.
              </p>
            </div>
          </div>

          {/* Credentials Box */}
          <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 font-mono text-xs space-y-2">
            <div className="flex justify-between border-b border-slate-200/60 pb-1.5">
              <span className="text-slate-500">Employee ID:</span>
              <span className="font-bold text-slate-900">{successData?.id}</span>
            </div>
            <div className="flex justify-between border-b border-slate-200/60 pb-1.5">
              <span className="text-slate-500">Full Name:</span>
              <span className="font-bold text-slate-900">{successData?.name}</span>
            </div>
            <div className="flex justify-between border-b border-slate-200/60 pb-1.5">
              <span className="text-slate-500">Email:</span>
              <span className="font-bold text-blue-600">{successData?.email}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Initial Password:</span>
              <span className="font-bold text-slate-900">{successData?.password}</span>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={copyCredentials}
              className="inline-flex items-center gap-1.5 px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors"
            >
              {copied ? <Check className="w-4 h-4 text-emerald-600" /> : <Copy className="w-4 h-4" />}
              <span>{copied ? 'Copied Details!' : 'Copy Credentials'}</span>
            </button>
            <button
              type="button"
              onClick={() => {
                setSuccessData(null);
                setTab(1);
              }}
              className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors"
            >
              Go to Employee Directory
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
