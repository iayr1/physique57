import React, { useState, useEffect } from 'react';
import {
  Menu,
  Bell,
  Search,
  Calendar,
  Clock,
  ShieldCheck,
  RefreshCw,
  LogOut
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { format } from 'date-fns';

export const Navbar = ({ onMenuClick, currentTabTitle, pendingCount = 0 }) => {
  const { currentUser, logout } = useAuth();
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="sticky top-0 z-30 h-20 bg-white/90 backdrop-blur-md border-b border-slate-200/80 px-4 sm:px-8 flex items-center justify-between">
      {/* Left: Mobile Menu & Tab Title */}
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition-colors"
        >
          <Menu className="w-5 h-5" />
        </button>
        <div>
          <h2 className="text-xl font-extrabold text-slate-900 tracking-tight">{currentTabTitle}</h2>
          <p className="hidden sm:block text-xs font-medium text-slate-500">
            Real-time Enterprise Resource & Management System
          </p>
        </div>
      </div>

      {/* Right: Live Clock, Status & Actions */}
      <div className="flex items-center gap-3 sm:gap-4">
        {/* Live Clock */}
        <div className="hidden md:flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-slate-100/80 border border-slate-200 text-xs font-semibold text-slate-700">
          <Calendar className="w-3.5 h-3.5 text-blue-600" />
          <span>{format(time, 'EEE, dd MMM yyyy')}</span>
          <span className="text-slate-300">•</span>
          <Clock className="w-3.5 h-3.5 text-indigo-600" />
          <span className="font-mono">{format(time, 'hh:mm:ss a')}</span>
        </div>

        {/* Notifications preview pill */}
        <div className="relative">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-blue-50 border border-blue-100 text-blue-800 text-xs font-bold">
            <Bell className="w-3.5 h-3.5 text-blue-600" />
            <span className="hidden sm:inline">Pending Actions:</span>
            <span className="px-1.5 py-0.5 rounded-md bg-blue-600 text-white text-[11px] font-extrabold">
              {pendingCount}
            </span>
          </div>
        </div>

        {/* Admin Avatar & Quick Signout */}
        <div className="flex items-center gap-2 pl-2 border-l border-slate-200">
          <div className="h-9 w-9 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-bold flex items-center justify-center text-xs shadow-sm shadow-blue-500/20">
            AD
          </div>
          <button
            onClick={logout}
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-200 transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </header>
  );
};
