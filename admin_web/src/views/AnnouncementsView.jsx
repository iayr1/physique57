import React, { useState } from 'react';
import {
  Megaphone,
  Send,
  Trash2,
  AlertTriangle,
  Bell,
  Clock,
  Sparkles,
  CheckCircle2
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { formatDate } from '../utils/dateUtils';
import { db } from '../firebase/config';
import { doc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';

export const AnnouncementsView = ({ announcements = [] }) => {
  const { addToast } = useToast();

  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [priority, setPriority] = useState('Normal');
  const [isBroadcasting, setIsBroadcasting] = useState(false);

  const handleBroadcast = async (e) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) {
      addToast('Please enter both announcement title and message content.', 'error');
      return;
    }

    setIsBroadcasting(true);
    const annId = `ANN-${Date.now()}`;
    const notifId = `NOTIF-${Date.now()}`;
    const auditId = `AUD-${Date.now()}`;

    try {
      // 1. Create announcement document
      await setDoc(doc(db, 'announcements', annId), {
        id: annId,
        title: title.trim(),
        message: message.trim(),
        priority: priority,
        createdBy: 'System Administrator',
        createdAt: serverTimestamp(),
      });

      // 2. Broadcast in-app notification to all users
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `📢 ${title.trim()}`,
        message: message.trim(),
        requestId: annId,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: 'all',
      });

      // 3. Record audit log
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'ANNOUNCEMENT_BROADCAST',
        performedBy: 'admin@gmail.com',
        targetEmail: 'all',
        details: `Title: ${title.trim()} (${priority})`,
        timestamp: serverTimestamp(),
      });

      addToast('✓ Notice broadcast to all employee devices in real-time!', 'success');
      setTitle('');
      setMessage('');
      setPriority('Normal');
    } catch (err) {
      addToast(`Failed to broadcast: ${err.message}`, 'error');
    } finally {
      setIsBroadcasting(false);
    }
  };

  const handleDeleteAnnouncement = async (annId) => {
    try {
      await deleteDoc(doc(db, 'announcements', annId));
      addToast('Announcement removed.', 'success');
    } catch (err) {
      addToast(`Error deleting announcement: ${err.message}`, 'error');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft">
        <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
          Company Announcements & Organization Broadcasts
        </h3>
        <p className="text-xs text-slate-500 mt-0.5 font-medium">
          Publish notices, townhall meetings, and urgent policy updates directly to all employee mobile applications.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Compose Form (1 col) */}
        <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft h-fit">
          <div className="flex items-center gap-2 mb-4">
            <Megaphone className="w-5 h-5 text-blue-600" />
            <h4 className="text-sm font-bold text-slate-900">Create Broadcast Notice</h4>
          </div>

          <form onSubmit={handleBroadcast} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Notice Title *
              </label>
              <input
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Office Holiday Notice / Q3 Townhall"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Priority Level
              </label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              >
                <option value="Normal">Normal (General Information)</option>
                <option value="Important">Important (High Priority)</option>
                <option value="Urgent">🚨 Urgent (Action Required)</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Broadcast Content / Message *
              </label>
              <textarea
                rows="4"
                required
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Type the full announcement message for all staff..."
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>

            <button
              type="submit"
              disabled={isBroadcasting}
              className="w-full py-3 px-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold rounded-xl text-xs shadow-md shadow-blue-500/20 flex items-center justify-center gap-2 transition-all cursor-pointer disabled:opacity-60"
            >
              <Send className="w-3.5 h-3.5" />
              <span>{isBroadcasting ? 'Broadcasting...' : 'Broadcast to All Staff Devices'}</span>
            </button>
          </form>
        </div>

        {/* Active Broadcasts Feed (2 cols) */}
        <div className="lg:col-span-2 bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft">
          <h4 className="text-sm font-bold text-slate-900 mb-4">
            Active Broadcast Notices ({announcements.length})
          </h4>

          {announcements.length === 0 ? (
            <div className="p-12 text-center rounded-2xl bg-slate-50 border border-dashed border-slate-200">
              <Bell className="w-10 h-10 text-slate-300 mx-auto mb-2" />
              <p className="text-sm font-bold text-slate-800">No active broadcast notices</p>
              <p className="text-xs text-slate-400 mt-0.5">
                Published company announcements will appear here and in employee inboxes.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {announcements.map((ann) => {
                let priorityBg = 'bg-blue-50 text-blue-700 border-blue-200';
                if (ann.priority === 'Important') {
                  priorityBg = 'bg-orange-50 text-orange-700 border-orange-200';
                } else if (ann.priority === 'Urgent') {
                  priorityBg = 'bg-rose-50 text-rose-700 border-rose-200';
                }

                return (
                  <div
                    key={ann.id}
                    className="p-5 rounded-2xl bg-slate-50/70 border border-slate-200/80 flex items-start justify-between gap-4 hover:bg-slate-50 transition-colors"
                  >
                    <div className="space-y-2">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className={`px-2.5 py-0.5 rounded-md text-[10px] font-extrabold uppercase tracking-wider border ${priorityBg}`}>
                          {ann.priority || 'Normal'}
                        </span>
                        <h5 className="text-sm font-bold text-slate-900">{ann.title}</h5>
                      </div>

                      <p className="text-xs text-slate-700 leading-relaxed">{ann.message}</p>

                      <div className="flex items-center gap-3 text-[11px] text-slate-400 font-medium pt-1">
                        <span>By {ann.createdBy || 'Administrator'}</span>
                        <span>•</span>
                        <span>Published: {formatDate(ann.createdAt, 'dd MMM yyyy, hh:mm a')}</span>
                      </div>
                    </div>

                    <button
                      onClick={() => handleDeleteAnnouncement(ann.id)}
                      className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors shrink-0"
                      title="Delete Announcement"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
