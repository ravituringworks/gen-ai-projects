
import React, { useState } from 'react';
import './Settings.css';

const Settings: React.FC = () => {
  const [theme, setTheme] = useState('dark');
  const [refreshInterval, setRefreshInterval] = useState(5);

  const handleThemeChange = () => {
    setTheme(prevTheme => (prevTheme === 'dark' ? 'light' : 'dark'));
    // In a real app, you'd apply this theme globally
    document.documentElement.setAttribute('data-theme', theme === 'dark' ? 'light' : 'dark');
  };

  const handleRefreshIntervalChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(e.target.value);
    if (!isNaN(value) && value > 0) {
      setRefreshInterval(value);
    }
  };

  return (
    <div className="settings-container">
      <h1>Settings</h1>

      <div className="settings-section">
        <h2>Appearance</h2>
        <div className="setting-item">
          <label>Theme:</label>
          <button onClick={handleThemeChange}>
            Switch to {theme === 'dark' ? 'Light' : 'Dark'} Theme
          </button>
        </div>
      </div>

      <div className="settings-section">
        <h2>Data & Performance</h2>
        <div className="setting-item">
          <label htmlFor="refreshInterval">Refresh Interval (seconds):</label>
          <input
            type="number"
            id="refreshInterval"
            value={refreshInterval}
            onChange={handleRefreshIntervalChange}
            min="1"
          />
        </div>
      </div>

      <div className="settings-section">
        <h2>Customization</h2>
        <div className="setting-item">
          <label>Shortcut Mappings:</label>
          <p>Configure your keyboard shortcuts here (Coming Soon).</p>
        </div>
      </div>

      <div className="settings-section">
        <h2>Debugging</h2>
        <div className="setting-item">
          <label>CLI Debug/Log Export:</label>
          <button onClick={() => alert('Exporting logs...')}>Export Logs</button>
        </div>
      </div>
    </div>
  );
};

export default Settings;
