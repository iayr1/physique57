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
  Play,
  RotateCcw,
  Sparkles,
  LayoutGrid,
  Kanban,
  ArrowRight,
  ArrowLeft,
  MoreVertical
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { formatDate } from '../utils/dateUtils';
import { db } from '../firebase/config';
import { doc, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { useToast } from '../components/Toast';
import { useAuth } from '../context/AuthContext';

export const TasksView = ({ tasks = [], employees = [] }) => {
  const { addToast } = useToast();
  const { currentUser } = useAuth();

  // Layout View Switcher: 'kanban' | 'grid'
  const [viewMode, setViewMode] = useState('kanban');

  // Filter States
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [priorityFilter, setPriorityFilter] = useState('All');
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

  // Metric Computations
  const totalTasks = tasks.length;
  const pendingCount = tasks.filter((t) => (t.status || 'Pending') === 'Pending').length;
  const inProgressCount = tasks.filter((t) => t.status === 'In Progress').length;
  const completedCount = tasks.filter((t) => t.status === 'Completed').length;

  const filteredTasks = tasks.filter((t) => {
    const q = searchQuery.toLowerCase().trim();
    const title = (t.title || '').toLowerCase();
    const desc = (t.description || '').toLowerCase();
    const assignee = (t.assignedToName || t.assignedToEmail || '').toLowerCase();

    const matchesQuery = !q || title.includes(q) || desc.includes(q) || assignee.includes(q);
    const matchesStatus =
      statusFilter === 'All' ||
      (statusFilter === 'Pending' && (t.status === 'Pending' || !t.status)) ||
      (statusFilter === 'In Progress' && t.status === 'In Progress') ||
      (statusFilter === 'Completed' && t.status === 'Completed');

    const matchesPriority =
      priorityFilter === 'All' || (t.priority || 'Medium') === priorityFilter;

    return matchesQuery && matchesStatus && matchesPriority;
  });

  // Split tasks by status for Kanban Board
  const pendingTasksList = filteredTasks.filter((t) => (t.status || 'Pending') === 'Pending');
  const inProgressTasksList = filteredTasks.filter((t) => t.status === 'In Progress');
  const completedTasksList = filteredTasks.filter((t) => t.status === 'Completed');

  const handleAssignTask = async (e) => {
    e.preventDefault();
    if (!taskForm.title.trim() || !taskForm.assignedToEmail) {
      addToast('Please provide a task title and select an employee assignee.', 'error');
      return;
    }

    setIsSubmitting(true);
    const taskId = `TASK-${Date.now()}`;
    const adminEmail = currentUser?.email || 'admin@physique57.com';

    try {
      let dueDateValue = null;
      if (taskForm.dueDate) {
        const parsed = new Date(taskForm.dueDate);
        if (!isNaN(parsed.getTime())) {
          dueDateValue = Timestamp.fromDate(parsed);
        }
      }

      const nowTimestamp = serverTimestamp();

      await setDoc(doc(db, 'tasks', taskId), {
        id: taskId,
        title: taskForm.title.trim(),
        description: taskForm.description.trim(),
        dueDate: dueDateValue,
        dueDateString: taskForm.dueDate || '',
        priority: taskForm.priority,
        assignedToEmail: taskForm.assignedToEmail,
        assignedToName: taskForm.assignedToName || taskForm.assignedToEmail,
        assignedByEmail: adminEmail,
        assignedBy: adminEmail,
        status: 'Pending',
        createdDate: nowTimestamp,
        createdAt: nowTimestamp,
      });

      // Send notification
      const notifId = `NOTIF-${Date.now()}`;
      await setDoc(doc(db, 'notifications', notifId), {
        id: notifId,
        title: `📋 New Task Assigned: ${taskForm.title}`,
        message: taskForm.description.trim() || 'You have been assigned a new task by management.',
        requestId: taskId,
        timestamp: nowTimestamp,
        isRead: false,
        recipientEmail: taskForm.assignedToEmail,
      });

      // Audit log
      const auditId = `AUD-${Date.now()}`;
      await setDoc(doc(db, 'audit_logs', auditId), {
        id: auditId,
        action: 'TASK_ASSIGNED',
        performedBy: adminEmail,
        targetEmail: taskForm.assignedToEmail,
        details: `Task: ${taskForm.title} (${taskId})`,
        timestamp: nowTimestamp,
      });

      addToast(`✓ Task delegated to ${taskForm.assignedToName}!`, 'success');
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

  const handleUpdateStatus = async (taskId, newStatus) => {
    try {
      await updateDoc(doc(db, 'tasks', taskId), {
        status: newStatus,
        completedAt: newStatus === 'Completed' ? serverTimestamp() : null,
      });
      addToast(`Task status updated to ${newStatus}`, 'success');
    } catch (err) {
      addToast(`Failed to update task status: ${err.message}`, 'error');
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

  // Render a single Kanban Task Card
  const renderKanbanCard = (t) => {
    const isDone = t.status === 'Completed';
    const isInProgress = t.status === 'In Progress';
    const isPending = !t.status || t.status === 'Pending';

    return (
      <div
        key={t.id}
        className={`bg-white/90 backdrop-blur-md rounded-2xl p-4 border shadow-soft transition-all duration-200 hover-lift space-y-3.5 ${
          isDone
            ? 'border-emerald-200/90 bg-emerald-50/20'
            : isInProgress
            ? 'border-blue-200/90 bg-blue-50/20 shadow-glow-blue/10'
            : 'border-slate-200/90'
        }`}
      >
        {/* Card Header: Priority & Delete */}
        <div className="flex items-center justify-between gap-2">
          <span
            className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider ${
              t.priority === 'High'
                ? 'bg-rose-50 text-rose-700 border border-rose-200'
                : t.priority === 'Low'
                ? 'bg-slate-100 text-slate-700 border border-slate-200'
                : 'bg-amber-50 text-amber-700 border border-amber-200'
            }`}
          >
            {t.priority || 'Medium'}
          </span>

          <button
            onClick={() => handleDeleteTask(t.id)}
            className="p-1 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
            title="Delete Task"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Title & Description */}
        <div>
          <h4 className={`text-xs sm:text-sm font-bold text-slate-900 leading-snug ${isDone ? 'line-through opacity-70' : ''}`}>
            {t.title}
          </h4>
          {t.description && (
            <p className="text-xs text-slate-500 mt-1 leading-relaxed font-medium">
              {t.description}
            </p>
          )}
        </div>

        {/* Assignee & Due Date */}
        <div className="pt-2 border-t border-slate-100/80 flex items-center justify-between text-xs text-slate-500 font-medium">
          <div className="flex items-center gap-1.5 min-w-0">
            <div className="h-6 w-6 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-extrabold flex items-center justify-center text-[10px] shrink-0">
              {(t.assignedToName || 'E').charAt(0).toUpperCase()}
            </div>
            <span className="font-bold text-slate-800 text-[11px]">
              {t.assignedToName || t.assignedToEmail}
            </span>
          </div>

          {t.dueDate && (
            <div className="flex items-center gap-1 text-[10px] font-mono font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md shrink-0">
              <Calendar className="w-3 h-3 text-slate-400" />
              <span>{formatDate(t.dueDate, 'dd MMM')}</span>
            </div>
          )}
        </div>

        {/* Quick Shift Status Controls */}
        <div className="flex items-center justify-between gap-1.5 pt-1">
          {isPending && (
            <button
              onClick={() => handleUpdateStatus(t.id, 'In Progress')}
              className="w-full py-1.5 px-3 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200/80 rounded-xl text-[11px] font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer shadow-xs"
            >
              <span>Move to In Progress</span>
              <ArrowRight className="w-3 h-3" />
            </button>
          )}

          {isInProgress && (
            <>
              <button
                onClick={() => handleUpdateStatus(t.id, 'Pending')}
                className="py-1.5 px-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-[11px] font-bold transition-colors flex items-center justify-center gap-1 cursor-pointer"
                title="Back to Pending"
              >
                <ArrowLeft className="w-3 h-3" />
              </button>
              <button
                onClick={() => handleUpdateStatus(t.id, 'Completed')}
                className="flex-1 py-1.5 px-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-[11px] font-bold transition-all flex items-center justify-center gap-1 cursor-pointer shadow-xs"
              >
                <span>Mark Done</span>
                <CheckCircle2 className="w-3 h-3" />
              </button>
            </>
          )}

          {isDone && (
            <button
              onClick={() => handleUpdateStatus(t.id, 'In Progress')}
              className="w-full py-1.5 px-3 bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 rounded-xl text-[11px] font-bold transition-colors flex items-center justify-center gap-1.5 cursor-pointer"
            >
              <RotateCcw className="w-3 h-3 text-slate-500" />
              <span>Reopen to In Progress</span>
            </button>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header Banner & Stats */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-bold shadow-xs">
                <CheckSquare className="w-4 h-4" />
              </div>
              <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
                Staff Task Delegation & Kanban Board
              </h3>
            </div>
            <p className="text-xs text-slate-500 mt-1 font-medium">
              Delegate deliverables, monitor real-time staff progress, and manage workflows visually.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {/* View Mode Toggle Switcher */}
            <div className="p-1 rounded-2xl bg-slate-100 border border-slate-200/80 flex items-center gap-1 shrink-0">
              <button
                onClick={() => setViewMode('kanban')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all cursor-pointer ${
                  viewMode === 'kanban'
                    ? 'bg-white text-blue-700 shadow-xs'
                    : 'text-slate-500 hover:text-slate-900'
                }`}
              >
                <Kanban className="w-3.5 h-3.5" />
                <span>Kanban</span>
              </button>
              <button
                onClick={() => setViewMode('grid')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all cursor-pointer ${
                  viewMode === 'grid'
                    ? 'bg-white text-blue-700 shadow-xs'
                    : 'text-slate-500 hover:text-slate-900'
                }`}
              >
                <LayoutGrid className="w-3.5 h-3.5" />
                <span>Grid</span>
              </button>
            </div>

            <button
              onClick={() => setIsModalOpen(true)}
              className="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white rounded-2xl text-xs font-bold transition-all shadow-md shadow-blue-500/20 shrink-0 cursor-pointer hover-lift"
            >
              <Plus className="w-4 h-4" />
              <span>+ Assign Task</span>
            </button>
          </div>
        </div>

        {/* Task Metrics Bar */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-4 border-t border-slate-100">
          <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
            <p className="text-[11px] font-extrabold text-slate-500 uppercase tracking-wider">Total Tasks</p>
            <p className="text-xl font-extrabold text-slate-900 mt-0.5">{totalTasks}</p>
          </div>
          <div className="p-3.5 rounded-2xl bg-amber-50/80 border border-amber-100">
            <p className="text-[11px] font-extrabold text-amber-700 uppercase tracking-wider">Pending</p>
            <p className="text-xl font-extrabold text-amber-800 mt-0.5">{pendingCount}</p>
          </div>
          <div className="p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100">
            <p className="text-[11px] font-extrabold text-blue-700 uppercase tracking-wider">In Progress</p>
            <p className="text-xl font-extrabold text-blue-800 mt-0.5">{inProgressCount}</p>
          </div>
          <div className="p-3.5 rounded-2xl bg-emerald-50/80 border border-emerald-100">
            <p className="text-[11px] font-extrabold text-emerald-700 uppercase tracking-wider">Completed</p>
            <p className="text-xl font-extrabold text-emerald-800 mt-0.5">{completedCount}</p>
          </div>
        </div>
      </div>

      {/* Search & Filter Controls */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
        <div className="relative sm:col-span-2">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by task title, description, or employee name..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          />
        </div>

        <div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            <option value="All">All Task Statuses</option>
            <option value="Pending">Pending</option>
            <option value="In Progress">In Progress</option>
            <option value="Completed">Completed</option>
          </select>
        </div>

        <div>
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-2xl text-xs font-semibold text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            <option value="All">All Priorities</option>
            <option value="High">High Priority</option>
            <option value="Medium">Medium Priority</option>
            <option value="Low">Low Priority</option>
          </select>
        </div>
      </div>

      {/* VIEW MODE 1: KANBAN BOARD */}
      {viewMode === 'kanban' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {/* Column 1: Pending / To Do */}
          <div className="bg-slate-100/70 rounded-3xl p-4 border border-slate-200/80 flex flex-col space-y-3 min-h-[500px]">
            <div className="flex items-center justify-between pb-2 border-b border-slate-200/80 px-1">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-amber-500" />
                <h4 className="text-xs font-extrabold text-slate-800 uppercase tracking-wider">
                  Pending / To Do
                </h4>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 text-[11px] font-extrabold">
                {pendingTasksList.length}
              </span>
            </div>

            <div className="flex-1 space-y-3 overflow-y-auto max-h-[700px] pr-0.5">
              {pendingTasksList.length === 0 ? (
                <div className="h-40 border border-dashed border-slate-300 rounded-2xl flex flex-col items-center justify-center text-center p-4">
                  <Clock className="w-6 h-6 text-slate-400 mb-1" />
                  <p className="text-xs font-bold text-slate-500">No pending tasks</p>
                </div>
              ) : (
                pendingTasksList.map(renderKanbanCard)
              )}
            </div>
          </div>

          {/* Column 2: In Progress */}
          <div className="bg-blue-50/40 rounded-3xl p-4 border border-blue-200/60 flex flex-col space-y-3 min-h-[500px]">
            <div className="flex items-center justify-between pb-2 border-b border-blue-200/70 px-1">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-blue-600 animate-pulse" />
                <h4 className="text-xs font-extrabold text-blue-900 uppercase tracking-wider">
                  In Progress
                </h4>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-blue-100 text-blue-800 text-[11px] font-extrabold">
                {inProgressTasksList.length}
              </span>
            </div>

            <div className="flex-1 space-y-3 overflow-y-auto max-h-[700px] pr-0.5">
              {inProgressTasksList.length === 0 ? (
                <div className="h-40 border border-dashed border-blue-200 rounded-2xl flex flex-col items-center justify-center text-center p-4">
                  <Play className="w-6 h-6 text-blue-400 mb-1" />
                  <p className="text-xs font-bold text-blue-600">No tasks in progress</p>
                </div>
              ) : (
                inProgressTasksList.map(renderKanbanCard)
              )}
            </div>
          </div>

          {/* Column 3: Completed */}
          <div className="bg-emerald-50/40 rounded-3xl p-4 border border-emerald-200/60 flex flex-col space-y-3 min-h-[500px]">
            <div className="flex items-center justify-between pb-2 border-b border-emerald-200/70 px-1">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-emerald-500" />
                <h4 className="text-xs font-extrabold text-emerald-900 uppercase tracking-wider">
                  Completed
                </h4>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[11px] font-extrabold">
                {completedTasksList.length}
              </span>
            </div>

            <div className="flex-1 space-y-3 overflow-y-auto max-h-[700px] pr-0.5">
              {completedTasksList.length === 0 ? (
                <div className="h-40 border border-dashed border-emerald-200 rounded-2xl flex flex-col items-center justify-center text-center p-4">
                  <CheckCircle2 className="w-6 h-6 text-emerald-400 mb-1" />
                  <p className="text-xs font-bold text-emerald-700">No completed tasks yet</p>
                </div>
              ) : (
                completedTasksList.map(renderKanbanCard)
              )}
            </div>
          </div>
        </div>
      )}

      {/* VIEW MODE 2: GRID VIEW */}
      {viewMode === 'grid' && (
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
              const isInProgress = t.status === 'In Progress';

              return (
                <div
                  key={t.id}
                  className={`bg-white rounded-3xl p-5 border shadow-soft transition-all duration-200 flex flex-col justify-between hover-lift ${
                    isDone
                      ? 'border-emerald-200/80 bg-emerald-50/20'
                      : isInProgress
                      ? 'border-blue-200/80 bg-blue-50/20'
                      : 'border-slate-200/80'
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
                      <p className="text-xs text-slate-600 mt-1.5 line-clamp-3 leading-relaxed font-medium">
                        {t.description}
                      </p>
                    )}
                  </div>

                  <div className="mt-5 pt-4 border-t border-slate-100 space-y-3">
                    <div className="flex items-center justify-between text-xs text-slate-500 font-medium">
                      <div className="flex items-center gap-2">
                        <div className="h-6 w-6 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-extrabold flex items-center justify-center text-[10px] shrink-0">
                          {(t.assignedToName || 'E').charAt(0).toUpperCase()}
                        </div>
                        <span className="font-bold text-slate-800">
                          {t.assignedToName || t.assignedToEmail}
                        </span>
                      </div>

                      {t.dueDate && (
                        <div className="flex items-center gap-1 text-[11px] font-mono font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">
                          <Calendar className="w-3 h-3 text-slate-400" />
                          <span>{formatDate(t.dueDate, 'dd MMM yyyy')}</span>
                        </div>
                      )}
                    </div>

                    {/* Status Action Buttons */}
                    <div className="flex items-center justify-between gap-2 pt-1">
                      {!isDone ? (
                        <div className="flex items-center gap-1.5 flex-1">
                          {!isInProgress && (
                            <button
                              onClick={() => handleUpdateStatus(t.id, 'In Progress')}
                              className="flex-1 py-1.5 px-2 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded-xl text-[11px] font-bold transition-colors flex items-center justify-center gap-1 cursor-pointer"
                            >
                              <Play className="w-3 h-3" />
                              <span>In Progress</span>
                            </button>
                          )}
                          <button
                            onClick={() => handleUpdateStatus(t.id, 'Completed')}
                            className="flex-1 py-1.5 px-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-[11px] font-bold transition-colors flex items-center justify-center gap-1 cursor-pointer shadow-xs"
                          >
                            <CheckCircle2 className="w-3 h-3" />
                            <span>Mark Done</span>
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => handleUpdateStatus(t.id, 'Pending')}
                          className="flex-1 py-1.5 px-2 bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 rounded-xl text-[11px] font-bold transition-colors flex items-center justify-center gap-1 cursor-pointer"
                        >
                          <RotateCcw className="w-3 h-3" />
                          <span>Reopen Task</span>
                        </button>
                      )}

                      <button
                        onClick={() => handleDeleteTask(t.id)}
                        className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors cursor-pointer"
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
      )}

      {/* Assign Task Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Delegate New Task to Employee"
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
              placeholder="e.g. Prepare Monthly Financial Audit & Attendance Report"
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
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
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
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
              placeholder="Provide clear instructions, deliverables, or target outcomes..."
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
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
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
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
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-center focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white"
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
              className="px-5 py-2 text-xs font-bold text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 rounded-xl shadow-md shadow-blue-500/20 disabled:opacity-60 cursor-pointer"
            >
              {isSubmitting ? 'Delegating Task...' : 'Delegate & Assign Task'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
