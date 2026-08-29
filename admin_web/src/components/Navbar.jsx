import React, { useState, useEffect, useRef } from 'react';
import {
  Menu,
  Bell,
  Calendar,
  Clock,
  LogOut,
  Volume2,
  FileCheck2
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
    <header className="sticky top-0 z-30 h-20 bg-[#FFFDF5] border-b-3 border-neo-border px-4 sm:px-8 flex items-center justify-between transition-all">
      {/* Left: Mobile Menu & Tab Title */}
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 text-neo-border bg-neo-yellow border-2 border-neo-border rounded-xl shadow-brutal-sm cursor-pointer"
        >
          <Menu className="w-5 h-5 stroke-[2.5]" />
        </button>
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-xl font-black text-neo-border tracking-tight font-display">{currentTabTitle}</h2>
            <span className="h-2.5 w-2.5 rounded-full bg-neo-green border border-neo-border animate-pulse hidden sm:block" title="Real-time stream active" />
          </div>
          <p className="hidden sm:block text-xs font-bold text-neo-border opacity-70 mt-0.5">
            Real-Time Enterprise Resource Management Console
          </p>
        </div>
      </div>

      {/* Right: Live Clock, Status & Actions */}
      <div className="flex items-center gap-3 sm:gap-4">
        {/* Live Clock */}
        <div className="hidden md:flex items-center gap-2.5 px-4 py-2 rounded-xl bg-white border-2 border-neo-border shadow-brutal-sm text-xs font-black text-neo-border">
          <Calendar className="w-4 h-4 text-neo-indigo stroke-[2.5]" />
          <span>{format(time, 'EEE, dd MMM yyyy')}</span>
          <span className="text-neo-border font-black">•</span>
          <Clock className="w-4 h-4 text-neo-purple stroke-[2.5]" />
          <span className="font-mono text-neo-border">{format(time, 'hh:mm:ss a')}</span>
        </div>

        {/* Real-Time Interactive Notification Dropdown */}
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setIsNotifOpen(!isNotifOpen)}
            className="relative flex items-center gap-2 px-3.5 py-2 rounded-xl bg-neo-yellow border-2 border-neo-border text-neo-border text-xs font-black transition-all cursor-pointer shadow-brutal-sm hover:translate-x-0.5 hover:translate-y-0.5"
          >
            <Bell className="w-4 h-4 text-neo-border stroke-[2.5]" />
            <span className="hidden sm:inline">Alerts</span>
            {pendingCount > 0 && (
              <span className="px-2 py-0.5 rounded-md bg-neo-pink text-neo-border border border-neo-border text-[10px] font-black">
                {pendingCount}
              </span>
            )}
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 h-3.5 w-3.5 rounded-full bg-neo-pink border-2 border-neo-border animate-ping" />
            )}
          </button>

          {/* Dropdown Menu */}
          {isNotifOpen && (
            <div className="absolute right-0 mt-3 w-80 sm:w-96 bg-white rounded-2xl shadow-brutal-lg border-3 border-neo-border overflow-hidden z-50 animate-fade-in">
              {/* Dropdown Header */}
              <div className="px-4 py-3.5 bg-neo-yellow border-b-2 border-neo-border flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Bell className="w-4 h-4 text-neo-border stroke-[2.5]" />
                  <h4 className="text-xs font-black text-neo-border uppercase tracking-wider font-display">
                    Live System Alerts
                  </h4>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={playNotificationChime}
                    title="Test Audio Chime"
                    className="px-2.5 py-1 rounded-lg bg-white border border-neo-border text-neo-border text-[11px] font-black flex items-center gap-1 transition-colors cursor-pointer shadow-brutal-sm"
                  >
                    <Volume2 className="w-3.5 h-3.5" />
                    <span>Chime</span>
                  </button>
                </div>
              </div>

              {'Notification' in window && Notification.permission !== 'granted' && (
                <div className="p-3 bg-neo-cyan/30 border-b-2 border-neo-border flex items-center justify-between text-xs">
                  <span className="text-neo-border font-bold">Enable desktop alerts?</span>
                  <button
                    onClick={handleEnableDesktopAlerts}
                    className="px-2.5 py-1 bg-neo-indigo text-white font-black rounded-lg text-[11px] border border-neo-border shadow-brutal-sm"
                  >
                    Enable
                  </button>
                </div>
              )}

              {/* Notification List */}
              <div className="max-h-80 overflow-y-auto divide-y-2 divide-neo-border/20">
                {notifications.length === 0 ? (
                  <div className="py-10 text-center text-neo-border text-xs font-bold opacity-70">
                    No recent system notifications
                  </div>
                ) : (
                  notifications.slice(0, 10).map((notif) => (
                    <div
                      key={notif.id}
                      onClick={() => {
                        setIsNotifOpen(false);
                        if (onSelectTab) onSelectTab(3);
                      }}
                      className={`p-4 hover:bg-neo-yellow/20 transition-colors cursor-pointer text-xs ${
                        !notif.isRead ? 'bg-neo-yellow/30 font-bold' : ''
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className="p-2 rounded-lg bg-neo-cyan border border-neo-border text-neo-border mt-0.5 shrink-0 shadow-brutal-sm">
                          <FileCheck2 className="w-4 h-4" />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="font-black text-neo-border">{notif.title}</p>
                          <p className="text-neo-border text-[11px] mt-0.5 leading-relaxed font-semibold">
                            {notif.message}
                          </p>
                          <p className="text-neo-border/70 text-[10px] mt-1 font-mono font-bold">
                            {formatDate(notif.timestamp, 'dd MMM, hh:mm a')}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Footer */}
              <div className="px-4 py-3 bg-[#FFFDF5] border-t-2 border-neo-border text-center">
                <button
                  onClick={() => {
                    setIsNotifOpen(false);
                    if (onSelectTab) onSelectTab(3);
                  }}
                  className="text-xs font-black text-neo-indigo hover:underline cursor-pointer"
                >
                  View All Review Requests →
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Admin Avatar & Quick Signout */}
        <div className="flex items-center gap-2.5 pl-3 border-l-2 border-neo-border">
          <div className="h-9 w-9 rounded-xl bg-neo-purple text-neo-border border-2 border-neo-border font-black flex items-center justify-center text-xs shadow-brutal-sm shrink-0">
            {(currentUser?.name || 'A').charAt(0).toUpperCase()}
          </div>
          <button
            onClick={logout}
            className="hidden sm:flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-black text-white bg-rose-600 border-2 border-neo-border shadow-brutal-sm hover:translate-x-0.5 hover:translate-y-0.5 transition-all cursor-pointer"
          >
            <LogOut className="w-3.5 h-3.5 stroke-[2.5]" />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </header>
  );
};
