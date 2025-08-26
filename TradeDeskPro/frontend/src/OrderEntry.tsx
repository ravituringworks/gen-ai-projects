import React, { useState } from 'react';
import './OrderEntry.css';
import { useNotification } from './NotificationContext';

const OrderEntry: React.FC = () => {
  const [symbol, setSymbol] = useState('');
  const [orderType, setOrderType] = useState('Market');
  const [quantity, setQuantity] = useState(0);
  const [price, setPrice] = useState(0); // For Limit/Stop orders
  const { showNotification } = useNotification();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const orderData = {
      symbol: symbol.toUpperCase(),
      type: orderType,
      quantity: quantity,
      price: orderType !== 'Market' ? price : 0, // Price is 0 for Market orders in this mock setup
      status: 'Pending', // All new orders start as pending
    };

    try {
      const response = await fetch('http://localhost:8000/api/orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(orderData),
      });

      if (response.ok) {
        const newOrder = await response.json();
        showNotification(`Order submitted successfully! Order ID: ${newOrder.id}`, 'success');
        // Clear form
        setSymbol('');
        setOrderType('Market');
        setQuantity(0);
        setPrice(0);
      } else {
        const errorData = await response.json();
        showNotification(`Failed to submit order: ${errorData.detail || response.statusText}`, 'error');
      }
    } catch (error) {
      console.error('Error submitting order:', error);
      showNotification('An error occurred while submitting the order.', 'error');
    }
  };

  return (
    <div className="order-entry-container">
      <h1>Order Entry</h1>
      <form onSubmit={handleSubmit} className="order-form">
        <div className="form-group">
          <label htmlFor="symbol">Symbol:</label>
          <input
            type="text"
            id="symbol"
            value={symbol}
            onChange={(e) => setSymbol(e.target.value.toUpperCase())}
            required
          />
        </div>

        <div className="form-group">
          <label htmlFor="orderType">Order Type:</label>
          <select
            id="orderType"
            value={orderType}
            onChange={(e) => setOrderType(e.target.value)}
          >
            <option value="Market">Market</option>
            <option value="Limit">Limit</option>
            <option value="Stop">Stop</option>
            <option value="StopLimit">Stop-Limit</option>
          </select>
        </div>

        <div className="form-group">
          <label htmlFor="quantity">Quantity:</label>
          <input
            type="number"
            id="quantity"
            value={quantity}
            onChange={(e) => setQuantity(parseInt(e.target.value))}
            min="1"
            required
          />
        </div>

        {(orderType === 'Limit' || orderType === 'Stop' || orderType === 'StopLimit') && (
          <div className="form-group">
            <label htmlFor="price">Price:</label>
            <input
              type="number"
              id="price"
              value={price}
              onChange={(e) => setPrice(parseFloat(e.target.value))}
              step="0.01"
              required
            />
          </div>
        )}

        <button type="submit" className="submit-button">Place Order</button>
      </form>
    </div>
  );
};

export default OrderEntry;