
import React, { useState, useEffect } from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';
import './Portfolio.css';
import { useNotification } from './NotificationContext';

interface Holding {
  id?: number;
  symbol: string;
  quantity: number;
  avgPrice: number;
  currentPrice: number;
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#A28DFF', '#FF6B6B'];

const Portfolio: React.FC = () => {
  const [holdings, setHoldings] = useState<Holding[]>([]);
  const [newHoldingSymbol, setNewHoldingSymbol] = useState('');
  const [newHoldingQuantity, setNewHoldingQuantity] = useState(0);
  const [newHoldingAvgPrice, setNewHoldingAvgPrice] = useState(0);
  const [newHoldingCurrentPrice, setNewHoldingCurrentPrice] = useState(0);
  const { showNotification } = useNotification();

  const fetchPortfolio = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/portfolio');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setHoldings(data);
    } catch (error) {
      console.error('Error fetching portfolio:', error);
      showNotification('Failed to fetch portfolio.', 'error');
    }
  };

  useEffect(() => {
    fetchPortfolio();
  }, []);

  const handleAddHolding = async () => {
    if (newHoldingSymbol && newHoldingQuantity > 0 && newHoldingAvgPrice > 0 && newHoldingCurrentPrice > 0) {
      const newHolding: Holding = {
        symbol: newHoldingSymbol.toUpperCase(),
        quantity: newHoldingQuantity,
        avgPrice: newHoldingAvgPrice,
        currentPrice: newHoldingCurrentPrice,
      };
      try {
        const response = await fetch('http://localhost:8000/api/portfolio', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(newHolding),
        });
        if (response.ok) {
          fetchPortfolio(); // Refresh the list
          setNewHoldingSymbol('');
          setNewHoldingQuantity(0);
          setNewHoldingAvgPrice(0);
          setNewHoldingCurrentPrice(0);
          showNotification(`Added ${newHolding.symbol} to portfolio.`, 'success');
        } else {
          const errorData = await response.json();
          showNotification(`Failed to add holding: ${errorData.detail || response.statusText}`, 'error');
        }
      } catch (error) {
        console.error('Error adding holding:', error);
        showNotification('An error occurred while adding holding.', 'error');
      }
    } else {
      showNotification('Please fill all fields for new holding.', 'info');
    }
  };

  const handleDeleteHolding = async (symbolToDelete: string) => {
    try {
      const response = await fetch(`http://localhost:8000/api/portfolio/${symbolToDelete}`, {
        method: 'DELETE',
      });
      if (response.ok) {
        fetchPortfolio(); // Refresh the list
        showNotification(`Deleted ${symbolToDelete} from portfolio.`, 'success');
      } else {
        const errorData = await response.json();
        showNotification(`Failed to delete holding: ${errorData.detail || response.statusText}`, 'error');
      }
    } catch (error) {
      console.error('Error deleting holding:', error);
      showNotification('An error occurred while deleting holding.', 'error');
    }
  };

  const totalValue = holdings.reduce((sum, holding) => sum + (holding.quantity * holding.currentPrice), 0);

  const assetAllocationData = holdings.map((holding) => ({
    name: holding.symbol,
    value: holding.quantity * holding.currentPrice,
  }));

  return (
    <div className="portfolio-container">
      <h1>Portfolio Overview</h1>

      <div className="portfolio-section">
        <h2>Add New Holding</h2>
        <div className="add-holding-form">
          <input type="text" placeholder="Symbol" value={newHoldingSymbol} onChange={(e) => setNewHoldingSymbol(e.target.value)} />
          <input type="number" placeholder="Quantity" value={newHoldingQuantity === 0 ? '' : newHoldingQuantity} onChange={(e) => setNewHoldingQuantity(parseInt(e.target.value))} />
          <input type="number" placeholder="Avg. Price" value={newHoldingAvgPrice === 0 ? '' : newHoldingAvgPrice} onChange={(e) => setNewHoldingAvgPrice(parseFloat(e.target.value))} step="0.01" />
          <input type="number" placeholder="Current Price" value={newHoldingCurrentPrice === 0 ? '' : newHoldingCurrentPrice} onChange={(e) => setNewHoldingCurrentPrice(parseFloat(e.target.value))} step="0.01" />
          <button onClick={handleAddHolding}>Add Holding</button>
        </div>
      </div>

      <div className="portfolio-section">
        <h2>Holdings</h2>
        <table>
          <thead>
            <tr>
              <th>Symbol</th>
              <th>Quantity</th>
              <th>Avg. Price</th>
              <th>Current Price</th>
              <th>Total Value</th>
              <th>P&L</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {holdings.map((holding) => {
              const holdingValue = holding.quantity * holding.currentPrice;
              const profitLoss = (holding.currentPrice - holding.avgPrice) * holding.quantity;
              return (
                <tr key={holding.symbol}>
                  <td>{holding.symbol}</td>
                  <td>{holding.quantity}</td>
                  <td>${holding.avgPrice.toFixed(2)}</td>
                  <td>${holding.currentPrice.toFixed(2)}</td>
                  <td>${holdingValue.toFixed(2)}</td>
                  <td style={{ color: profitLoss >= 0 ? '#4CAF50' : '#F44336' }}>
                    ${profitLoss.toFixed(2)}
                  </td>
                  <td>
                    <button onClick={() => handleDeleteHolding(holding.symbol)} className="action-button cancel-button">Delete</button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="portfolio-section">
        <h2>Asset Allocation</h2>
        <ResponsiveContainer width="100%" height={300}>
          <PieChart>
            <Pie
              data={assetAllocationData}
              cx="50%"
              cy="50%"
              labelLine={false}
              outerRadius={100}
              fill="#8884d8"
              dataKey="value"
            >
              {assetAllocationData.map((_entry, index) => (
                <Cell key={`cell-${_entry.name}`} fill={COLORS[index % COLORS.length]} />
              ))}
            </Pie>
            <Tooltip formatter={(value: number) => `$${value.toFixed(2)} (${((value / totalValue) * 100).toFixed(2)}%)`}/>
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default Portfolio;
