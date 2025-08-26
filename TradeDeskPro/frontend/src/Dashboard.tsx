
import React from 'react';
import Chart from './Chart';
import Watchlist from './Watchlist';
import './Dashboard.css';

const Dashboard: React.FC = () => {
  return (
    <div className="dashboard-container">
      <div className="dashboard-section chart-section">
        <h2>Market Overview</h2>
        <Chart />
      </div>
      <div className="dashboard-section watchlist-section">
        <Watchlist />
      </div>
      <div className="dashboard-section account-summary-section">
        <h3>Account Summary</h3>
        <p>Total Balance: $100,000.00</p>
        <p>Today's P&L: +$500.00</p>
        {/* More account summary details */}
      </div>
    </div>
  );
};

export default Dashboard;
