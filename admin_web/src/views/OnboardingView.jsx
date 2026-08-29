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
  CalendarCheck,
  Banknote,
  HeartPulse
} from 'lucide-react';
import { db } from '../firebase/config';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';
import { Modal } from '../components/Modal';

export const OnboardingView = ({ setTab }) => {
  const { addToast } = useToast();
  const [existingEmployees, setExistingEmployees] = useState([]);

  React.useEffect(() => {
    import('firebase/firestore').then(({ collection, getDocs }) => {
      getDocs(collection(db, 'employees')).then((snapshot) => {
        const list = snapshot.docs.map(doc => doc.data());
        setExistingEmployees(list);
      }).catch(() => {});
    });
  }, []);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: 'Password@123',
    department: 'Engineering & Product',
    designation: 'Software Engineer',
    reportingManagerName: 'Mayur Chaudhari',
    reportingManagerEmail: 'mayurchaudhari@gmail.com',
    role: 'employee',
    // Dynamic Compensation & Earnings
    baseSalary: 65000,
    hraPercentage: 40,
    allowancePercentage: 15,
    pfPercentage: 8,
    overtimeRate: 500,
    monthlyIncentive: 5000,
    payStatus: 'Processed',
    payCycle: 'Monthly',
    // Dynamic Leave Quotas
    annualLeaveQuota: 18,
    casualLeaveQuota: 10,
    sickLeaveQuota: 10,
    // Dynamic Health & Insurance Profile
    bloodGroup: 'O+',
    coverageAmount: 500000,
    emergencyContactName: 'Family Contact',
    emergencyContactPhone: '+91 98765 43210',
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
    'Physique 57 Studio Ops',
  ];

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.email.trim()) {
      addToast('Please fill out all required fields.', 'error');
      return;
    }

    setIsSubmitting(true);
    const cleanEmail = formData.email.trim().toLowerCase();
    const hash = Math.abs(cleanEmail.split('').reduce((a, b) => (a << 5) - a + b.charCodeAt(0), 0));
    const empId = `EMP-${1000 + (hash % 8999)}`;
    const mediclaimCardId = `PHY57-MED-${1000 + (hash % 8999)}`;

    try {
      const annualQ = Number(formData.annualLeaveQuota) || 18;
      const casualQ = Number(formData.casualLeaveQuota) || 10;
      const sickQ = Number(formData.sickLeaveQuota) || 10;

      const dynamicLeaveBalances = {
        'Annual / Paid Leave': { total: annualQ, used: 0, remaining: annualQ },
        'Casual Leave': { total: casualQ, used: 0, remaining: casualQ },
        'Sick Leave': { total: sickQ, used: 0, remaining: sickQ },
        'Maternity / Paternity Leave': { total: 90, used: 0, remaining: 90 },
        'Bereavement Leave': { total: 5, used: 0, remaining: 5 },
        'Unpaid Leave': { total: 0, used: 0, remaining: 0 },
      };

      const dynamicHealthProfile = {
        mediclaimId: mediclaimCardId,
        coverageAmount: Number(formData.coverageAmount),
        bloodGroup: formData.bloodGroup,
        emergencyContactName: formData.emergencyContactName.trim(),
        emergencyContactPhone: formData.emergencyContactPhone.trim(),
        wellnessAllowance: 15000,
        healthCheckupDone: true,
        createdAt: new Date().toISOString(),
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
        // Dynamic Compensation Fields
        baseSalary: Number(formData.baseSalary),
        hraPercentage: Number(formData.hraPercentage),
        allowancePercentage: Number(formData.allowancePercentage),
        pfPercentage: Number(formData.pfPercentage),
        overtimeRate: Number(formData.overtimeRate),
        monthlyIncentive: Number(formData.monthlyIncentive),
        payStatus: formData.payStatus,
        payCycle: formData.payCycle,
        // Dynamic Leave Quotas Map
        leaveBalances: dynamicLeaveBalances,
        // Dynamic Health Profile Map
        healthProfile: dynamicHealthProfile,
        createdAt: serverTimestamp(),
      };

      // Write to Firestore employees collection
      await setDoc(doc(db, 'employees', cleanEmail), employeeDoc);

      // Create welcome notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `Welcome to Physique 57 ERMS!`,
        message: `Your employee portal account is active. Monthly Base Salary: ₹${formData.baseSalary.toLocaleString('en-IN')}, ${annualQ} Annual, ${casualQ} Casual, and ${sickQ} Sick leave days allocated.`,
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
        details: `Name: ${formData.name}, Salary: ₹${formData.baseSalary}, Quotas: A:${annualQ}/C:${casualQ}/S:${sickQ}`,
        timestamp: serverTimestamp(),
      });

      addToast(`✓ Successfully onboarded ${formData.name}!`, 'success');

      setSuccessData({
        name: formData.name,
        email: cleanEmail,
        password: formData.password,
        id: empId,
        department: formData.department,
        salary: formData.baseSalary,
        mediclaimId: mediclaimCardId,
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
        baseSalary: 65000,
        hraPercentage: 40,
        allowancePercentage: 15,
        pfPercentage: 8,
        overtimeRate: 500,
        monthlyIncentive: 5000,
        payStatus: 'Processed',
        payCycle: 'Monthly',
        annualLeaveQuota: 18,
        casualLeaveQuota: 10,
        sickLeaveQuota: 10,
        bloodGroup: 'O+',
        coverageAmount: 500000,
        emergencyContactName: 'Family Contact',
        emergencyContactPhone: '+91 98765 43210',
      });
    } catch (err) {
      addToast(`Onboarding failed: ${err.message}`, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const copyCredentials = () => {
    if (!successData) return;
    const text = `Physique 57 ERMS Account Details\nName: ${successData.name}\nEmployee ID: ${successData.id}\nEmail: ${successData.email}\nInitial Password: ${successData.password}\nDepartment: ${successData.department}\nMonthly Salary: ₹${successData.salary}\nMediclaim ID: ${successData.mediclaimId}`;
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
            <span>100% Dynamic Firebase Provisioning Active</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
            Onboard New Organization Staff Member
          </h2>
          <p className="text-xs sm:text-sm text-slate-500 font-medium mt-1">
            Fill in the employee details below. Dynamic compensation structures, custom leave quotas, and health insurance profiles are stored directly in Firebase.
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
              <span>2. Department & Role Placement</span>
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

              <div className="sm:col-span-2">
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5 flex items-center justify-between">
                  <span>Assign Reporting Manager *</span>
                  <span className="text-[10px] text-blue-600 font-semibold">Default: Mayur Chaudhari</span>
                </label>
                <select
                  value={formData.reportingManagerEmail}
                  onChange={(e) => {
                    const email = e.target.value;
                    let name = 'Mayur Chaudhari';
                    if (email === 'mayurchaudhari@gmail.com') {
                      name = 'Mayur Chaudhari';
                    } else {
                      const emp = existingEmployees.find(x => x.email === email);
                      if (emp) name = emp.name;
                    }
                    setFormData({ ...formData, reportingManagerEmail: email, reportingManagerName: name });
                  }}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white mb-2"
                >
                  <option value="mayurchaudhari@gmail.com">
                    Mayur Chaudhari (Default Manager - mayurchaudhari@gmail.com)
                  </option>
                  {existingEmployees
                    .filter(emp => emp.email && emp.email.toLowerCase() !== 'mayurchaudhari@gmail.com')
                    .map(emp => (
                      <option key={emp.email} value={emp.email}>
                        {emp.name || emp.email} ({emp.email})
                      </option>
                    ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Manager Display Name
                </label>
                <input
                  type="text"
                  value={formData.reportingManagerName}
                  onChange={(e) => setFormData({ ...formData, reportingManagerName: e.target.value })}
                  placeholder="Mayur Chaudhari"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Manager Email
                </label>
                <input
                  type="email"
                  value={formData.reportingManagerEmail}
                  onChange={(e) => setFormData({ ...formData, reportingManagerEmail: e.target.value })}
                  placeholder="mayurchaudhari@gmail.com"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>
            </div>
          </div>

          {/* Section 3: Dynamic Compensation & Salary Setup */}
          <div className="pt-4 border-t border-slate-100">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <Banknote className="w-4 h-4 text-emerald-600" />
              <span>3. Dynamic Compensation Structure</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Base Monthly Salary (₹) *
                </label>
                <input
                  type="number"
                  required
                  min="0"
                  value={formData.baseSalary}
                  onChange={(e) => setFormData({ ...formData, baseSalary: Number(e.target.value) })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  House Rent Allowance (HRA %)
                </label>
                <input
                  type="number"
                  min="0"
                  max="100"
                  value={formData.hraPercentage}
                  onChange={(e) => setFormData({ ...formData, hraPercentage: Number(e.target.value) })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Monthly Incentive / Bonus (₹)
                </label>
                <input
                  type="number"
                  min="0"
                  value={formData.monthlyIncentive}
                  onChange={(e) => setFormData({ ...formData, monthlyIncentive: Number(e.target.value) })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>
            </div>
          </div>

          {/* Section 4: Dynamic Custom Leave Quotas */}
          <div className="pt-4 border-t border-slate-100">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <CalendarCheck className="w-4 h-4 text-blue-700" />
              <span>4. Custom Annual Leave Quota Allocation</span>
            </h3>

            <div className="grid grid-cols-3 gap-3">
              <div className="p-3 rounded-2xl bg-blue-50/70 border border-blue-100">
                <label className="block text-[11px] font-bold text-blue-900 uppercase mb-1">
                  Annual Paid Leave
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={formData.annualLeaveQuota}
                  onChange={(e) => setFormData({ ...formData, annualLeaveQuota: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-blue-200 rounded-xl text-xs font-mono font-bold text-center text-blue-900"
                />
              </div>

              <div className="p-3 rounded-2xl bg-amber-50/70 border border-amber-100">
                <label className="block text-[11px] font-bold text-amber-900 uppercase mb-1">
                  Casual Leave
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={formData.casualLeaveQuota}
                  onChange={(e) => setFormData({ ...formData, casualLeaveQuota: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-amber-200 rounded-xl text-xs font-mono font-bold text-center text-amber-900"
                />
              </div>

              <div className="p-3 rounded-2xl bg-emerald-50/70 border border-emerald-100">
                <label className="block text-[11px] font-bold text-emerald-900 uppercase mb-1">
                  Sick Leave
                </label>
                <input
                  type="number"
                  min="0"
                  max="365"
                  value={formData.sickLeaveQuota}
                  onChange={(e) => setFormData({ ...formData, sickLeaveQuota: Number(e.target.value) })}
                  className="w-full px-3 py-1.5 bg-white border border-emerald-200 rounded-xl text-xs font-mono font-bold text-center text-emerald-900"
                />
              </div>
            </div>
          </div>

          {/* Section 5: Group Mediclaim & Emergency Details */}
          <div className="pt-4 border-t border-slate-100">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <HeartPulse className="w-4 h-4 text-rose-600" />
              <span>5. Group Mediclaim & Health Pass</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Blood Group
                </label>
                <select
                  value={formData.bloodGroup}
                  onChange={(e) => setFormData({ ...formData, bloodGroup: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                >
                  {['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].map((bg) => (
                    <option key={bg} value={bg}>
                      {bg}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Emergency Contact Name
                </label>
                <input
                  type="text"
                  value={formData.emergencyContactName}
                  onChange={(e) => setFormData({ ...formData, emergencyContactName: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Emergency Contact Phone
                </label>
                <input
                  type="text"
                  value={formData.emergencyContactPhone}
                  onChange={(e) => setFormData({ ...formData, emergencyContactPhone: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
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
              <span>{isSubmitting ? 'Onboarding Employee...' : 'Provision Account & Sync Firebase'}</span>
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
              <p className="font-bold text-sm">Dynamic Firebase Profile Ready</p>
              <p className="mt-0.5 text-emerald-800">
                Employee profile, base salary (₹{successData?.salary?.toLocaleString('en-IN')}), custom leave quotas, and Mediclaim Card ID ({successData?.mediclaimId}) have been stored in Cloud Firestore.
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
            <div className="flex justify-between border-b border-slate-200/60 pb-1.5">
              <span className="text-slate-500">Initial Password:</span>
              <span className="font-bold text-slate-900">{successData?.password}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Mediclaim Card ID:</span>
              <span className="font-bold text-rose-600">{successData?.mediclaimId}</span>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={copyCredentials}
              className="inline-flex items-center gap-1.5 px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors cursor-pointer"
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
              className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors cursor-pointer"
            >
              Go to Employee Directory
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
