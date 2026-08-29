import React from 'react';
import {
  LayoutDashboard,
  Users,
  UserPlus,
  FileCheck2,
  Clock,
  CheckSquare,
  Megaphone,
  ShieldCheck,
  Banknote,
  Calendar,
  HeartPulse,
  LogOut,
  ChevronRight
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const navItems = [
  { id: 'overview', index: 0, label: 'Overview', icon: LayoutDashboard, badgeKey: null },
  { id: 'employees', index: 1, label: 'Employee Directory', icon: Users, badgeKey: 'employees' },
  { id: 'onboarding', index: 2, label: '+ Onboard Employee', icon: UserPlus, badgeKey: null },
  { id: 'compensation', index: 8, label: 'Compensation & Payroll', icon: Banknote, badgeKey: null },
  { id: 'leave_quotas', index: 9, label: 'Leave Quotas & Rules', icon: Calendar, badgeKey: null },
  { id: 'health_wellness', index: 10, label: 'Health & Mediclaim', icon: HeartPulse, badgeKey: null },
  { id: 'requests', index: 3, label: 'Review Requests', icon: FileCheck2, badgeKey: 'pendingRequests' },
  { id: 'attendance', index: 4, label: 'Attendance Logs', icon: Clock, badgeKey: null },
  { id: 'tasks', index: 5, label: 'Task Management', icon: CheckSquare, badgeKey: 'pendingTasks' },
  { id: 'announcements', index: 6, label: 'Broadcast Notices', icon: Megaphone, badgeKey: null },
  { id: 'audit', index: 7, label: 'Audit Trail & Compliance', icon: ShieldCheck, badgeKey: null },
];

export const Sidebar = ({ currentTab, setTab, counts = {}, isMobileOpen, setIsMobileOpen }) => {
  const { logout, currentUser } = useAuth();

  const handleSelect = (tabIndex) => {
    setTab(tabIndex);
    if (setIsMobileOpen) setIsMobileOpen(false);
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-950/70 lg:hidden transition-opacity"
          onClick={() => setIsMobileOpen(false)}
        />
      )}

      <aside
        className={`fixed top-0 left-0 bottom-0 z-40 w-72 bg-[#FFFDF5] border-r-3 border-neo-border flex flex-col transition-transform duration-300 ease-out lg:translate-x-0 ${
          isMobileOpen ? 'translate-x-0 shadow-brutal-lg' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="h-20 flex items-center gap-3.5 px-6 border-b-3 border-neo-border bg-[#FFDE59]">
          <img
            src="/logo.jpg"
            alt="Physique 57"
            className="h-11 w-11 rounded-xl object-cover border-2 border-neo-border shadow-brutal-sm shrink-0"
          />
          <div>
            <div className="flex items-center gap-1.5">
              <h1 className="text-lg font-black text-neo-border tracking-tight font-display">Physique 57</h1>
              <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-black bg-neo-pink text-neo-border border border-neo-border uppercase tracking-wider">
                PRO
              </span>
            </div>
            <p className="text-xs text-neo-border font-extrabold opacity-80">Enterprise Admin Console</p>
          </div>
        </div>

        {/* Navigation List */}
        <div className="flex-1 overflow-y-auto py-5 px-4 space-y-2">
          <div className="px-3 pb-2 text-[11px] font-black text-neo-border uppercase tracking-widest opacity-70">
            Main Management
          </div>

          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.index;
            const badgeCount = item.badgeKey ? counts[item.badgeKey] : null;

            return (
              <button
                key={item.id}
                onClick={() => handleSelect(item.index)}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-black transition-all duration-150 group cursor-pointer ${
                  isActive
                    ? 'bg-neo-yellow text-neo-border border-2 border-neo-border shadow-brutal-sm translate-x-1'
                    : 'text-neo-border hover:bg-neo-cyan/30 hover:border-2 hover:border-neo-border border-2 border-transparent'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`p-1 rounded-lg ${isActive ? 'text-neo-border' : 'text-neo-border opacity-70 group-hover:opacity-100'}`}>
                    <Icon className="w-4 h-4 stroke-[2.5]" />
                  </div>
                  <span>{item.label}</span>
                </div>

                <div className="flex items-center gap-1.5">
                  {badgeCount !== null && badgeCount > 0 && (
                    <span
                      className={`px-2 py-0.5 text-[10px] rounded-md font-black border border-neo-border ${
                        isActive
                          ? 'bg-neo-pink text-neo-border'
                          : 'bg-neo-cyan text-neo-border'
                      }`}
                    >
                      {badgeCount}
                    </span>
                  )}
                  {isActive && <ChevronRight className="w-4 h-4 stroke-[3]" />}
                </div>
              </button>
            );
          })}
        </div>

        {/* Admin Profile & Logout Footer */}
        <div className="p-4 border-t-3 border-neo-border bg-[#FFDE59]/40">
          <div className="flex items-center justify-between p-3 rounded-xl bg-white border-2 border-neo-border shadow-brutal-sm mb-2">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="h-9 w-9 rounded-lg bg-neo-purple text-neo-border border border-neo-border font-black flex items-center justify-center text-xs shrink-0 shadow-brutal-sm">
                {(currentUser?.name || 'A').charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="text-xs font-black text-neo-border">
                  {currentUser?.name || 'Administrator'}
                </p>
                <p className="text-[10px] text-neo-border opacity-80 font-mono">{currentUser?.email || 'admin@gmail.com'}</p>
              </div>
            </div>
            <button
              onClick={logout}
              title="Logout"
              className="p-1.5 text-neo-border hover:bg-neo-pink rounded-lg border border-neo-border transition-colors cursor-pointer"
            >
              <LogOut className="w-4 h-4 stroke-[2.5]" />
            </button>
          </div>

          <div className="flex items-center justify-between text-[10px] text-neo-border px-1 font-black">
            <span>Firebase Connected</span>
            <span className="flex items-center gap-1 text-emerald-700 font-black">
              <span className="h-2 w-2 rounded-full bg-neo-green border border-neo-border animate-pulse" />
              Live Sync
            </span>
          </div>
        </div>
      </aside>
    </>
  );
};
