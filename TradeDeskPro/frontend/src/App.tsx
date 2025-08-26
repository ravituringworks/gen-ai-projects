
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Dashboard from './Dashboard';
import OrderEntry from './OrderEntry';
import Portfolio from './Portfolio';
import Settings from './Settings';
import NewsAlerts from './NewsAlerts';
import OrderHistory from './OrderHistory';
import { NotificationProvider } from './NotificationContext';
import './App.css';

function App() {
  return (
    <NotificationProvider>
      <Router>
        <div className="container">
          <div className="sidebar">
            <h2>TradeDeskPro</h2>
            <ul>
              <li><Link to="/">Dashboard</Link></li>
              <li><Link to="/order-entry">Order Entry</Link></li>
              <li><Link to="/order-history">Order History</Link></li>
              <li><Link to="/portfolio">Portfolio</Link></li>
              <li><Link to="/settings">Settings</Link></li>
              <li><Link to="/news-alerts">News & Alerts</Link></li>
            </ul>
            <div style={{ marginTop: '20px', padding: '10px' }}>
              <button onClick={() => window.location.href = 'http://localhost:8000/login/google'}>
                Login with Google
              </button>
            </div>
          </div>
          <div className="main-content">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/order-entry" element={<OrderEntry />} />
              <Route path="/order-history" element={<OrderHistory />} />
              <Route path="/portfolio" element={<Portfolio />} />
              <Route path="/settings" element={<Settings />} />
              <Route path="/news-alerts" element={<NewsAlerts />} />
            </Routes>
          </div>
        </div>
      </Router>
    </NotificationProvider>
  );
}

export default App;