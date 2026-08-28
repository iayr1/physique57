import React, { useState } from 'react';
import {
  ShieldCheck,
  Search,
  History,
  UserCheck,
  FileCheck2,
  CheckSquare,
  Megaphone,
  AlertCircle
} from 'lucide-react';
import { formatDate } from '../utils/dateUtils';

export const AuditLogsView = ({ auditLogs = [] }) => {
  const [searchQuery, setSearchQuery] = useState('');

  const filteredLogs = auditLogs.filter((log) => {
    const q = searchQuery.toLowerCase().trim();
    const action = (log.action || '').toLowerCase();
    const by = (log.performedBy || '').toLowerCase();
    const target = (log.targetEmail || '').toLowerCase();
    const details = (log.details || '').toLowerCase();

    return !q || action.includes(q) || by.includes(q) || target.includes(q) || details.includes(q);
  });

  const getActionBadge = (action = '') => {
    if (action.includes('APPROVE')) {
      return 'bg-emerald-50 text-emerald-700 border-emerald-200';
    }
    if (action.includes('REJECT') || action.includes('DELETE')) {
      return 'bg-rose-50 text-rose-700 border-rose-200';
    }
    if (action.includes('ONBOARD') || action.includes('STATUS')) {
      return 'bg-blue-50 text-blue-700 border-blue-200';
    }
    if (action.includes('TASK')) {
      return 'bg-indigo-50 text-indigo-700 border-indigo-200';
    }
    if (action.includes('ANNOUNCEMENT')) {
      return 'bg-amber-50 text-amber-700 border-amber-200';
    }
    return 'bg-slate-100 text-slate-700 border-slate-200';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-soft flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-xl font-extrabold text-slate-900 tracking-tight">
            System Compliance & Security Audit Trail
          </h3>
          <p className="text-xs text-slate-500 mt-0.5 font-medium">
            Immutable chronological logging of administrative operations, leave deductions, status toggles, and broadcast dispatches.
          </p>
        </div>

        <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-100 border border-slate-200 text-xs font-bold text-slate-700">
          <ShieldCheck className="w-4 h-4 text-emerald-600" />
          <span>SOC-2 Compliant Trail</span>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search audit trail by operation type, administrator email, or employee email..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-blue-500 shadow-soft"
        />
      </div>

      {/* Logs Table / List */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/70 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                <th className="py-4 px-6">Timestamp</th>
                <th className="py-4 px-6">Action / Event</th>
                <th className="py-4 px-6">Performed By</th>
                <th className="py-4 px-6">Target Subject</th>
                <th className="py-4 px-6">Details / Operational Payload</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs font-medium">
              {filteredLogs.length === 0 ? (
                <tr>
                  <td colSpan="5" className="py-12 text-center text-slate-400">
                    No compliance audit logs recorded matching your search.
                  </td>
                </tr>
              ) : (
                filteredLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/60 transition-colors">
                    {/* Timestamp */}
                    <td className="py-4 px-6 font-mono text-slate-500 text-[11px] whitespace-nowrap">
                      {formatDate(log.timestamp, 'dd MMM yyyy, hh:mm:ss a')}
                    </td>

                    {/* Action */}
                    <td className="py-4 px-6">
                      <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase tracking-wider border ${getActionBadge(log.action)}`}>
                        {log.action || 'SYSTEM_EVENT'}
                      </span>
                    </td>

                    {/* Performed By */}
                    <td className="py-4 px-6 font-bold text-slate-800 font-mono text-[11px]">
                      {log.performedBy || 'admin@gmail.com'}
                    </td>

                    {/* Target */}
                    <td className="py-4 px-6 font-mono text-slate-600 text-[11px]">
                      {log.targetEmail || 'System Wide'}
                    </td>

                    {/* Details */}
                    <td className="py-4 px-6 text-slate-700 max-w-xs truncate">
                      {log.details || 'Operational record logged.'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
