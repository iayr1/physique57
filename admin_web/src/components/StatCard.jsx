import React from 'react';

export const StatCard = ({ title, value, icon: Icon, color = 'blue', change, subtitle, onClick, isActive = false }) => {
  const colorMap = {
    blue: {
      bg: 'bg-blue-50',
      border: 'border-blue-100 hover:border-blue-300',
      icon: 'text-blue-600 bg-blue-100/70',
      accent: 'from-blue-600 to-indigo-600',
      activeRing: 'ring-2 ring-blue-500 bg-blue-50/60',
    },
    emerald: {
      bg: 'bg-emerald-50',
      border: 'border-emerald-100 hover:border-emerald-300',
      icon: 'text-emerald-600 bg-emerald-100/70',
      accent: 'from-emerald-600 to-teal-600',
      activeRing: 'ring-2 ring-emerald-500 bg-emerald-50/60',
    },
    amber: {
      bg: 'bg-amber-50',
      border: 'border-amber-100 hover:border-amber-300',
      icon: 'text-amber-600 bg-amber-100/70',
      accent: 'from-amber-500 to-orange-600',
      activeRing: 'ring-2 ring-amber-500 bg-amber-50/60',
    },
    rose: {
      bg: 'bg-rose-50',
      border: 'border-rose-100 hover:border-rose-300',
      icon: 'text-rose-600 bg-rose-100/70',
      accent: 'from-rose-500 to-pink-600',
      activeRing: 'ring-2 ring-rose-500 bg-rose-50/60',
    },
    indigo: {
      bg: 'bg-indigo-50',
      border: 'border-indigo-100 hover:border-indigo-300',
      icon: 'text-indigo-600 bg-indigo-100/70',
      accent: 'from-indigo-600 to-violet-600',
      activeRing: 'ring-2 ring-indigo-500 bg-indigo-50/60',
    },
    slate: {
      bg: 'bg-slate-50',
      border: 'border-slate-200 hover:border-slate-300',
      icon: 'text-slate-700 bg-slate-200/70',
      accent: 'from-slate-700 to-slate-900',
      activeRing: 'ring-2 ring-slate-600 bg-slate-50/80',
    },
  };

  const scheme = colorMap[color] || colorMap.blue;

  return (
    <div
      onClick={onClick}
      className={`relative bg-white rounded-2xl p-5 border shadow-soft transition-all duration-200 ${
        onClick ? 'cursor-pointer hover:shadow-soft-lg hover:-translate-y-0.5' : ''
      } ${isActive ? scheme.activeRing : scheme.border}`}
    >
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">{title}</p>
          <h4 className="text-2xl sm:text-3xl font-extrabold text-slate-900 mt-1">{value}</h4>
          {subtitle && (
            <p className="text-xs text-slate-500 mt-1 font-medium">{subtitle}</p>
          )}
          {change && (
            <div className="flex items-center gap-1 mt-1 text-xs font-semibold text-emerald-600">
              <span>{change}</span>
            </div>
          )}
        </div>
        {Icon && (
          <div className={`p-3.5 rounded-xl ${scheme.icon} shrink-0`}>
            <Icon className="w-6 h-6" />
          </div>
        )}
      </div>
    </div>
  );
};
