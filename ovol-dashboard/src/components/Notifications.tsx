'use client';

import { useEffect } from 'react';
import { useNotificationStore } from '@/lib/store';
import { XMarkIcon, CheckCircleIcon, ExclamationIcon, InformationCircleIcon } from '@heroicons/react/24/outline';
import clsx from 'clsx';

export default function Notifications() {
  const { notifications, removeNotification } = useNotificationStore();

  return (
    <div className="fixed right-0 top-0 z-50 space-y-3 p-4">
      {notifications.map((notification) => (
        <NotificationItem
          key={notification.id}
          notification={notification}
          onClose={() => removeNotification(notification.id)}
        />
      ))}
    </div>
  );
}

function NotificationItem({
  notification,
  onClose,
}: {
  notification: ReturnType<typeof useNotificationStore>['notifications'][0];
  onClose: () => void;
}) {
  useEffect(() => {
    const timer = setTimeout(onClose, 5000);
    return () => clearTimeout(timer);
  }, [onClose]);

  const iconMap = {
    success: <CheckCircleIcon className="h-5 w-5 text-kheteebaadi-success" />,
    error: <ExclamationIcon className="h-5 w-5 text-kheteebaadi-error" />,
    warning: <ExclamationIcon className="h-5 w-5 text-kheteebaadi-warning" />,
    info: <InformationCircleIcon className="h-5 w-5 text-blue-500" />,
  };

  const bgColorMap = {
    success: 'bg-green-50 border-green-200',
    error: 'bg-red-50 border-red-200',
    warning: 'bg-yellow-50 border-yellow-200',
    info: 'bg-blue-50 border-blue-200',
  };

  return (
    <div
      className={clsx(
        'flex items-center gap-3 rounded-lg border p-4 shadow-lg',
        bgColorMap[notification.type],
      )}
      role="alert"
    >
      {iconMap[notification.type]}
      <span className="flex-1 text-sm font-medium text-gray-900">
        {notification.message}
      </span>
      <button
        onClick={onClose}
        className="text-gray-400 hover:text-gray-600"
        aria-label="Close notification"
      >
        <XMarkIcon className="h-5 w-5" />
      </button>
    </div>
  );
}
