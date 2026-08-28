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
  LogOut,
  Sparkles,
  ExternalLink
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const navItems = [
  { id: 'overview', index: 0, label: 'Overview', icon: LayoutDashboard, badgeKey: null },
  { id: 'employees', index: 1, label: 'Employee Directory', icon: Users, badgeKey: 'employees' },
  { id: 'onboarding', index: 2, label: '+ Onboard Employee', icon: UserPlus, badgeKey: null },
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
          className="fixed inset-0 z-40 bg-slate-900/50 backdrop-blur-xs lg:hidden"
          onClick={() => setIsMobileOpen(false)}
        />
      )}

      <aside
        className={`fixed top-0 left-0 bottom-0 z-40 w-72 bg-white border-r border-slate-200/80 flex flex-col transition-transform duration-300 ease-in-out lg:translate-x-0 ${
          isMobileOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="h-20 flex items-center gap-3.5 px-6 border-b border-slate-100 bg-slate-50/50">
          <div className="h-11 w-11 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white shadow-md shadow-blue-500/20">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <h1 className="text-base font-extrabold text-slate-900 tracking-tight">ERMS Portal</h1>
              <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-blue-100 text-blue-700">
                PRO
              </span>
            </div>
            <p className="text-xs text-slate-500 font-medium">Enterprise Admin Console</p>
          </div>
        </div>

        {/* Navigation List */}
        <div className="flex-1 overflow-y-auto py-5 px-4 space-y-1">
          <div className="px-3 pb-2 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
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
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-semibold transition-all duration-150 ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-sm shadow-blue-600/30'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100/80'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4.5 h-4.5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>
                {badgeCount !== null && badgeCount > 0 && (
                  <span
                    className={`px-2 py-0.5 text-xs rounded-full font-bold ${
                      isActive ? 'bg-white/20 text-white' : 'bg-blue-100 text-blue-700'
                    }`}
                  >
                    {badgeCount}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Admin Profile & Logout Footer */}
        <div className="p-4 border-t border-slate-100 bg-slate-50/70">
          <div className="flex items-center justify-between p-2.5 rounded-xl bg-white border border-slate-200/80 shadow-xs mb-2">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="h-9 w-9 rounded-lg bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center text-sm shrink-0">
                AD
              </div>
              <div className="min-w-0">
                <p className="text-xs font-bold text-slate-900 truncate">
                  {currentUser?.name || 'Administrator'}
                </p>
                <p className="text-[11px] text-slate-500 truncate">{currentUser?.email || 'admin@gmail.com'}</p>
              </div>
            </div>
            <button
              onClick={logout}
              title="Logout"
              className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
          <div className="flex items-center justify-between text-[11px] text-slate-400 px-1 font-medium">
            <span>Firebase Connected</span>
            <span className="flex items-center gap-1 text-emerald-600 font-semibold">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Live Sync
            </span>
          </div>
        </div>
      </aside>
    </>
  );
};
