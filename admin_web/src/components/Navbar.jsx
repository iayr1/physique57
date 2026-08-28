import React, { useState, useEffect, useRef } from 'react';
import {
  Menu,
  Bell,
  Calendar,
  Clock,
  LogOut,
  Volume2,
  CheckCircle2,
  AlertCircle,
  Megaphone,
  FileCheck2,
  Check,
  X
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { format } from 'date-fns';
import { playNotificationChime } from '../utils/audioUtils';
import { requestBrowserNotificationPermission } from '../utils/notificationUtils';
import { formatDate } from '../utils/dateUtils';

export const Navbar = ({
  onMenuClick,
  currentTabTitle,
  pendingCount = 0,
  notifications = [],
  onSelectTab
}) => {
  const { currentUser, logout } = useAuth();
  const [time, setTime] = useState(new Date());
  const [isNotifOpen, setIsNotifOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setIsNotifOpen(false);
      }
    };
    if (isNotifOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isNotifOpen]);

  const handleEnableDesktopAlerts = async () => {
    const res = await requestBrowserNotificationPermission();
    if (res === 'granted') {
      playNotificationChime();
    }
  };

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  return (
    <header className="sticky top-0 z-30 h-20 bg-white/90 backdrop-blur-md border-b border-slate-200/80 px-4 sm:px-8 flex items-center justify-between">
      {/* Left: Mobile Menu & Tab Title */}
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition-colors cursor-pointer"
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

        {/* Real-Time Interactive Notification Dropdown */}
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setIsNotifOpen(!isNotifOpen)}
            className="relative flex items-center gap-2 px-3 py-1.5 rounded-xl bg-blue-50 hover:bg-blue-100/80 border border-blue-100 text-blue-800 text-xs font-bold transition-all cursor-pointer"
          >
            <Bell className="w-4 h-4 text-blue-600" />
            <span className="hidden sm:inline">Alerts</span>
            {pendingCount > 0 && (
              <span className="px-1.5 py-0.5 rounded-md bg-blue-600 text-white text-[11px] font-extrabold shadow-xs">
                {pendingCount}
              </span>
            )}
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 h-2.5 w-2.5 rounded-full bg-rose-500 ring-2 ring-white animate-ping" />
            )}
          </button>

          {/* Dropdown Menu */}
          {isNotifOpen && (
            <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-2xl shadow-soft-lg border border-slate-200/90 overflow-hidden z-50 animate-fade-in">
              {/* Dropdown Header */}
              <div className="px-4 py-3 bg-slate-50 border-b border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Bell className="w-4 h-4 text-blue-600" />
                  <h4 className="text-xs font-bold text-slate-900 uppercase tracking-wider">
                    Live System Alerts
                  </h4>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={playNotificationChime}
                    title="Test Audio Chime"
                    className="p-1 rounded-lg text-slate-500 hover:text-blue-600 hover:bg-slate-200/60 text-[11px] font-semibold flex items-center gap-1 transition-colors"
                  >
                    <Volume2 className="w-3.5 h-3.5" />
                    <span>Test Chime</span>
                  </button>
                </div>
              </div>

              {/* Desktop notification opt-in button */}
              {'Notification' in window && Notification.permission !== 'granted' && (
                <div className="p-3 bg-blue-50/70 border-b border-blue-100 flex items-center justify-between text-xs">
                  <span className="text-blue-900 font-medium">Enable browser desktop notifications?</span>
                  <button
                    onClick={handleEnableDesktopAlerts}
                    className="px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg text-[11px] transition-colors"
                  >
                    Enable
                  </button>
                </div>
              )}

              {/* Notification List */}
              <div className="max-h-80 overflow-y-auto divide-y divide-slate-100">
                {notifications.length === 0 ? (
                  <div className="py-8 text-center text-slate-400 text-xs">
                    No recent notifications
                  </div>
                ) : (
                  notifications.slice(0, 10).map((notif) => (
                    <div
                      key={notif.id}
                      onClick={() => {
                        setIsNotifOpen(false);
                        if (onSelectTab) onSelectTab(3); // Navigate to requests tab
                      }}
                      className={`p-3.5 hover:bg-slate-50 transition-colors cursor-pointer text-xs ${
                        !notif.isRead ? 'bg-blue-50/30' : ''
                      }`}
                    >
                      <div className="flex items-start gap-2.5">
                        <div className="p-1.5 rounded-lg bg-blue-100 text-blue-700 mt-0.5 shrink-0">
                          <FileCheck2 className="w-3.5 h-3.5" />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="font-bold text-slate-900 truncate">{notif.title}</p>
                          <p className="text-slate-600 text-[11px] line-clamp-2 mt-0.5">
                            {notif.message}
                          </p>
                          <p className="text-slate-400 text-[10px] mt-1 font-mono">
                            {formatDate(notif.timestamp, 'dd MMM, hh:mm a')}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Footer */}
              <div className="px-4 py-2.5 bg-slate-50/70 border-t border-slate-100 text-center">
                <button
                  onClick={() => {
                    setIsNotifOpen(false);
                    if (onSelectTab) onSelectTab(3);
                  }}
                  className="text-xs font-bold text-blue-600 hover:text-blue-700"
                >
                  View All Review Requests →
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Admin Avatar & Quick Signout */}
        <div className="flex items-center gap-2 pl-2 border-l border-slate-200">
          <div className="h-9 w-9 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-bold flex items-center justify-center text-xs shadow-sm shadow-blue-500/20">
            AD
          </div>
          <button
            onClick={logout}
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-200 transition-colors cursor-pointer"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </header>
  );
};
