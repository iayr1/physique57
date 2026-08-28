import React, { useState, useEffect } from 'react';
import { useAuth } from './context/AuthContext';
import { db } from './firebase/config';
import {
  collection,
  onSnapshot,
  doc,
  updateDoc,
  getDoc,
  setDoc,
  serverTimestamp,
  query,
  orderBy
} from 'firebase/firestore';
import { useToast } from './components/Toast';
import { Modal } from './components/Modal';
import { Navbar } from './components/Navbar';
import { Sidebar, navItems } from './components/Sidebar';
import { LoginView } from './views/LoginView';
import { OverviewView } from './views/OverviewView';
import { EmployeesView } from './views/EmployeesView';
import { OnboardingView } from './views/OnboardingView';
import { RequestsView } from './views/RequestsView';
import { AttendanceView } from './views/AttendanceView';
import { TasksView } from './views/TasksView';
import { AnnouncementsView } from './views/AnnouncementsView';
import { AuditLogsView } from './views/AuditLogsView';

export const App = () => {
  const { currentUser, loading } = useAuth();
  const { addToast } = useToast();

  const [currentTab, setCurrentTab] = useState(0);
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  // Firestore Real-Time States
  const [employees, setEmployees] = useState([]);
  const [requests, setRequests] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [attendanceLogs, setAttendanceLogs] = useState([]);
  const [announcements, setAnnouncements] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);

  // Reject Modal State
  const [rejectingRequest, setRejectingRequest] = useState(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [isRejecting, setIsRejecting] = useState(false);

  // Real-time Firestore Listeners
  useEffect(() => {
    if (!currentUser) return;

    // 1. Employees Stream
    const unsubEmployees = onSnapshot(collection(db, 'employees'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setEmployees(list);
    });

    // 2. Requests Stream
    const unsubRequests = onSnapshot(collection(db, 'requests'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.submittedAt?.toDate?.() || a.createdAt?.toDate?.() || new Date(0);
        const timeB = b.submittedAt?.toDate?.() || b.createdAt?.toDate?.() || new Date(0);
        return timeB - timeA;
      });
      setRequests(list);
    });

    // 3. Tasks Stream
    const unsubTasks = onSnapshot(collection(db, 'tasks'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.createdAt?.toDate?.() || new Date(0);
        const timeB = b.createdAt?.toDate?.() || new Date(0);
        return timeB - timeA;
      });
      setTasks(list);
    });

    // 4. Attendance Stream
    const unsubAttendance = onSnapshot(collection(db, 'attendance'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.checkInTime?.toDate?.() || new Date(0);
        const timeB = b.checkInTime?.toDate?.() || new Date(0);
        return timeB - timeA;
      });
      setAttendanceLogs(list);
    });

    // 5. Announcements Stream
    const unsubAnnouncements = onSnapshot(collection(db, 'announcements'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.createdAt?.toDate?.() || new Date(0);
        const timeB = b.createdAt?.toDate?.() || new Date(0);
        return timeB - timeA;
      });
      setAnnouncements(list);
    });

    // 6. Audit Logs Stream
    const unsubAudit = onSnapshot(collection(db, 'audit_logs'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.timestamp?.toDate?.() || new Date(0);
        const timeB = b.timestamp?.toDate?.() || new Date(0);
        return timeB - timeA;
      });
      setAuditLogs(list);
    });

    return () => {
      unsubEmployees();
      unsubRequests();
      unsubTasks();
      unsubAttendance();
      unsubAnnouncements();
      unsubAudit();
    };
  }, [currentUser]);

  // Request Approval with Automated Leave Quota Deduction
  const handleApproveRequest = async (req) => {
    try {
      const reqData = req.requestData || {};
      const reqType = req.requestType || '';
      const employeeEmail = req.employeeEmail;
      const days = parseInt(reqData.numberOfDays || 1, 10);
      const leaveType = reqData.leaveType || 'Annual / Paid Leave';

      // 1. If Leave Request, deduct quota from employee profile
      if (reqType === 'leave' && employeeEmail) {
        const empRef = doc(db, 'employees', employeeEmail);
        const empSnap = await getDoc(empRef);

        if (empSnap.exists()) {
          const empData = empSnap.data();
          const balances = empData.leaveBalances || {
            'Annual / Paid Leave': { total: 18, used: 0, remaining: 18 },
            'Casual Leave': { total: 10, used: 0, remaining: 10 },
            'Sick Leave': { total: 10, used: 0, remaining: 10 },
          };

          // Find matching key
          let balanceKey = 'Annual / Paid Leave';
          if (leaveType.toLowerCase().includes('sick')) balanceKey = 'Sick Leave';
          if (leaveType.toLowerCase().includes('casual')) balanceKey = 'Casual Leave';

          const currentQuota = balances[balanceKey] || { total: 18, used: 0, remaining: 18 };
          const newRemaining = Math.max(0, currentQuota.remaining - days);
          const newUsed = currentQuota.used + days;

          balances[balanceKey] = {
            ...currentQuota,
            used: newUsed,
            remaining: newRemaining,
          };

          await updateDoc(empRef, {
            leaveBalances: balances,
          });
        }
      }

      // 2. Append to Approval History
      const approvalStep = {
        step: 'Approved by Administrator',
        status: 'Approved',
        approver: 'admin@gmail.com',
        timestamp: serverTimestamp(),
      };

      const updatedHistory = [...(req.approvalHistory || []), approvalStep];

      // 3. Update Request Document
      await updateDoc(doc(db, 'requests', req.id), {
        status: 'Approved',
        approvedAt: serverTimestamp(),
        approvalHistory: updatedHistory,
      });

      // 4. Send in-app notification to employee
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `✓ Request Approved: ${req.id}`,
        message: `Your ${reqType} request has been approved by the management board.`,
        requestId: req.id,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: employeeEmail,
      });

      // 5. Audit Log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'REQUEST_APPROVED',
        performedBy: 'admin@gmail.com',
        targetEmail: employeeEmail,
        details: `Request: ${req.id} (${reqType}), Days: ${days}`,
        timestamp: serverTimestamp(),
      });

      addToast(`✓ Request ${req.id} approved successfully!`, 'success');
    } catch (err) {
      addToast(`Failed to approve request: ${err.message}`, 'error');
    }
  };

  // Open Rejection Reason Modal
  const handleOpenRejectModal = (req) => {
    setRejectingRequest(req);
    setRejectionReason('');
  };

  // Submit Rejection
  const handleConfirmReject = async (e) => {
    e.preventDefault();
    if (!rejectingRequest) return;
    if (!rejectionReason.trim()) {
      addToast('Please provide a rejection reason for the employee.', 'error');
      return;
    }

    setIsRejecting(true);
    const req = rejectingRequest;

    try {
      const rejectionStep = {
        step: 'Rejected by Administrator',
        status: 'Rejected',
        reason: rejectionReason.trim(),
        approver: 'admin@gmail.com',
        timestamp: serverTimestamp(),
      };

      const updatedHistory = [...(req.approvalHistory || []), rejectionStep];

      // Update Request Document
      await updateDoc(doc(db, 'requests', req.id), {
        status: 'Rejected',
        rejectionReason: rejectionReason.trim(),
        rejectedAt: serverTimestamp(),
        approvalHistory: updatedHistory,
      });

      // Send rejection notification to employee
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `✗ Request Rejected: ${req.id}`,
        message: `Reason: ${rejectionReason.trim()}`,
        requestId: req.id,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: req.employeeEmail,
      });

      // Audit Log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'REQUEST_REJECTED',
        performedBy: 'admin@gmail.com',
        targetEmail: req.employeeEmail,
        details: `Request: ${req.id}, Reason: ${rejectionReason.trim()}`,
        timestamp: serverTimestamp(),
      });

      addToast(`Request ${req.id} rejected.`, 'success');
      setRejectingRequest(null);
    } catch (err) {
      addToast(`Failed to reject request: ${err.message}`, 'error');
    } finally {
      setIsRejecting(false);
    }
  };

  // Show login screen if not authenticated
  if (!currentUser) {
    return <LoginView />;
  }

  // Counts for sidebar badges
  const pendingRequestsCount = requests.filter((r) =>
    (r.status || '').toLowerCase().includes('pending')
  ).length;
  const pendingTasksCount = tasks.filter((t) => (t.status || 'Pending') !== 'Completed').length;

  // Active view title
  const currentTabTitle = navItems[currentTab]?.label || 'Dashboard';

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar */}
      <Sidebar
        currentTab={currentTab}
        setTab={setCurrentTab}
        counts={{
          employees: employees.length,
          pendingRequests: pendingRequestsCount,
          pendingTasks: pendingTasksCount,
        }}
        isMobileOpen={isMobileOpen}
        setIsMobileOpen={setIsMobileOpen}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 lg:pl-72">
        {/* Navbar */}
        <Navbar
          onMenuClick={() => setIsMobileOpen(true)}
          currentTabTitle={currentTabTitle}
          pendingCount={pendingRequestsCount}
        />

        {/* Dynamic View Body */}
        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
          {currentTab === 0 && (
            <OverviewView
              employees={employees}
              requests={requests}
              tasks={tasks}
              todayAttendance={attendanceLogs.filter(
                (a) => a.date === new Date().toISOString().split('T')[0]
              )}
              setTab={setCurrentTab}
              onApproveRequest={handleApproveRequest}
              onOpenRejectModal={handleOpenRejectModal}
            />
          )}

          {currentTab === 1 && (
            <EmployeesView employees={employees} setTab={setCurrentTab} />
          )}

          {currentTab === 2 && <OnboardingView setTab={setCurrentTab} />}

          {currentTab === 3 && (
            <RequestsView
              requests={requests}
              onApproveRequest={handleApproveRequest}
              onOpenRejectModal={handleOpenRejectModal}
            />
          )}

          {currentTab === 4 && (
            <AttendanceView
              employees={employees}
              allAttendanceLogs={attendanceLogs}
            />
          )}

          {currentTab === 5 && (
            <TasksView tasks={tasks} employees={employees} />
          )}

          {currentTab === 6 && (
            <AnnouncementsView announcements={announcements} />
          )}

          {currentTab === 7 && <AuditLogsView auditLogs={auditLogs} />}
        </main>
      </div>

      {/* Rejection Reason Modal */}
      <Modal
        isOpen={!!rejectingRequest}
        onClose={() => setRejectingRequest(null)}
        title={`Reject Request: ${rejectingRequest?.id || ''}`}
      >
        <form onSubmit={handleConfirmReject} className="space-y-4">
          <div className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-xs text-rose-800">
            <p className="font-bold">Specify Reason for Employee</p>
            <p className="mt-0.5">
              Explain why this request is being rejected. This note will be recorded in the audit trail and sent to the employee.
            </p>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Rejection Reason / Comments *
            </label>
            <textarea
              rows="3"
              required
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g. Quota limit exceeded / Insufficient documentation attached / Schedule conflict"
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:bg-white"
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={() => setRejectingRequest(null)}
              className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isRejecting}
              className="px-5 py-2 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-xs disabled:opacity-60"
            >
              {isRejecting ? 'Rejecting...' : 'Confirm Rejection'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
export default App;
