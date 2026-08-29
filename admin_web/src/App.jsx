import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from './context/AuthContext';
import { db } from './firebase/config';
import {
  collection,
  onSnapshot,
  doc,
  updateDoc,
  getDoc,
  setDoc,
  query,
  where,
  getDocs,
  serverTimestamp,
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
import { CompensationView } from './views/CompensationView';
import { LeaveQuotaView } from './views/LeaveQuotaView';
import { HealthWellnessView } from './views/HealthWellnessView';
import { playNotificationChime } from './utils/audioUtils';
import { showDesktopNotification, requestBrowserNotificationPermission } from './utils/notificationUtils';

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
  const [notifications, setNotifications] = useState([]);

  // Reject Modal State
  const [rejectingRequest, setRejectingRequest] = useState(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [isRejecting, setIsRejecting] = useState(false);

  // Initial load ref to prevent chiming for old existing items on initial load
  const isInitialLoad = useRef(true);

  // Auto-request desktop notifications when admin is logged in
  useEffect(() => {
    if (currentUser) {
      requestBrowserNotificationPermission();
    }
  }, [currentUser]);

  // Real-time Firestore Listeners
  useEffect(() => {
    if (!currentUser) return;

    isInitialLoad.current = true;
    setTimeout(() => {
      isInitialLoad.current = false;
    }, 2500);

    // 1. Employees Stream
    const unsubEmployees = onSnapshot(collection(db, 'employees'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setEmployees(list);
    });

    // 2. Requests Stream with Live Incoming Alerts
    const unsubRequests = onSnapshot(collection(db, 'requests'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.submittedAt?.toDate?.() || a.createdAt?.toDate?.() || new Date(0);
        const timeB = b.submittedAt?.toDate?.() || b.createdAt?.toDate?.() || new Date(0);
        return timeB - timeA;
      });

      // Detect newly submitted employee requests
      if (!isInitialLoad.current) {
        snap.docChanges().forEach((change) => {
          if (change.type === 'added') {
            const data = change.doc.data();
            const employeeName = data.employeeName || 'Staff Member';
            const reqType = data.requestType || 'Request';

            // Play alert sound chime
            playNotificationChime();

            // Show floating Toast Alert
            addToast(`🔔 New ${reqType} submitted by ${employeeName}!`, 'info', 6000);

            // Show native desktop notification
            showDesktopNotification(
              `🔔 New ${reqType} Submitted`,
              `${employeeName} submitted a new request for approval.`,
              () => setCurrentTab(3)
            );
          }
        });
      }

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

    // 7. System Notifications Stream
    const unsubNotifications = onSnapshot(collection(db, 'notifications'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => {
        const timeA = a.timestamp?.toDate?.() || new Date(0);
        const timeB = b.timestamp?.toDate?.() || new Date(0);
        return timeB - timeA;
      });
      setNotifications(list);
    });

    return () => {
      unsubEmployees();
      unsubRequests();
      unsubTasks();
      unsubAttendance();
      unsubAnnouncements();
      unsubAudit();
      unsubNotifications();
    };
  }, [currentUser, addToast]);

  // Request Approval with Automated Leave Quota Deduction
  const handleApproveRequest = async (req) => {
    try {
      const reqData = req.requestData || {};
      const reqType = (req.requestType || '').toLowerCase();
      const employeeEmail = (req.employeeEmail || '').toLowerCase().trim();
      const days = parseInt(reqData.numberOfDays || reqData.days || 1, 10);
      const leaveType = reqData.leaveType || reqData.category || 'Annual / Paid Leave';

      // 1. If Leave Request, deduct quota from employee profile
      if ((reqType.includes('leave') || reqType === 'leave') && employeeEmail) {
        let empRef = doc(db, 'employees', employeeEmail);
        let empSnap = await getDoc(empRef);

        // Fallback search by email field if document key is not email
        if (!empSnap.exists()) {
          const qSnap = await getDocs(query(collection(db, 'employees'), where('email', '==', employeeEmail)));
          if (!qSnap.empty) {
            empSnap = qSnap.docs[0];
            empRef = doc(db, 'employees', empSnap.id);
          }
        }

        if (empSnap.exists()) {
          const empData = empSnap.data();
          const balances = empData.leaveBalances || {
            'Annual / Paid Leave': { total: 18, used: 0, remaining: 18 },
            'Casual Leave': { total: 10, used: 0, remaining: 10 },
            'Sick Leave': { total: 10, used: 0, remaining: 10 },
            'Maternity / Paternity Leave': { total: 90, used: 0, remaining: 90 },
            'Bereavement Leave': { total: 5, used: 0, remaining: 5 },
            'Unpaid Leave': { total: 0, used: 0, remaining: 0 },
          };

          // Find matching leave category key
          let balanceKey = 'Annual / Paid Leave';
          const ltLower = leaveType.toLowerCase();
          if (ltLower.includes('sick')) balanceKey = 'Sick Leave';
          else if (ltLower.includes('casual')) balanceKey = 'Casual Leave';
          else if (ltLower.includes('maternity') || ltLower.includes('paternity')) balanceKey = 'Maternity / Paternity Leave';
          else if (ltLower.includes('bereavement')) balanceKey = 'Bereavement Leave';

          const currentQuota = balances[balanceKey] || { total: 18, used: 0, remaining: 18 };
          const newUsed = (currentQuota.used || 0) + days;
          const newRemaining = Math.max(0, (currentQuota.total || 18) - newUsed);

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
        timestamp: new Date().toISOString(),
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
        timestamp: new Date().toISOString(),
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
  const tabTitles = [
    'Overview',
    'User Directory',
    'Onboard Staff',
    'Leave Approvals',
    'Attendance',
    'Tasks',
    'Notices',
    'Audit Logs',
  ];
  const currentTabTitle = tabTitles[currentTab] || 'Dashboard';

  return (
    <div className="min-h-screen bg-[#FFFDF5] flex">
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
      {/* Main Workspace Layout */}
      <div className="lg:pl-72 flex flex-col min-h-screen flex-1">
        <Navbar
          onMenuClick={() => setIsMobileOpen(true)}
          currentTabTitle={currentTabTitle}
          pendingCount={pendingRequestsCount}
          notifications={notifications}
          onSelectTab={setCurrentTab}
        />

        <main className="flex-1 p-4 sm:p-8 space-y-6 max-w-7xl w-full mx-auto">
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

          {currentTab === 8 && <CompensationView employees={employees} />}

          {currentTab === 9 && (
            <LeaveQuotaView employees={employees} setTab={setCurrentTab} />
          )}

          {currentTab === 10 && (
            <HealthWellnessView employees={employees} />
          )}
        </main>
      </div>

      {/* Rejection Reason Modal */}
      <Modal
        isOpen={!!rejectingRequest}
        onClose={() => setRejectingRequest(null)}
        title={`Reject Request: ${rejectingRequest?.id || ''}`}
      >
        <form onSubmit={handleConfirmReject} className="space-y-4">
          <div className="p-4 rounded-xl bg-neo-pink/30 border-2 border-neo-border text-xs text-neo-border font-extrabold shadow-brutal-sm">
            <p className="font-black text-sm">Specify Reason for Employee</p>
            <p className="mt-1 font-semibold">
              Explain why this request is being rejected. This note will be recorded in the audit trail and sent to the employee.
            </p>
          </div>

          <div>
            <label className="block text-xs font-black text-neo-border uppercase tracking-wider mb-1.5 font-display">
              Rejection Reason / Comments *
            </label>
            <textarea
              rows="3"
              required
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g. Quota limit exceeded / Insufficient documentation attached / Schedule conflict"
              className="w-full px-3.5 py-2.5 bg-white border-2 border-neo-border rounded-xl text-xs font-bold focus:outline-none focus:ring-2 focus:ring-neo-indigo shadow-brutal-sm"
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t-2 border-neo-border">
            <button
              type="button"
              onClick={() => setRejectingRequest(null)}
              className="px-4 py-2 text-xs font-black text-neo-border hover:bg-neo-yellow/30 rounded-xl border border-neo-border transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isRejecting}
              className="px-5 py-2 text-xs font-black text-white bg-rose-600 border-2 border-neo-border rounded-xl shadow-brutal-sm hover:translate-x-0.5 hover:translate-y-0.5 transition-all disabled:opacity-60 cursor-pointer"
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
