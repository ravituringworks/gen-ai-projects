
import React, { useState, useEffect } from 'react';
import './Notification.css';

interface NotificationProps {
  message: string;
  type: 'success' | 'error' | 'info';
  duration?: number; // in milliseconds, default to 3000
  onClose: () => void;
}

const Notification: React.FC<NotificationProps> = ({ message, type, duration = 3000, onClose }) => {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(false);
      onClose();
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const notificationClass = `notification ${type} ${visible ? 'show' : 'hide'}`;

  return (
    <div className={notificationClass}>
      <span>{message}</span>
      <button onClick={() => { setVisible(false); onClose(); }}>&times;</button>
    </div>
  );
};

export default Notification;
