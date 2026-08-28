// Browser Desktop Notification Helper

export const requestBrowserNotificationPermission = async () => {
  if (!('Notification' in window)) {
    return 'unsupported';
  }

  if (Notification.permission === 'granted') {
    return 'granted';
  }

  if (Notification.permission !== 'denied') {
    const permission = await Notification.requestPermission();
    return permission;
  }

  return Notification.permission;
};

export const showDesktopNotification = (title, body, onClick) => {
  if (!('Notification' in window) || Notification.permission !== 'granted') {
    return null;
  }

  try {
    const notif = new Notification(title, {
      body: body || 'New organizational alert in ERMS portal.',
      icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%232563EB"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/></svg>',
      badge: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%232563EB"><circle cx="12" cy="12" r="10"/></svg>',
    });

    if (onClick) {
      notif.onclick = () => {
        window.focus();
        onClick();
        notif.close();
      };
    }

    return notif;
  } catch (err) {
    console.warn('Desktop notification error:', err);
    return null;
  }
};
