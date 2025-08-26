
import React, { useState, useEffect } from 'react';
import './OrderHistory.css';
import { useNotification } from './NotificationContext';

interface Order {
  id: string;
  symbol: string;
  type: string;
  quantity: number;
  price: number;
  status: string;
  timestamp: string;
}

const OrderHistory: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const { showNotification } = useNotification();

  const fetchOrders = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/orders');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setOrders(data);
    } catch (error) {
      console.error('Error fetching orders:', error);
      showNotification('Failed to fetch orders.', 'error');
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const handleCancelOrder = async (orderId: string) => {
    if (window.confirm(`Are you sure you want to cancel order ${orderId}?`)) {
      try {
        const response = await fetch(`http://localhost:8000/api/orders/${orderId}`, {
          method: 'DELETE',
        });
        if (response.ok) {
          showNotification(`Order ${orderId} cancelled successfully.`, 'success');
          fetchOrders(); // Refresh the list
        } else {
          const errorData = await response.json();
          showNotification(`Failed to cancel order: ${errorData.detail || response.statusText}`, 'error');
        }
      } catch (error) {
        console.error('Error cancelling order:', error);
        showNotification('An error occurred while cancelling the order.', 'error');
      }
    }
  };

  const handleEditOrder = async (order: Order) => {
    const newQuantityStr = prompt(`Edit quantity for order ${order.id}:`, order.quantity.toString());
    const newPriceStr = prompt(`Edit price for order ${order.id}:`, order.price.toString());

    if (newQuantityStr !== null && newPriceStr !== null) {
      const newQuantity = parseInt(newQuantityStr);
      const newPrice = parseFloat(newPriceStr);

      if (!isNaN(newQuantity) && newQuantity > 0 && !isNaN(newPrice) && newPrice > 0) {
        try {
          const response = await fetch(`http://localhost:8000/api/orders/${order.id}`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ quantity: newQuantity, price: newPrice }),
          });
          if (response.ok) {
            showNotification(`Order ${order.id} updated successfully.`, 'success');
            fetchOrders(); // Refresh the list
          } else {
            const errorData = await response.json();
            showNotification(`Failed to update order: ${errorData.detail || response.statusText}`, 'error');
          }
        } catch (error) {
          console.error('Error updating order:', error);
          showNotification('An error occurred while updating the order.', 'error');
        }
      } else {
        showNotification('Invalid quantity or price. Please enter valid numbers.', 'error');
      }
    }
  };

  return (
    <div className="order-history-container">
      <h1>Order History</h1>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Symbol</th>
            <th>Type</th>
            <th>Quantity</th>
            <th>Price</th>
            <th>Status</th>
            <th>Timestamp</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr key={order.id}>
              <td>{order.id}</td>
              <td>{order.symbol}</td>
              <td>{order.type}</td>
              <td>{order.quantity}</td>
              <td>${order.price.toFixed(2)}</td>
              <td>{order.status}</td>
              <td>{new Date(order.timestamp).toLocaleString()}</td>
              <td>
                {order.status === 'Pending' && (
                  <>
                    <button onClick={() => handleEditOrder(order)} className="action-button edit-button">Edit</button>
                    <button onClick={() => handleCancelOrder(order.id)} className="action-button cancel-button">Cancel</button>
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default OrderHistory;
