import React from 'react';

export const Badge = ({ children, variant = 'default', size = 'md', className = '' }) => {
  const normalized = String(children || variant).toLowerCase();

  const getVariantStyles = () => {
    if (normalized.includes('approve') || normalized === 'present' || normalized === 'active' || normalized === 'completed') {
      return 'bg-neo-green text-neo-border border-2 border-neo-border shadow-brutal-sm';
    }
    if (normalized === 'in progress') {
      return 'bg-neo-cyan text-neo-border border-2 border-neo-border shadow-brutal-sm';
    }
    if (normalized.includes('pend') || normalized === 'half day') {
      return 'bg-neo-yellow text-neo-border border-2 border-neo-border shadow-brutal-sm';
    }
    if (normalized.includes('reject') || normalized === 'deactivated' || normalized === 'absent' || normalized === 'not checked in' || normalized.includes('urgent')) {
      return 'bg-neo-pink text-neo-border border-2 border-neo-border shadow-brutal-sm';
    }
    if (normalized === 'late' || normalized.includes('important')) {
      return 'bg-neo-orange text-neo-border border-2 border-neo-border shadow-brutal-sm';
    }
    if (normalized === 'admin' || normalized === 'super administrator' || normalized === 'executive') {
      return 'bg-neo-purple text-neo-border border-2 border-neo-border shadow-brutal-sm';
    }
    return 'bg-[#E2E8F0] text-neo-border border-2 border-neo-border shadow-brutal-sm';
  };

  const sizeStyles = {
    sm: 'px-2 py-0.5 text-[11px] font-black',
    md: 'px-2.5 py-1 text-xs font-black',
    lg: 'px-3.5 py-1.5 text-sm font-black',
  };

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-lg ${getVariantStyles()} ${sizeStyles[size]} ${className}`}
    >
      <span className="h-2 w-2 rounded-full bg-neo-border" />
      {children}
    </span>
  );
};
