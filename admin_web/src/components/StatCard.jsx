import React from 'react';

export const StatCard = ({ title, value, icon: Icon, color = 'blue', change, subtitle, onClick, isActive = false }) => {
  const colorMap = {
    blue: {
      bg: 'bg-neo-cyan',
      icon: 'text-neo-border bg-white',
    },
    emerald: {
      bg: 'bg-neo-green',
      icon: 'text-neo-border bg-white',
    },
    amber: {
      bg: 'bg-neo-yellow',
      icon: 'text-neo-border bg-white',
    },
    rose: {
      bg: 'bg-neo-pink',
      icon: 'text-neo-border bg-white',
    },
    indigo: {
      bg: 'bg-neo-purple',
      icon: 'text-neo-border bg-white',
    },
    slate: {
      bg: 'bg-neo-yellow',
      icon: 'text-neo-border bg-white',
    },
  };

  const scheme = colorMap[color] || colorMap.blue;

  return (
    <div
      onClick={onClick}
      className={`relative bg-white rounded-2xl p-5 border-2.5 border-neo-border shadow-brutal transition-all duration-150 ${
        onClick ? 'cursor-pointer hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-brutal-lg' : ''
      } ${isActive ? 'ring-3 ring-neo-border bg-neo-yellow/20' : ''}`}
    >
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-[11px] font-black uppercase tracking-wider text-neo-border opacity-70 font-display">{title}</p>
          <h4 className="text-2xl sm:text-3xl font-black text-neo-border mt-1 tracking-tight font-display">{value}</h4>
          {subtitle && (
            <p className="text-xs text-neo-border font-bold mt-1 opacity-80">{subtitle}</p>
          )}
          {change && (
            <div className="flex items-center gap-1 mt-1 text-xs font-black text-emerald-700">
              <span>{change}</span>
            </div>
          )}
        </div>
        {Icon && (
          <div className={`p-3.5 rounded-xl ${scheme.bg} ${scheme.icon} shrink-0 border-2 border-neo-border shadow-brutal-sm`}>
            <Icon className="w-6 h-6 stroke-[2.5]" />
          </div>
        )}
      </div>
    </div>
  );
};
