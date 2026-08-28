import React from 'react';

export const Badge = ({ children, variant = 'default', size = 'md', className = '' }) => {
  const normalized = String(children || variant).toLowerCase();

  const getVariantStyles = () => {
    if (normalized.includes('approve') || normalized === 'present' || normalized === 'active' || normalized === 'completed') {
      return 'bg-emerald-50 text-emerald-700 border-emerald-200/80 ring-emerald-600/10';
    }
    if (normalized.includes('pend') || normalized === 'in progress' || normalized === 'half day') {
      return 'bg-amber-50 text-amber-700 border-amber-200/80 ring-amber-600/10';
    }
    if (normalized.includes('reject') || normalized === 'deactivated' || normalized === 'absent' || normalized === 'not checked in' || normalized.includes('urgent')) {
      return 'bg-rose-50 text-rose-700 border-rose-200/80 ring-rose-600/10';
    }
    if (normalized === 'late' || normalized.includes('important')) {
      return 'bg-orange-50 text-orange-700 border-orange-200/80 ring-orange-600/10';
    }
    if (normalized === 'admin' || normalized === 'super administrator' || normalized === 'executive') {
      return 'bg-indigo-50 text-indigo-700 border-indigo-200/80 ring-indigo-600/10';
    }
    return 'bg-slate-100 text-slate-700 border-slate-200 ring-slate-600/10';
  };

  const sizeStyles = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-xs font-medium',
    lg: 'px-3 py-1.5 text-sm font-semibold',
  };

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border ring-1 ring-inset ${getVariantStyles()} ${sizeStyles[size]} ${className}`}
    >
      <span className="h-1.5 w-1.5 rounded-full bg-current opacity-80" />
      {children}
    </span>
  );
};
