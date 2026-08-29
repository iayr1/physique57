import React, { useState } from 'react';
import {
  FileCheck2,
  Search,
  Filter,
  CheckCircle2,
  XCircle,
  Clock,
  Calendar,
  DollarSign,
  Laptop,
  Plane,
  HeartHandshake,
  Paperclip,
  AlertCircle,
  FileText,
  User
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { formatDate } from '../utils/dateUtils';

export const RequestsView = ({
  requests = [],
  onApproveRequest,
  onOpenRejectModal
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('Pending');
  const [selectedRequest, setSelectedRequest] = useState(null);

  const categories = [
    'All',
    'leave',
    'expense',
    'it_support',
    'attendance_correction',
    'wfh',
    'hr_request',
    'travel',
    'generic',
  ];

  const getCategoryLabel = (cat) => {
    switch (cat) {
      case 'leave':
        return 'Leave Request';
      case 'expense':
        return 'Expense Claim';
      case 'it_support':
        return 'IT & Tech Support';
      case 'attendance_correction':
        return 'Attendance Correction';
      case 'wfh':
        return 'Work From Home';
      case 'hr_request':
        return 'HR Grievance / Query';
      case 'travel':
        return 'Business Travel';
      case 'generic':
        return 'General Ticket';
      default:
        return cat || 'Request';
    }
  };

  const getCategoryIcon = (cat) => {
    switch (cat) {
      case 'leave':
      case 'wfh':
        return Calendar;
      case 'expense':
        return DollarSign;
      case 'it_support':
        return Laptop;
      case 'travel':
        return Plane;
      case 'hr_request':
        return HeartHandshake;
      default:
        return FileText;
    }
  };

  // Filter logic
  const filteredRequests = requests.filter((req) => {
    const q = searchQuery.toLowerCase().trim();
    const name = (req.employeeName || '').toLowerCase();
    const email = (req.employeeEmail || '').toLowerCase();
    const type = (req.requestType || '').toLowerCase();
    const id = (req.id || '').toLowerCase();

    const matchesQuery = !q || name.includes(q) || email.includes(q) || type.includes(q) || id.includes(q);
    const matchesCat = categoryFilter === 'All' || req.requestType === categoryFilter;

    const status = (req.status || '').toLowerCase();
    let matchesStatus = true;
    if (statusFilter === 'Pending') {
      matchesStatus = status.includes('pending');
    } else if (statusFilter === 'Approved') {
      matchesStatus = status.includes('approved');
    } else if (statusFilter === 'Rejected') {
      matchesStatus = status.includes('rejected');
    }

    return matchesQuery && matchesCat && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
            Employee Requests & Approvals Center
          </h3>
          <p className="text-xs text-slate-500 mt-0.5 font-medium">
            Review leave requests, expense reimbursements, IT tickets, and attendance corrections in real-time.
          </p>
        </div>

        {/* Status Filter Buttons */}
        <div className="inline-flex p-1 bg-slate-100/90 rounded-2xl border border-slate-200/80 self-start sm:self-auto">
          {['Pending', 'Approved', 'Rejected', 'All'].map((s) => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                statusFilter === s
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {/* Search & Category Filter Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {/* Search */}
        <div className="relative sm:col-span-2">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by employee name, email, request ID, or category..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          />
        </div>

        {/* Category Dropdown */}
        <div>
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
          >
            {categories.map((c) => (
              <option key={c} value={c}>
                Category: {getCategoryLabel(c)}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Request Cards Grid / List */}
      <div className="space-y-3">
        {filteredRequests.length === 0 ? (
          <div className="bg-white rounded-3xl p-12 text-center border border-slate-200/80 shadow-soft">
            <FileCheck2 className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-sm font-bold text-slate-800">No requests found</p>
            <p className="text-xs text-slate-400 mt-1">
              There are no submissions matching your search and filter criteria.
            </p>
          </div>
        ) : (
          filteredRequests.map((req) => {
            const reqData = req.requestData || {};
            const Icon = getCategoryIcon(req.requestType);
            const isPending = (req.status || '').toLowerCase().includes('pending');
            const leaveType = reqData.leaveType || reqData.category || getCategoryLabel(req.requestType);
            const days = reqData.numberOfDays || 1;

            return (
              <div
                key={req.id}
                className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-soft hover:shadow-soft-lg transition-all flex flex-col lg:flex-row lg:items-center justify-between gap-4"
              >
                {/* Request Overview */}
                <div className="flex items-start gap-4 min-w-0">
                  <div className="p-3 rounded-2xl bg-blue-50 text-blue-600 border border-blue-100 shrink-0">
                    <Icon className="w-6 h-6" />
                  </div>
                  <div className="min-w-0 space-y-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-sm font-extrabold text-slate-900">
                        {req.employeeName || 'Staff Member'}
                      </span>
                      <span className="text-xs text-slate-400">•</span>
                      <span className="text-xs font-semibold text-slate-500 font-mono">
                        {req.employeeEmail}
                      </span>
                      <Badge size="sm">{req.status}</Badge>
                    </div>

                    <div className="flex flex-wrap items-center gap-3 text-xs font-semibold text-blue-600">
                      <span>{leaveType}</span>
                      {req.requestType === 'leave' && (
                        <span className="text-slate-600 bg-slate-100 px-2 py-0.5 rounded-md font-mono text-[11px]">
                          {days} Day{days > 1 ? 's' : ''} ({formatDate(reqData.startDate, 'dd MMM')} - {formatDate(reqData.endDate, 'dd MMM')})
                        </span>
                      )}
                      {req.requestType === 'expense' && reqData.amount && (
                        <span className="text-emerald-700 bg-emerald-50 border border-emerald-100 px-2 py-0.5 rounded-md font-bold font-mono text-[11px]">
                          Claim: ₹{reqData.amount}
                        </span>
                      )}
                      <span className="text-slate-400 font-normal">
                        Submitted: {formatDate(req.submittedAt || req.createdAt, 'dd MMM yyyy, hh:mm a')}
                      </span>
                    </div>

                    <p className="text-xs text-slate-600 mt-1">
                      <strong>Details:</strong>{' '}
                      {reqData.reason ||
                        reqData.description ||
                        reqData.issueDescription ||
                        reqData.purpose ||
                        'Standard organizational request submission.'}
                    </p>

                    {/* Rejection comment if rejected */}
                    {req.rejectionReason && (
                      <p className="text-xs text-rose-700 font-semibold mt-1 bg-rose-50 p-2 rounded-xl border border-rose-100">
                        Rejection Reason: {req.rejectionReason}
                      </p>
                    )}
                  </div>
                </div>

                {/* Right: Actions */}
                <div className="flex items-center gap-2.5 shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-slate-100">
                  <button
                    onClick={() => setSelectedRequest(req)}
                    className="px-3.5 py-2 rounded-xl text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-colors"
                  >
                    View Details
                  </button>

                  {isPending && (
                    <>
                      <button
                        onClick={() => onApproveRequest(req)}
                        className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-all shadow-xs flex items-center gap-1.5 cursor-pointer"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        <span>Approve & Deduct</span>
                      </button>
                      <button
                        onClick={() => onOpenRejectModal(req)}
                        className="px-4 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        <span>Reject</span>
                      </button>
                    </>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* View Request Details Modal */}
      <Modal
        isOpen={!!selectedRequest}
        onClose={() => setSelectedRequest(null)}
        title={`Request Details: ${selectedRequest?.id || ''}`}
        maxWidth="max-w-2xl"
      >
        {selectedRequest && (
          <div className="space-y-4 text-xs">
            {/* Header info */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between">
              <div>
                <p className="font-bold text-sm text-slate-900">{selectedRequest.employeeName}</p>
                <p className="text-slate-500 font-mono">{selectedRequest.employeeEmail}</p>
                <p className="text-slate-500">{selectedRequest.department || 'General Department'}</p>
              </div>
              <div className="text-right">
                <Badge size="lg">{selectedRequest.status}</Badge>
                <p className="text-slate-400 mt-1 font-mono text-[11px]">
                  {formatDate(selectedRequest.submittedAt || selectedRequest.createdAt, 'dd MMM yyyy')}
                </p>
              </div>
            </div>

            {/* Structured payload */}
            <div className="p-4 rounded-2xl bg-white border border-slate-200 space-y-2">
              <h4 className="font-bold text-slate-900 uppercase tracking-wider text-[11px] mb-2">
                Payload Attributes
              </h4>
              {Object.entries(selectedRequest.requestData || {}).map(([key, val]) => (
                <div key={key} className="flex justify-between border-b border-slate-100 pb-1">
                  <span className="font-semibold text-slate-500 capitalize">
                    {key.replace(/([A-Z])/g, ' $1')}:
                  </span>
                  <span className="font-mono text-slate-900 font-bold text-right">
                    {typeof val === 'object' && val !== null
                      ? JSON.stringify(val)
                      : String(val || '—')}
                  </span>
                </div>
              ))}
            </div>

            {/* Approval History Trail */}
            {selectedRequest.approvalHistory && selectedRequest.approvalHistory.length > 0 && (
              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                <h4 className="font-bold text-slate-900 uppercase tracking-wider text-[11px] mb-2">
                  Approval Timeline Trail
                </h4>
                <div className="space-y-2">
                  {selectedRequest.approvalHistory.map((step, idx) => (
                    <div key={idx} className="flex items-center justify-between text-[11px]">
                      <div className="flex items-center gap-2">
                        <span className="h-2 w-2 rounded-full bg-blue-600" />
                        <span className="font-bold text-slate-800">{step.step || step.status}</span>
                        <span className="text-slate-500">by {step.approver || 'Admin'}</span>
                      </div>
                      <span className="text-slate-400 font-mono">
                        {formatDate(step.timestamp, 'dd MMM, hh:mm a')}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Action Buttons in Modal */}
            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
              <button
                onClick={() => setSelectedRequest(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl font-bold"
              >
                Close
              </button>
              {(selectedRequest.status || '').toLowerCase().includes('pending') && (
                <>
                  <button
                    onClick={() => {
                      onApproveRequest(selectedRequest);
                      setSelectedRequest(null);
                    }}
                    className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold shadow-xs"
                  >
                    Approve Request
                  </button>
                  <button
                    onClick={() => {
                      onOpenRejectModal(selectedRequest);
                      setSelectedRequest(null);
                    }}
                    className="px-4 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl font-bold"
                  >
                    Reject Request
                  </button>
                </>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
