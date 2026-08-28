import React, { useState } from 'react';
import {
  Clock,
  Calendar,
  ChevronLeft,
  ChevronRight,
  Search,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Edit2,
  LogIn,
  LogOut,
  Sparkles,
  Users
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { formatDate, formatTime } from '../utils/dateUtils';
import { format, addDays, subDays } from 'date-fns';
import { db } from '../firebase/config';
import { doc, setDoc, updateDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';

export const AttendanceView = ({
  employees = [],
  allAttendanceLogs = []
}) => {
  const { addToast } = useToast();
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [viewMode, setViewMode] = useState('daily'); // 'daily' | 'history'
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');

  // Manual Attendance Modal State
  const [editingAttendance, setEditingAttendance] = useState(null);
  const [modalForm, setModalForm] = useState({
    status: 'Present',
    checkInTime: '09:00',
    checkOutTime: '18:00',
    hasCheckOut: false,
  });
  const [isSaving, setIsSaving] = useState(false);

  const selectedDateStr = format(selectedDate, 'yyyy-MM-dd');
  const isToday = selectedDateStr === format(new Date(), 'yyyy-MM-dd');

  // Day Attendance Map
  const dayLogs = allAttendanceLogs.filter((log) => log.date === selectedDateStr);
  const dayLogMap = {};
  dayLogs.forEach((log) => {
    if (log.employeeEmail) {
      dayLogMap[log.employeeEmail.toLowerCase()] = log;
    }
  });

  // Calculate Metrics for the Day
  const totalEmployees = employees.length;
  let presentCount = 0;
  let lateCount = 0;
  let notCheckedInCount = 0;

  employees.forEach((emp) => {
    const log = dayLogMap[(emp.email || '').toLowerCase()];
    if (!log) {
      notCheckedInCount++;
    } else if (log.status === 'Late') {
      lateCount++;
    } else {
      presentCount++;
    }
  });

  // Shift Day
  const handlePrevDay = () => setSelectedDate((prev) => subDays(prev, 1));
  const handleNextDay = () => setSelectedDate((prev) => addDays(prev, 1));
  const handleSetToday = () => setSelectedDate(new Date());

  // Quick Check In
  const handleQuickCheckIn = async (emp) => {
    const email = emp.email;
    const name = emp.name;
    const docId = `ATT-${email}-${selectedDateStr}`;
    const now = new Date();
    const isLate = now.getHours() > 9 || (now.getHours() === 9 && now.getMinutes() > 30);
    const status = isLate ? 'Late' : 'Present';

    try {
      await setDoc(
        doc(db, 'attendance', docId),
        {
          id: docId,
          employeeEmail: email,
          employeeName: name,
          date: selectedDateStr,
          status: status,
          checkInTime: Timestamp.fromDate(now),
          checkOutTime: null,
        },
        { merge: true }
      );
      addToast(`✓ ${name} marked Checked In (${status})`, 'success');
    } catch (err) {
      addToast(`Failed to check in: ${err.message}`, 'error');
    }
  };

  // Quick Check Out
  const handleQuickCheckOut = async (emp) => {
    const email = emp.email;
    const name = emp.name;
    const docId = `ATT-${email}-${selectedDateStr}`;
    const now = new Date();

    try {
      await updateDoc(doc(db, 'attendance', docId), {
        checkOutTime: Timestamp.fromDate(now),
      });
      addToast(`✓ ${name} marked Checked Out at ${format(now, 'hh:mm a')}`, 'success');
    } catch (err) {
      addToast(`Failed to check out: ${err.message}`, 'error');
    }
  };

  // Open Correction Modal
  const handleOpenCorrection = (emp, existingLog) => {
    let checkInStr = '09:00';
    let checkOutStr = '18:00';
    let hasCheckOut = false;
    let status = 'Present';

    if (existingLog) {
      status = existingLog.status || 'Present';
      if (existingLog.checkInTime) {
        const d = existingLog.checkInTime.toDate ? existingLog.checkInTime.toDate() : new Date(existingLog.checkInTime);
        checkInStr = format(d, 'HH:mm');
      }
      if (existingLog.checkOutTime) {
        const d = existingLog.checkOutTime.toDate ? existingLog.checkOutTime.toDate() : new Date(existingLog.checkOutTime);
        checkOutStr = format(d, 'HH:mm');
        hasCheckOut = true;
      }
    }

    setEditingAttendance({ emp, existingLog });
    setModalForm({
      status,
      checkInTime: checkInStr,
      checkOutTime: checkOutStr,
      hasCheckOut,
    });
  };

  // Save Correction Modal
  const handleSaveCorrection = async (e) => {
    e.preventDefault();
    if (!editingAttendance) return;
    setIsSaving(true);

    const { emp } = editingAttendance;
    const email = emp.email;
    const name = emp.name;
    const docId = `ATT-${email}-${selectedDateStr}`;

    try {
      const [inH, inM] = modalForm.checkInTime.split(':').map(Number);
      const checkInDate = new Date(selectedDate);
      checkInDate.setHours(inH || 9, inM || 0, 0, 0);

      let checkOutDate = null;
      if (modalForm.hasCheckOut) {
        const [outH, outM] = modalForm.checkOutTime.split(':').map(Number);
        checkOutDate = new Date(selectedDate);
        checkOutDate.setHours(outH || 18, outM || 0, 0, 0);
      }

      await setDoc(
        doc(db, 'attendance', docId),
        {
          id: docId,
          employeeEmail: email,
          employeeName: name,
          date: selectedDateStr,
          status: modalForm.status,
          checkInTime: Timestamp.fromDate(checkInDate),
          checkOutTime: checkOutDate ? Timestamp.fromDate(checkOutDate) : null,
        },
        { merge: true }
      );

      addToast(`Attendance saved for ${name} (${selectedDateStr})`, 'success');
      setEditingAttendance(null);
    } catch (err) {
      addToast(`Error saving attendance: ${err.message}`, 'error');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & Date Controller */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
            Attendance Monitoring & Time Tracking
          </h3>
          <p className="text-xs text-slate-500 mt-0.5 font-medium">
            Live synchronization with mobile geolocation & check-in timestamps.
          </p>
        </div>

        {/* Date Navigator Pill */}
        <div className="flex items-center gap-2 bg-slate-100 p-1.5 rounded-2xl border border-slate-200 self-start sm:self-auto">
          <button
            onClick={handlePrevDay}
            className="p-1.5 rounded-xl hover:bg-white text-slate-600 hover:text-slate-900 transition-colors"
            title="Previous Day"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>

          <div className="flex items-center gap-2 px-3 py-1 bg-white rounded-xl shadow-xs text-xs font-bold text-slate-900">
            <Calendar className="w-3.5 h-3.5 text-blue-600" />
            <span>{format(selectedDate, 'EEEE, dd MMMM yyyy')}</span>
            {isToday && (
              <span className="px-1.5 py-0.5 rounded bg-blue-100 text-blue-700 text-[10px] font-extrabold">
                TODAY
              </span>
            )}
          </div>

          <button
            onClick={handleNextDay}
            className="p-1.5 rounded-xl hover:bg-white text-slate-600 hover:text-slate-900 transition-colors"
            title="Next Day"
          >
            <ChevronRight className="w-4 h-4" />
          </button>

          {!isToday && (
            <button
              onClick={handleSetToday}
              className="px-2.5 py-1 text-xs font-bold text-blue-600 hover:bg-white rounded-xl transition-colors"
            >
              Today
            </button>
          )}
        </div>
      </div>

      {/* Daily Metrics Breakdown */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-soft">
          <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Staff</p>
          <p className="text-2xl font-black text-slate-900 mt-1">{totalEmployees}</p>
          <p className="text-[11px] text-slate-500 mt-0.5">Enrolled employees</p>
        </div>

        <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-soft">
          <p className="text-xs font-bold uppercase tracking-wider text-emerald-600">On-Time</p>
          <p className="text-2xl font-black text-emerald-700 mt-1">{presentCount}</p>
          <p className="text-[11px] text-slate-500 mt-0.5">Before 09:30 AM</p>
        </div>

        <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-soft">
          <p className="text-xs font-bold uppercase tracking-wider text-orange-600">Late Arrival</p>
          <p className="text-2xl font-black text-orange-700 mt-1">{lateCount}</p>
          <p className="text-[11px] text-slate-500 mt-0.5">After 09:30 AM</p>
        </div>

        <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-soft">
          <p className="text-xs font-bold uppercase tracking-wider text-rose-600">Not Checked In</p>
          <p className="text-2xl font-black text-rose-700 mt-1">{notCheckedInCount}</p>
          <p className="text-[11px] text-slate-500 mt-0.5">Absent or pending</p>
        </div>
      </div>

      {/* Sub-View Tabs: Daily Roster vs Historical Feed */}
      <div className="flex items-center justify-between">
        <div className="inline-flex p-1 bg-slate-100 rounded-2xl border border-slate-200">
          <button
            onClick={() => setViewMode('daily')}
            className={`px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              viewMode === 'daily'
                ? 'bg-white text-slate-900 shadow-xs'
                : 'text-slate-500 hover:text-slate-900'
            }`}
          >
            Staff Daily Roster ({selectedDateStr})
          </button>
          <button
            onClick={() => setViewMode('history')}
            className={`px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              viewMode === 'history'
                ? 'bg-white text-slate-900 shadow-xs'
                : 'text-slate-500 hover:text-slate-900'
            }`}
          >
            All Historical Logs ({allAttendanceLogs.length})
          </button>
        </div>

        {/* Search */}
        <div className="relative w-64">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search employee..."
            className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          />
        </div>
      </div>

      {/* VIEW 1: Daily Staff Roster Table */}
      {viewMode === 'daily' && (
        <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50/70 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                  <th className="py-4 px-6">Staff Member</th>
                  <th className="py-4 px-6">Department</th>
                  <th className="py-4 px-6">Check-In Time</th>
                  <th className="py-4 px-6">Check-Out Time</th>
                  <th className="py-4 px-6">Status</th>
                  <th className="py-4 px-6 text-right">Quick Admin Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs font-medium">
                {employees
                  .filter((emp) => {
                    const q = searchQuery.toLowerCase().trim();
                    return !q || (emp.name || '').toLowerCase().includes(q) || (emp.email || '').toLowerCase().includes(q);
                  })
                  .map((emp) => {
                    const log = dayLogMap[(emp.email || '').toLowerCase()];
                    const hasCheckedIn = !!(log && log.checkInTime);
                    const hasCheckedOut = !!(log && log.checkOutTime);
                    const status = log ? log.status : 'Not Checked In';

                    return (
                      <tr key={emp.email || emp.id} className="hover:bg-slate-50/60 transition-colors">
                        {/* Name & Email */}
                        <td className="py-4 px-6">
                          <div className="flex items-center gap-3">
                            <div className="h-8 w-8 rounded-xl bg-slate-100 text-slate-700 font-bold flex items-center justify-center text-xs shrink-0">
                              {(emp.name || 'E').substring(0, 2).toUpperCase()}
                            </div>
                            <div>
                              <p className="font-bold text-slate-900">{emp.name}</p>
                              <p className="text-slate-500 text-[11px] font-mono">{emp.email}</p>
                            </div>
                          </div>
                        </td>

                        {/* Dept */}
                        <td className="py-4 px-6 text-slate-700 font-semibold">
                          {emp.department || 'General'}
                        </td>

                        {/* Check-In */}
                        <td className="py-4 px-6 font-mono">
                          {hasCheckedIn ? (
                            <span className="font-bold text-emerald-700">
                              {formatTime(log.checkInTime)}
                            </span>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>

                        {/* Check-Out */}
                        <td className="py-4 px-6 font-mono">
                          {hasCheckedOut ? (
                            <span className="font-bold text-blue-700">
                              {formatTime(log.checkOutTime)}
                            </span>
                          ) : hasCheckedIn ? (
                            <span className="text-amber-600 font-bold italic">In Progress</span>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>

                        {/* Status Badge */}
                        <td className="py-4 px-6">
                          <Badge size="sm">{status}</Badge>
                        </td>

                        {/* Actions */}
                        <td className="py-4 px-6 text-right">
                          <div className="flex items-center justify-end gap-2">
                            {!hasCheckedIn && (
                              <button
                                onClick={() => handleQuickCheckIn(emp)}
                                className="px-2.5 py-1 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 rounded-lg text-xs font-bold transition-colors cursor-pointer"
                                title="Mark Checked In now"
                              >
                                + Check In
                              </button>
                            )}

                            {hasCheckedIn && !hasCheckedOut && (
                              <button
                                onClick={() => handleQuickCheckOut(emp)}
                                className="px-2.5 py-1 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded-lg text-xs font-bold transition-colors cursor-pointer"
                                title="Mark Checked Out now"
                              >
                                Check Out
                              </button>
                            )}

                            <button
                              onClick={() => handleOpenCorrection(emp, log)}
                              className="p-1.5 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors cursor-pointer"
                              title="Manual Attendance Correction"
                            >
                              <Edit2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* VIEW 2: Historical Feed View */}
      {viewMode === 'history' && (
        <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50/70 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                  <th className="py-4 px-6">Date</th>
                  <th className="py-4 px-6">Staff Member</th>
                  <th className="py-4 px-6">Check-In Time</th>
                  <th className="py-4 px-6">Check-Out Time</th>
                  <th className="py-4 px-6">Recorded Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs font-medium">
                {allAttendanceLogs
                  .filter((log) => {
                    const q = searchQuery.toLowerCase().trim();
                    return (
                      !q ||
                      (log.employeeName || '').toLowerCase().includes(q) ||
                      (log.employeeEmail || '').toLowerCase().includes(q) ||
                      (log.date || '').toLowerCase().includes(q) ||
                      (log.status || '').toLowerCase().includes(q)
                    );
                  })
                  .slice(0, 50)
                  .map((log) => (
                    <tr key={log.id} className="hover:bg-slate-50/60 transition-colors">
                      <td className="py-4 px-6 font-bold text-slate-900 font-mono">
                        {log.date}
                      </td>
                      <td className="py-4 px-6">
                        <p className="font-bold text-slate-900">{log.employeeName || 'Staff'}</p>
                        <p className="text-slate-500 text-[11px] font-mono">{log.employeeEmail}</p>
                      </td>
                      <td className="py-4 px-6 font-mono text-emerald-700 font-bold">
                        {formatTime(log.checkInTime)}
                      </td>
                      <td className="py-4 px-6 font-mono text-blue-700 font-bold">
                        {log.checkOutTime ? formatTime(log.checkOutTime) : '—'}
                      </td>
                      <td className="py-4 px-6">
                        <Badge size="sm">{log.status || 'Present'}</Badge>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Manual Correction Modal */}
      <Modal
        isOpen={!!editingAttendance}
        onClose={() => setEditingAttendance(null)}
        title={`Attendance Correction: ${editingAttendance?.emp?.name || ''}`}
      >
        <form onSubmit={handleSaveCorrection} className="space-y-4">
          <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 text-xs flex justify-between">
            <span className="font-semibold text-slate-600">Selected Date:</span>
            <span className="font-bold font-mono text-blue-600">{selectedDateStr}</span>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Attendance Status
            </label>
            <select
              value={modalForm.status}
              onChange={(e) => setModalForm({ ...modalForm, status: e.target.value })}
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500"
            >
              <option value="Present">Present (On Time)</option>
              <option value="Late">Late Arrival</option>
              <option value="Half Day">Half Day</option>
              <option value="Excused">Excused / Official Duty</option>
              <option value="Absent">Absent / No Show</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Check-In Time
              </label>
              <input
                type="time"
                value={modalForm.checkInTime}
                onChange={(e) => setModalForm({ ...modalForm, checkInTime: e.target.value })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-center focus:outline-hidden focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-bold text-slate-700 uppercase tracking-wider">
                  Check-Out Time
                </label>
                <input
                  type="checkbox"
                  checked={modalForm.hasCheckOut}
                  onChange={(e) => setModalForm({ ...modalForm, hasCheckOut: e.target.checked })}
                  className="rounded text-blue-600 focus:ring-blue-500"
                />
              </div>
              <input
                type="time"
                disabled={!modalForm.hasCheckOut}
                value={modalForm.checkOutTime}
                onChange={(e) => setModalForm({ ...modalForm, checkOutTime: e.target.value })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-center focus:outline-hidden focus:ring-2 focus:ring-blue-500 disabled:opacity-40"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={() => setEditingAttendance(null)}
              className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSaving}
              className="px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-xs disabled:opacity-60"
            >
              {isSaving ? 'Saving Log...' : 'Save Attendance Log'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
