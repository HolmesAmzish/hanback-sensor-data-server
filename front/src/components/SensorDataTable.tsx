import { useState, useEffect, useRef } from 'react';
import { DateTime } from 'luxon';
import './SensorDataTable.css';

// Verify environment variables are loaded
if (!import.meta.env.VITE_API_BASE_URL) {
  console.error('VITE_API_BASE_URL is not defined in environment variables');
}
if (!import.meta.env.VITE_WS_BASE_URL) {
  console.error('VITE_WS_BASE_URL is not defined in environment variables');
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
const WS_BASE_URL = import.meta.env.VITE_WS_BASE_URL || `ws://${window.location.hostname}:8080`;
console.log('Using WebSocket URL:', WS_BASE_URL);

interface SensorData {
  temperature: number;
  humidity: number;
  light: number;
  rfidData: string;
  timestamp: string;
}

export default function SensorDataTable() {
  const [data, setData] = useState<SensorData[]>([]);
  const [page, setPage] = useState(1);
  const [size, setSize] = useState(10);
  const [startTime, setStartTime] = useState<string>('');
  const [endTime, setEndTime] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const ws = useRef<WebSocket | null>(null);
  const sizeRef = useRef(size);
  
  // Update ref when size changes
  useEffect(() => {
    sizeRef.current = size;
  }, [size]);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        let url = `${API_BASE_URL}/api/data?page=${page}&size=${size}`;
        if (startTime) url += `&startTime=${startTime}`;
        if (endTime) url += `&endTime=${endTime}`;
        
        const response = await fetch(url);
        const result = await response.json();
        setData(result);
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();

    // Setup WebSocket connection with retry logic
    const connectWebSocket = () => {
      const wsUrl = `${WS_BASE_URL}/ws/data`;
      console.log('Connecting to WebSocket:', wsUrl);
      ws.current = new WebSocket(wsUrl);

      ws.current.onopen = () => {
        console.log('WebSocket connected');
      };

      ws.current.onmessage = (event) => {
        const newData = JSON.parse(event.data) as SensorData;
        console.log('WebSocket message received, current size:', sizeRef.current);
        setData(prevData => {
          // Use ref to get current size without closure issues
          return [newData, ...prevData.slice(0, sizeRef.current - 1)];
        });
      };

      ws.current.onerror = (error) => {
        console.error('WebSocket error:', error);
      };

      ws.current.onclose = (event) => {
        console.log(`WebSocket disconnected (code: ${event.code}, reason: ${event.reason})`);
        if (event.code !== 1000) { // Don't reconnect if closed normally
          console.log('Attempting to reconnect in 3 seconds...');
          setTimeout(connectWebSocket, 3000);
        }
      };
    };

    connectWebSocket();

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, [page, size, startTime, endTime]);

  const handleDateFilter = () => {
    setPage(1); // Reset to first page when changing date filter
  };

  return (
    <div className="py-4 px-4 sm:px-8 w-full max-w-7xl mx-auto bg-white rounded-lg shadow-md">
      <h1 className="text-xl sm:text-2xl font-bold mb-6 text-gray-800">Sensor Data</h1>
      
      {/* Date Filter Controls */}
      <div className="flex flex-wrap gap-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Start Time</label>
          <input
            type="datetime-local"
            value={startTime}
            onChange={(e) => setStartTime(e.target.value)}
            className="p-2 border rounded-md"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">End Time</label>
          <input
            type="datetime-local"
            value={endTime}
            onChange={(e) => setEndTime(e.target.value)}
            className="p-2 border rounded-md"
          />
        </div>
        <button
          onClick={handleDateFilter}
          className="mt-6 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Apply Filter
        </button>
      </div>

      {/* Data Table */}
      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      ) : (
        <>
          {/* Desktop Table */}
          <div className="hidden sm:block overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
                  <th className="px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Temperature</th>
                  <th className="px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Humidity</th>
                  <th className="px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Light</th>
                  <th className="px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">RFID Data</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {data.map((item, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-3 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {DateTime.fromISO(item.timestamp).toLocaleString(DateTime.DATETIME_MED)}
                    </td>
                    <td className="px-3 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.temperature}°C</td>
                    <td className="px-3 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.humidity}%</td>
                    <td className="px-3 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.light} lux</td>
                    <td className="px-3 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.rfidData}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobile Cards */}
          <div className="sm:hidden space-y-4">
            {data.map((item, index) => (
              <div key={index} className="p-4 border rounded-lg shadow-sm">
                <div className="flex justify-between mb-2">
                  <span className="font-medium">Timestamp:</span>
                  <span>{DateTime.fromISO(item.timestamp).toLocaleString(DateTime.DATETIME_MED)}</span>
                </div>
                <div className="flex justify-between mb-2">
                  <span className="font-medium">Temperature:</span>
                  <span>{item.temperature}°C</span>
                </div>
                <div className="flex justify-between mb-2">
                  <span className="font-medium">Humidity:</span>
                  <span>{item.humidity}%</span>
                </div>
                <div className="flex justify-between mb-2">
                  <span className="font-medium">Light:</span>
                  <span>{item.light} lux</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-medium">RFID Data:</span>
                  <span>{item.rfidData}</span>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* Pagination Controls */}
      <div className="flex justify-between items-center mt-6">
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-700">Rows per page:</span>
          <select
            value={size}
            onChange={(e) => setSize(Number(e.target.value))}
            className="p-1 border rounded-md"
          >
            <option value="5">5</option>
            <option value="10">10</option>
            <option value="20">20</option>
            <option value="50">50</option>
          </select>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setPage(p => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-3 py-1 border rounded-md disabled:opacity-50"
          >
            Previous
          </button>
          <span className="px-3 py-1 text-sm text-gray-700">Page {page}</span>
          <button
            onClick={() => setPage(p => p + 1)}
            disabled={data.length < size}
            className="px-3 py-1 border rounded-md disabled:opacity-50"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  );
}
