
import React, { useState, useEffect } from 'react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ComposedChart } from 'recharts';

interface ChartData {
  name: string;
  uv?: number;
  pv?: number;
  amt?: number;
  open?: number;
  close?: number;
  high?: number;
  low?: number;
  price?: number; // Added for line chart with MA
  ma?: number;    // Added for line chart with MA
}

const Chart: React.FC = () => {
  const [chartData, setChartData] = useState<ChartData[]>([]);
  const [selectedChartType, setSelectedChartType] = useState<'line' | 'bar' | 'candlestick'>('line');

  useEffect(() => {
    const fetchChartData = async () => {
      try {
        const response = await fetch(`http://localhost:8000/api/chart-data?chart_type=${selectedChartType}`);
        const data = await response.json();
        setChartData(data);
      } catch (error) {
        console.error('Error fetching chart data:', error);
      }
    };
    fetchChartData();
  }, [selectedChartType]);

  return (
    <div>
      <div style={{ marginBottom: '10px' }}>
        <button onClick={() => setSelectedChartType('line')} style={{ marginRight: '10px' }}>Line Chart</button>
        <button onClick={() => setSelectedChartType('bar')} style={{ marginRight: '10px' }}>Bar Chart</button>
        <button onClick={() => setSelectedChartType('candlestick')}>Candlestick Chart</button>
      </div>
      <ResponsiveContainer width="100%" height={300}>
        <>
          {selectedChartType === 'line' && (
            <LineChart
              data={chartData}
              margin={{
                top: 5,
                right: 30,
                left: 20,
                bottom: 5,
              }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="price" stroke="#8884d8" activeDot={{ r: 8 }} name="Price" />
              <Line type="monotone" dataKey="ma" stroke="#82ca9d" name="MA" />
            </LineChart>
          )}
          {selectedChartType === 'bar' && (
            <BarChart
              data={chartData}
              margin={{
                top: 5,
                right: 30,
                left: 20,
                bottom: 5,
              }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="pv" fill="#8884d8" />
              <Bar dataKey="uv" fill="#82ca9d" />
            </BarChart>
          )}
          {selectedChartType === 'candlestick' && (
            <ComposedChart
              data={chartData}
              margin={{
                top: 5,
                right: 30,
                left: 20,
                bottom: 5,
              }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis domain={['dataMin', 'dataMax']} />
              <Tooltip />
              <Legend />
              <Bar dataKey="close" fill="#4CAF50" name="Close" />
              <Line type="monotone" dataKey="open" stroke="#F44336" name="Open" />
            </ComposedChart>
          )}
        </>
      </ResponsiveContainer>
    </div>
  );
};

export default Chart;
