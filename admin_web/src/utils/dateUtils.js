import { format, parseISO, isValid } from 'date-fns';

export const formatDate = (dateOrTimestamp, formatStr = 'dd MMM yyyy') => {
  if (!dateOrTimestamp) return '—';
  try {
    if (dateOrTimestamp.toDate && typeof dateOrTimestamp.toDate === 'function') {
      return format(dateOrTimestamp.toDate(), formatStr);
    }
    if (dateOrTimestamp instanceof Date) {
      return format(dateOrTimestamp, formatStr);
    }
    if (typeof dateOrTimestamp === 'string') {
      const parsed = parseISO(dateOrTimestamp);
      if (isValid(parsed)) return format(parsed, formatStr);
      return dateOrTimestamp;
    }
    if (typeof dateOrTimestamp === 'number') {
      return format(new Date(dateOrTimestamp), formatStr);
    }
  } catch {
    return '—';
  }
  return '—';
};

export const formatTime = (dateOrTimestamp) => {
  if (!dateOrTimestamp) return '—';
  return formatDate(dateOrTimestamp, 'hh:mm a');
};

export const getTodayDateString = () => {
  return format(new Date(), 'yyyy-MM-dd');
};
