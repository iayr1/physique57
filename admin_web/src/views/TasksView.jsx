import React, { useState } from 'react';
import {
  CheckSquare,
  Plus,
  Search,
  Calendar,
  User,
  Trash2,
  CheckCircle2,
  Clock,
  AlertCircle,
  Sparkles
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { formatDate } from '../utils/dateUtils';
import { db } from '../firebase/config';
import { doc, setDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';

export const TasksView = ({ tasks = [], employees = [] }) => {
  const { addToast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form State
  const [taskForm, setTaskForm] = useState({
    title: '',
    description: '',
    dueDate: '',
    priority: 'Medium',
    assignedToEmail: '',
    assignedToName: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const filteredTasks = tasks.filter((t) => {
    const q = searchQuery.toLowerCase().trim();
    const title = (t.title || '').toLowerCase();
    const desc = (t.description || '').toLowerCase();
    const assignee = (t.assignedToName || t.assignedToEmail || '').toLowerCase();

    const matchesQuery = !q || title.includes(q) || desc.includes(q) || assignee.includes(q);
    const matchesStatus =
      statusFilter === 'All' ||
      (statusFilter === 'Pending' && t.status !== 'Completed') ||
      (statusFilter === 'Completed' && t.status === 'Completed');

    return matchesQuery && matchesStatus;
  });

  const handleAssignTask = async (e) => {
    e.preventDefault();
    if (!taskForm.title.trim() || !taskForm.assignedToEmail) {
      addToast('Please provide a task title and select an employee assignee.', 'error');
      return;
    }

    setIsSubmitting(true);
    const taskId = `TASK-${Date.now()}`;

    try {
      await setDoc(doc(db, 'tasks', taskId), {
        id: taskId,
        title: taskForm.title.trim(),
        description: taskForm.description.trim(),
        dueDate: taskForm.dueDate || null,
        priority: taskForm.priority,
        assignedToEmail: taskForm.assignedToEmail,
        assignedToName: taskForm.assignedToName,
        assignedBy: 'admin@gmail.com',
        status: 'Pending',
        createdAt: serverTimestamp(),
      });

      // Send in-app notification to employee
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `📋 New Task Assigned: ${taskForm.title}`,
        message: taskForm.description.trim() || 'You have been assigned a new organizational task.',
        requestId: taskId,
        timestamp: serverTimestamp(),
        isRead: false,
        recipientEmail: taskForm.assignedToEmail,
      });

      // Audit log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'TASK_ASSIGNED',
        performedBy: 'admin@gmail.com',
        targetEmail: taskForm.assignedToEmail,
        details: `Task: ${taskForm.title} (${taskId})`,
        timestamp: serverTimestamp(),
      });

      addToast(`✓ Task assigned to ${taskForm.assignedToName}!`, 'success');
      setIsModalOpen(false);
      setTaskForm({
        title: '',
        description: '',
        dueDate: '',
        priority: 'Medium',
        assignedToEmail: '',
        assignedToName: '',
      });
    } catch (err) {
      addToast(`Failed to assign task: ${err.message}`, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleTaskStatus = async (task) => {
    const isCompleted = task.status === 'Completed';
    const newStatus = isCompleted ? 'Pending' : 'Completed';

    try {
      await updateDoc(doc(db, 'tasks', task.id), {
        status: newStatus,
        completedAt: newStatus === 'Completed' ? serverTimestamp() : null,
      });
      addToast(`Task marked as ${newStatus}`, 'success');
    } catch (err) {
      addToast(`Failed to update task: ${err.message}`, 'error');
    }
  };

  const handleDeleteTask = async (taskId) => {
    try {
      await deleteDoc(doc(db, 'tasks', taskId));
      addToast('Task deleted successfully', 'success');
    } catch (err) {
      addToast(`Failed to delete task: ${err.message}`, 'error');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
            Staff Task Delegation & Performance Tracking
          </h3>
          <p className="text-xs text-slate-500 mt-0.5 font-medium">
            Assign deliverables to staff members and monitor real-time completion status.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-xs shrink-0 cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>+ Assign New Task</span>
        </button>
      </div>

      {/* Filter & Search */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="relative sm:col-span-2">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by task title, description, or staff member..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          />
        </div>

        <div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            <option value="All">All Task Statuses</option>
            <option value="Pending">Pending / In Progress</option>
            <option value="Completed">Completed</option>
          </select>
        </div>
      </div>

      {/* Task Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredTasks.length === 0 ? (
          <div className="col-span-full bg-white rounded-3xl p-12 text-center border border-slate-200/80 shadow-soft">
            <CheckSquare className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-sm font-bold text-slate-800">No tasks found</p>
            <p className="text-xs text-slate-400 mt-1">
              There are currently no delegated staff tasks matching your filters.
            </p>
          </div>
        ) : (
          filteredTasks.map((t) => {
            const isDone = t.status === 'Completed';

            return (
              <div
                key={t.id}
                className={`bg-white rounded-3xl p-5 border shadow-soft transition-all flex flex-col justify-between ${
                  isDone ? 'border-emerald-200/80 bg-emerald-50/20' : 'border-slate-200/80'
                }`}
              >
                <div>
                  <div className="flex items-center justify-between gap-2 mb-3">
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider ${
                        t.priority === 'High'
                          ? 'bg-rose-50 text-rose-700 border border-rose-200'
                          : t.priority === 'Low'
                          ? 'bg-slate-100 text-slate-700 border border-slate-200'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                    >
                      {t.priority || 'Medium'} Priority
                    </span>
                    <Badge size="sm">{t.status || 'Pending'}</Badge>
                  </div>

                  <h4 className={`text-sm font-bold text-slate-900 ${isDone ? 'line-through opacity-70' : ''}`}>
                    {t.title}
                  </h4>
                  {t.description && (
                    <p className="text-xs text-slate-600 mt-1.5 line-clamp-3 leading-relaxed">
                      {t.description}
                    </p>
                  )}
                </div>

                <div className="mt-4 pt-4 border-t border-slate-100 space-y-3">
                  <div className="flex items-center justify-between text-xs text-slate-500 font-medium">
                    <div className="flex items-center gap-1.5">
                      <User className="w-3.5 h-3.5 text-blue-600" />
                      <span className="font-bold text-slate-800 truncate max-w-[120px]">
                        {t.assignedToName || t.assignedToEmail}
                      </span>
                    </div>

                    {t.dueDate && (
                      <div className="flex items-center gap-1 text-[11px] font-mono text-slate-400">
                        <Calendar className="w-3 h-3" />
                        <span>{t.dueDate}</span>
                      </div>
                    )}
                  </div>

                  <div className="flex items-center justify-between gap-2">
                    <button
                      onClick={() => handleToggleTaskStatus(t)}
                      className={`flex-1 py-1.5 rounded-xl text-xs font-bold border transition-colors flex items-center justify-center gap-1.5 cursor-pointer ${
                        isDone
                          ? 'bg-slate-100 text-slate-700 border-slate-200 hover:bg-slate-200'
                          : 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100'
                      }`}
                    >
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>{isDone ? 'Reopen Task' : 'Mark Completed'}</span>
                    </button>

                    <button
                      onClick={() => handleDeleteTask(t.id)}
                      className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors"
                      title="Delete Task"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Assign Task Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Assign New Task to Employee"
      >
        <form onSubmit={handleAssignTask} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Task Title *
            </label>
            <input
              type="text"
              required
              value={taskForm.title}
              onChange={(e) => setTaskForm({ ...taskForm, title: e.target.value })}
              placeholder="e.g. Prepare Monthly Revenue & Attendance Audit"
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Assignee Employee *
            </label>
            <select
              required
              value={taskForm.assignedToEmail}
              onChange={(e) => {
                const selectedEmail = e.target.value;
                const emp = employees.find((x) => x.email === selectedEmail);
                setTaskForm({
                  ...taskForm,
                  assignedToEmail: selectedEmail,
                  assignedToName: emp ? emp.name : selectedEmail,
                });
              }}
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select an employee from directory...</option>
              {employees.map((emp) => (
                <option key={emp.email || emp.id} value={emp.email}>
                  {emp.name} ({emp.email}) — {emp.department || 'General'}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Detailed Instructions / Description
            </label>
            <textarea
              rows="3"
              value={taskForm.description}
              onChange={(e) => setTaskForm({ ...taskForm, description: e.target.value })}
              placeholder="Provide context, links, or expectations for the staff member..."
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Priority Level
              </label>
              <select
                value={taskForm.priority}
                onChange={(e) => setTaskForm({ ...taskForm, priority: e.target.value })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500"
              >
                <option value="Low">Low Priority</option>
                <option value="Medium">Medium Priority</option>
                <option value="High">🚨 High Priority</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Target Due Date
              </label>
              <input
                type="date"
                value={taskForm.dueDate}
                onChange={(e) => setTaskForm({ ...taskForm, dueDate: e.target.value })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-center focus:outline-hidden focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-xs disabled:opacity-60"
            >
              {isSubmitting ? 'Delegating Task...' : 'Delegate & Assign Task'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
