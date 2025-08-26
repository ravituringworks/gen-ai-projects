import React, { useState, useEffect } from 'react';
import { useNotification } from './NotificationContext';

interface Stock {
  id?: number; // Added id for database interaction
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
}

const Watchlist: React.FC = () => {
  const [watchlist, setWatchlist] = useState<Stock[]>([]);
  const [newSymbol, setNewSymbol] = useState('');
  const { showNotification } = useNotification();

  const fetchWatchlist = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/watchlist');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setWatchlist(data);
    } catch (error) {
      console.error('Error fetching watchlist:', error);
      showNotification('Failed to fetch watchlist.', 'error');
    }
  };

  useEffect(() => {
    fetchWatchlist();

    // WebSocket for real-time price updates
    const ws = new WebSocket('ws://localhost:8000/ws/prices');

    ws.onopen = () => {
      console.log('WebSocket connected');
      showNotification('Real-time prices connected.', 'success', 2000);
    };

    ws.onmessage = (event) => {
      const updatedStock = JSON.parse(event.data);
      setWatchlist(prevWatchlist =>
        prevWatchlist.map(stock =>
          stock.symbol === updatedStock.symbol
            ? { ...stock, price: updatedStock.price, change: updatedStock.change, changePercent: updatedStock.changePercent }
            : stock
        )
      );
    };

    ws.onclose = () => {
      console.log('WebSocket disconnected');
      showNotification('Real-time prices disconnected.', 'info', 3000);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
      showNotification('Real-time price connection error.', 'error');
    };

    return () => {
      ws.close();
    };
  }, []);

  const handleAddSymbol = async () => {
    if (newSymbol && !watchlist.some(stock => stock.symbol === newSymbol.toUpperCase())) {
      const newStock: Stock = {
        symbol: newSymbol.toUpperCase(),
        price: parseFloat(((Math.random() * 200) + 50).toFixed(2)), // Random price
        change: parseFloat(((Math.random() * 10) - 5).toFixed(2)), // Random change
        changePercent: parseFloat(((Math.random() * 3) - 1.5).toFixed(2)), // Random percent change
      };
      try {
        const response = await fetch('http://localhost:8000/api/watchlist', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(newStock),
        });
        if (response.ok) {
          const addedStock = await response.json();
          setWatchlist([...watchlist, addedStock]);
          setNewSymbol('');
          showNotification(`Added ${addedStock.symbol} to watchlist.`, 'success');
        } else {
          const errorData = await response.json();
          showNotification(`Failed to add ${newSymbol.toUpperCase()}: ${errorData.detail || response.statusText}`, 'error');
        }
      } catch (error) {
        console.error('Error adding watchlist item:', error);
        showNotification('An error occurred while adding to watchlist.', 'error');
      }
    } else if (newSymbol) {
      showNotification(`${newSymbol.toUpperCase()} is already in your watchlist.`, 'info');
    }
  };

  const handleDeleteSymbol = async (symbolToDelete: string) => {
    try {
      const response = await fetch(`http://localhost:8000/api/watchlist/${symbolToDelete}`, {
        method: 'DELETE',
      });
      if (response.ok) {
        setWatchlist(watchlist.filter(stock => stock.symbol !== symbolToDelete));
        showNotification(`Removed ${symbolToDelete} from watchlist.`, 'success');
      } else {
        const errorData = await response.json();
        showNotification(`Failed to delete ${symbolToDelete}: ${errorData.detail || response.statusText}`, 'error');
      }
    } catch (error) {
      console.error('Error deleting watchlist item:', error);
      showNotification('An error occurred while deleting from watchlist.', 'error');
    }
  };

  return (
    <div className="watchlist">
      <h3>Watchlist</h3>
      <div className="add-symbol-container">
        <input
          type="text"
          placeholder="Add symbol (e.g., TSLA)"
          value={newSymbol}
          onChange={(e) => setNewSymbol(e.target.value)}
          onKeyPress={(e) => {
            if (e.key === 'Enter') {
              handleAddSymbol();
            }
          }}
        />
        <button onClick={handleAddSymbol}>Add</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Symbol</th>
            <th>Price</th>
            <th>Change</th>
            <th>% Change</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {watchlist.map((stock) => (
            <tr key={stock.symbol}>
              <td>{stock.symbol}</td>
              <td>{stock.price.toFixed(2)}</td>
              <td style={{ color: stock.change >= 0 ? '#4CAF50' : '#F44336' }}>
                {stock.change.toFixed(2)}
              </td>
              <td style={{ color: stock.change >= 0 ? '#4CAF50' : '#F44336' }}>
                {stock.changePercent.toFixed(2)}%
              </td>
              <td>
                <button onClick={() => handleDeleteSymbol(stock.symbol)} className="action-button cancel-button">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default Watchlist;