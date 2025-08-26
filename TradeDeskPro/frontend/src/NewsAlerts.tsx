
import React, { useState } from 'react';
import './NewsAlerts.css';

interface PriceAlert {
  symbol: string;
  price: number;
  condition: 'above' | 'below';
}

interface NewsArticle {
  id: number;
  title: string;
  source: string;
  date: string;
  url: string;
}

const mockNews: NewsArticle[] = [
  { id: 1, title: 'Market Rallies on Positive Economic Data', source: 'Reuters', date: '2025-07-03', url: '#' },
  { id: 2, title: 'Tech Stocks Lead Gains in Early Trading', source: 'Bloomberg', date: '2025-07-03', url: '#' },
  { id: 3, title: 'CoinDesk: Bitcoin Price Surges Past $70,000', source: 'CoinDesk', date: '2025-07-03', url: '#' },
];

const NewsAlerts: React.FC = () => {
  const [priceAlerts, setPriceAlerts] = useState<PriceAlert[]>([
    { symbol: 'AAPL', price: 180.00, condition: 'above' },
    { symbol: 'GOOGL', price: 145.00, condition: 'below' },
  ]);
  const [newAlertSymbol, setNewAlertSymbol] = useState('');
  const [newAlertPrice, setNewAlertPrice] = useState(0);
  const [newAlertCondition, setNewAlertCondition] = useState<'above' | 'below'>('above');

  const handleAddAlert = () => {
    if (newAlertSymbol && newAlertPrice > 0) {
      setPriceAlerts([...priceAlerts, { symbol: newAlertSymbol.toUpperCase(), price: newAlertPrice, condition: newAlertCondition }]);
      setNewAlertSymbol('');
      setNewAlertPrice(0);
    }
  };

  return (
    <div className="news-alerts-container">
      <h1>News & Alerts</h1>

      <div className="news-alerts-section">
        <h2>Custom Price Alerts</h2>
        <div className="add-alert-form">
          <input
            type="text"
            placeholder="Symbol (e.g., TSLA)"
            value={newAlertSymbol}
            onChange={(e) => setNewAlertSymbol(e.target.value)}
          />
          <select value={newAlertCondition} onChange={(e) => setNewAlertCondition(e.target.value as 'above' | 'below')}>
            <option value="above">Above</option>
            <option value="below">Below</option>
          </select>
          <input
            type="number"
            placeholder="Price"
            value={newAlertPrice === 0 ? '' : newAlertPrice}
            onChange={(e) => setNewAlertPrice(parseFloat(e.target.value))}
            min="0.01"
          />
          <button onClick={handleAddAlert}>Add Alert</button>
        </div>
        <ul className="alerts-list">
          {priceAlerts.map((alert, index) => (
            <li key={index}>
              {alert.symbol} - Price {alert.condition} ${alert.price.toFixed(2)}
            </li>
          ))}
        </ul>
      </div>

      <div className="news-alerts-section">
        <h2>News Feed</h2>
        <ul className="news-list">
          {mockNews.map((article) => (
            <li key={article.id}>
              <a href={article.url} target="_blank" rel="noopener noreferrer">
                <strong>{article.title}</strong>
              </a>
              <p>{article.source} - {article.date}</p>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default NewsAlerts;
