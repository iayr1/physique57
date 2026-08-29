import { format, parseISO, isValid } from 'date-fns';

export const formatDate = (dateOrTimestamp, formatStr = 'dd MMM yyyy') => {
  if (!dateOrTimestamp) return '—';
  try {
    if (dateOrTimestamp.toDate && typeof dateOrTimestamp.toDate === 'function') {
      return format(dateOrTimestamp.toDate(), formatStr);
    }
    if (typeof dateOrTimestamp === 'object' && dateOrTimestamp !== null && 'seconds' in dateOrTimestamp) {
      return format(new Date(dateOrTimestamp.seconds * 1000), formatStr);
    }
    if (dateOrTimestamp instanceof Date) {
      return format(dateOrTimestamp, formatStr);
    }
    if (typeof dateOrTimestamp === 'string') {
      // Try parseISO first, then native Date parse
      const parsedIso = parseISO(dateOrTimestamp);
      if (isValid(parsedIso)) return format(parsedIso, formatStr);
      const parsedNative = new Date(dateOrTimestamp);
      if (isValid(parsedNative)) return format(parsedNative, formatStr);
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
