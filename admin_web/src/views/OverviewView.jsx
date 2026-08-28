import React from 'react';
import {
  Users,
  UserCheck,
  FileClock,
  CheckSquare,
  Clock,
  UserPlus,
  ArrowRight,
  Sparkles,
  ShieldCheck,
  CheckCircle2,
  AlertTriangle,
  Megaphone
} from 'lucide-react';
import { StatCard } from '../components/StatCard';
import { Badge } from '../components/Badge';
import { formatDate } from '../utils/dateUtils';

export const OverviewView = ({
  employees = [],
  requests = [],
  tasks = [],
  todayAttendance = [],
  setTab,
  onApproveRequest,
  onOpenRejectModal
}) => {
  // Metric Calculations
  const totalStaff = employees.length;
  const activeLogins = employees.filter(
    (e) => e.isActive !== false && e.status !== 'deactivated'
  ).length;
  const deactivatedLogins = totalStaff - activeLogins;

  const pendingRequests = requests.filter((r) =>
    (r.status || '').toLowerCase().includes('pending')
  );

  const pendingTasks = tasks.filter((t) => (t.status || 'Pending') !== 'Completed');

  const presentToday = todayAttendance.filter((a) => a.status !== 'Late').length;
  const lateToday = todayAttendance.filter((a) => a.status === 'Late').length;

  return (
    <div className="space-y-6">
      {/* Welcome Banner */}
      <div className="relative overflow-hidden bg-gradient-to-r from-blue-600 via-indigo-600 to-slate-900 rounded-3xl p-6 sm:p-8 text-white shadow-soft-lg">
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/15 backdrop-blur-md text-xs font-bold text-blue-100 mb-3 border border-white/20">
            <Sparkles className="w-3.5 h-3.5 text-blue-300" />
            <span>Enterprise Admin Portal Active</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
            Welcome back, System Administrator
          </h2>
          <p className="text-blue-100/90 text-xs sm:text-sm mt-2 font-medium leading-relaxed">
            Monitor real-time employee attendance, review automated leave deductions, assign company tasks, and broadcast notices directly to the ERMS mobile app.
          </p>
        </div>
        <div className="absolute right-0 bottom-0 translate-x-12 translate-y-12 w-64 h-64 bg-blue-400/10 rounded-full blur-2xl pointer-events-none" />
      </div>

      {/* KPI Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        <StatCard
          title="Total Staff"
          value={totalStaff}
          icon={Users}
          color="blue"
          subtitle={`${activeLogins} active logins`}
          onClick={() => setTab(1)}
        />
        <StatCard
          title="Pending Approvals"
          value={pendingRequests.length}
          icon={FileClock}
          color="amber"
          subtitle="Awaiting decision"
          onClick={() => setTab(3)}
        />
        <StatCard
          title="Present Today"
          value={presentToday + lateToday}
          icon={Clock}
          color="emerald"
          subtitle={`${lateToday} late arrival(s)`}
          onClick={() => setTab(4)}
        />
        <StatCard
          title="Active Tasks"
          value={pendingTasks.length}
          icon={CheckSquare}
          color="indigo"
          subtitle={`${tasks.length} total assigned`}
          onClick={() => setTab(5)}
        />
      </div>

      {/* Quick Action Shortcuts Grid */}
      <div>
        <h3 className="text-sm font-bold uppercase tracking-wider text-slate-500 mb-3">
          Quick Administrative Actions
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <button
            onClick={() => setTab(2)}
            className="flex items-center gap-3.5 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-soft hover:shadow-soft-lg hover:border-blue-300 transition-all text-left group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white transition-colors">
              <UserPlus className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900 group-hover:text-blue-600 transition-colors">
                + Onboard Employee
              </p>
              <p className="text-xs text-slate-500 font-medium">Provision account & quotas</p>
            </div>
          </button>

          <button
            onClick={() => setTab(3)}
            className="flex items-center gap-3.5 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-soft hover:shadow-soft-lg hover:border-amber-300 transition-all text-left group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-amber-50 text-amber-600 group-hover:bg-amber-600 group-hover:text-white transition-colors">
              <FileClock className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900 group-hover:text-amber-600 transition-colors">
                Review Requests
              </p>
              <p className="text-xs text-slate-500 font-medium">{pendingRequests.length} pending actions</p>
            </div>
          </button>

          <button
            onClick={() => setTab(5)}
            className="flex items-center gap-3.5 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-soft hover:shadow-soft-lg hover:border-indigo-300 transition-all text-left group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-indigo-50 text-indigo-600 group-hover:bg-indigo-600 group-hover:text-white transition-colors">
              <CheckSquare className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900 group-hover:text-indigo-600 transition-colors">
                Assign Tasks
              </p>
              <p className="text-xs text-slate-500 font-medium">Delegate & track staff</p>
            </div>
          </button>

          <button
            onClick={() => setTab(6)}
            className="flex items-center gap-3.5 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-soft hover:shadow-soft-lg hover:border-rose-300 transition-all text-left group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-rose-50 text-rose-600 group-hover:bg-rose-600 group-hover:text-white transition-colors">
              <Megaphone className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900 group-hover:text-rose-600 transition-colors">
                Broadcast Notice
              </p>
              <p className="text-xs text-slate-500 font-medium">Send company-wide alert</p>
            </div>
          </button>
        </div>
      </div>

      {/* Main Grid: Pending Requests Preview & Today's Attendance Snapshot */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Pending Requests Column (2 cols) */}
        <div className="lg:col-span-2 bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">Latest Pending Requests</h3>
              <p className="text-xs text-slate-500">Requires administrator review or quota deduction</p>
            </div>
            <button
              onClick={() => setTab(3)}
              className="text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1"
            >
              <span>View All ({pendingRequests.length})</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {pendingRequests.length === 0 ? (
            <div className="py-12 text-center rounded-2xl bg-slate-50 border border-dashed border-slate-200">
              <CheckCircle2 className="w-10 h-10 text-emerald-500 mx-auto mb-2" />
              <p className="text-sm font-bold text-slate-800">All requests are up to date!</p>
              <p className="text-xs text-slate-500 mt-0.5">No pending leaves or employee tickets</p>
            </div>
          ) : (
            <div className="space-y-3">
              {pendingRequests.slice(0, 4).map((req) => {
                const reqData = req.requestData || {};
                const leaveType = reqData.leaveType || req.requestType || 'Request';
                const days = reqData.numberOfDays || 1;

                return (
                  <div
                    key={req.id}
                    className="p-4 rounded-2xl bg-slate-50/70 border border-slate-200/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-slate-50 transition-colors"
                  >
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-slate-900">{req.employeeName || 'Staff Member'}</span>
                        <span className="text-xs text-slate-400">•</span>
                        <span className="text-xs font-medium text-slate-500">{req.department || 'General'}</span>
                        <Badge size="sm">{req.status}</Badge>
                      </div>
                      <p className="text-xs font-semibold text-blue-600">
                        {leaveType} {req.requestType === 'leave' && `(${days} day${days > 1 ? 's' : ''})`}
                      </p>
                      <p className="text-xs text-slate-500 line-clamp-1">
                        Reason: {reqData.reason || reqData.description || reqData.subject || reqData.title || 'Standard submission'}
                      </p>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      <button
                        onClick={() => onApproveRequest(req)}
                        className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-colors shadow-xs"
                      >
                        Approve
                      </button>
                      <button
                        onClick={() => onOpenRejectModal(req)}
                        className="px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition-colors"
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Live Attendance Snapshot (1 col) */}
        <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-base font-bold text-slate-900">Today's Check-Ins</h3>
                <p className="text-xs text-slate-500">Live attendance monitoring</p>
              </div>
              <button
                onClick={() => setTab(4)}
                className="text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1"
              >
                <span>Full Log</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Attendance Status Pill Summary */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="p-3 rounded-2xl bg-emerald-50 border border-emerald-100 text-center">
                <p className="text-xl font-extrabold text-emerald-700">{presentToday}</p>
                <p className="text-[11px] font-bold text-emerald-600 uppercase tracking-wider mt-0.5">On Time</p>
              </div>
              <div className="p-3 rounded-2xl bg-orange-50 border border-orange-100 text-center">
                <p className="text-xl font-extrabold text-orange-700">{lateToday}</p>
                <p className="text-[11px] font-bold text-orange-600 uppercase tracking-wider mt-0.5">Late</p>
              </div>
            </div>

            <div className="space-y-2">
              <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                Recent Check-Ins
              </div>
              {todayAttendance.length === 0 ? (
                <p className="text-xs text-slate-400 text-center py-6 font-medium">
                  No check-ins recorded yet today
                </p>
              ) : (
                todayAttendance.slice(0, 5).map((att) => (
                  <div
                    key={att.id}
                    className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100 text-xs"
                  >
                    <div className="min-w-0 pr-2">
                      <p className="font-bold text-slate-900 truncate">{att.employeeName || att.employeeEmail}</p>
                      <p className="text-[11px] text-slate-500">
                        In: {att.checkInTime ? formatDate(att.checkInTime, 'hh:mm a') : '—'}
                      </p>
                    </div>
                    <Badge size="sm">{att.status || 'Present'}</Badge>
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="mt-4 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500 font-medium">
            <span>Total Staff: {totalStaff}</span>
            <span className="font-bold text-slate-700">
              {totalStaff > 0 ? Math.round(((presentToday + lateToday) / totalStaff) * 100) : 0}% Turnout
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
