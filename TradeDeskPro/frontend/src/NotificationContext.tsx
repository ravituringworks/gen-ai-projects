
import React, { createContext, useContext, useState, type ReactNode } from 'react';
import Notification from './Notification';

interface NotificationContextType {
  showNotification: (message: string, type: 'success' | 'error' | 'info', duration?: number) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const useNotification = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider');
  }
  return context;
};

interface NotificationProviderProps {
  children: ReactNode;
}

export const NotificationProvider: React.FC<NotificationProviderProps> = ({ children }) => {
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' | 'info'; duration?: number } | null>(null);

  const showNotification = (message: string, type: 'success' | 'error' | 'info', duration?: number) => {
    setNotification({ message, type, duration });
  };

  const handleCloseNotification = () => {
    setNotification(null);
  };

  return (
    <NotificationContext.Provider value={{ showNotification }}>
      {children}
      {notification && (
        <Notification
          message={notification.message}
          type={notification.type}
          duration={notification.duration}
          onClose={handleCloseNotification}
        />
      )}
    </NotificationContext.Provider>
  );
};
