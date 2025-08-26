
import { render, screen, act } from '@testing-library/react';
import App from './App';
import { NotificationProvider } from './NotificationContext';
import { expect, vi } from 'vitest';
import React from 'react'; // Import React for JSX in mocks

// Mock ResizeObserver
const ResizeObserverMock = vi.fn(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

vi.stubGlobal('ResizeObserver', ResizeObserverMock);

// Mock fetch API calls
vi.stubGlobal('fetch', vi.fn((url) => {
  if (url.includes('/api/watchlist')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve([
        { symbol: 'MOCKED_AAPL', price: 100, change: 1, changePercent: 1 },
        { symbol: 'MOCKED_GOOGL', price: 200, change: 2, changePercent: 2 },
      ]),
    });
  }
  if (url.includes('/api/chart-data')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve([
        { name: 'Day 1', price: 100, ma: 100 },
        { name: 'Day 2', price: 105, ma: 102 },
      ]),
    });
  }
  if (url.includes('/api/orders')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve([
        { id: '1', symbol: 'MOCKED_ORDER', type: 'BUY', quantity: 1, price: 10, status: 'Pending', timestamp: '2025-01-01T00:00:00Z' },
      ]),
    });
  }
  if (url.includes('/api/portfolio')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve([
        { symbol: 'MOCKED_PORTFOLIO', quantity: 1, avgPrice: 10, currentPrice: 11 },
      ]),
    });
  }
  return Promise.reject(new Error(`Unhandled fetch URL: ${url}`));
}));

// Mock WebSocket
class MockWebSocket {
  onopen: (() => void) | null = null;
  onmessage: ((event: MessageEvent) => void) | null = null;
  onclose: (() => void) | null = null;
  onerror: ((event: Event) => void) | null = null;

  constructor(url: string) {
    console.log(`MockWebSocket: ${url}`);
    setTimeout(() => {
      if (this.onopen) {
        act(() => {
          this.onopen!();
        });
      }
    }, 100);
  }

  send(data: string) {
    console.log('MockWebSocket: send', data);
  }

  close() {
    console.log('MockWebSocket: close');
    if (this.onclose) this.onclose();
  }
}

vi.stubGlobal('WebSocket', MockWebSocket);

// Mock Recharts ResponsiveContainer
vi.mock('recharts', async (importOriginal) => {
  const original = await importOriginal();
  return {
    ...original,
    ResponsiveContainer: ({ children }: { children: React.ReactNode }) => (
      React.createElement('div', { style: { width: '100%', height: 300 } }, children)
    ),
  };
});

// Mock document.documentElement.setAttribute
Object.defineProperty(document, 'documentElement', {
  value: {
    setAttribute: vi.fn(),
  },
  writable: true,
});

describe('App', () => {
  it('renders the dashboard link', async () => {
    await act(async () => {
      render(
        <NotificationProvider>
          <App />
        </NotificationProvider>
      );
    });
    expect(screen.getByText(/Dashboard/i)).not.toBeNull();
  });

  it('renders the login button', async () => {
    await act(async () => {
      render(
        <NotificationProvider>
          <App />
        </NotificationProvider>
      );
    });
    expect(screen.getByText(/Login with Google/i)).not.toBeNull();
  });
});
