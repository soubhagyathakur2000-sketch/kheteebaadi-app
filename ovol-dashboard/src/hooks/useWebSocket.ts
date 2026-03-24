'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { WebSocketMessage } from '@/lib/types';
import { useNotificationStore } from '@/lib/store';

interface UseWebSocketOptions {
  url?: string;
  enabled?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const {
    url = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:3001/ws',
    enabled = true,
    reconnectInterval = 3000,
    maxReconnectAttempts = 5,
  } = options;

  const queryClient = useQueryClient();
  const addNotification = useNotificationStore((state) => state.addNotification);

  const wsRef = useRef<WebSocket | null>(null);
  const reconnectCountRef = useRef(0);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout>();
  const isManualCloseRef = useRef(false);

  const connect = useCallback(() => {
    if (!enabled || wsRef.current?.readyState === WebSocket.OPEN) {
      return;
    }

    try {
      const ws = new WebSocket(url);

      ws.onopen = () => {
        console.log('[WebSocket] Connected');
        reconnectCountRef.current = 0;
        addNotification('Connected to live updates', 'success');
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data) as WebSocketMessage;

          switch (message.type) {
            case 'order_update':
              queryClient.invalidateQueries({ queryKey: ['orders'] });
              addNotification('Order updated', 'info');
              break;

            case 'payment_update':
              queryClient.invalidateQueries({ queryKey: ['payments'] });
              addNotification('Payment processed', 'success');
              break;

            case 'farmer_update':
              queryClient.invalidateQueries({ queryKey: ['farmers'] });
              addNotification('Farmer data updated', 'info');
              break;

            case 'stock_update':
              queryClient.invalidateQueries({ queryKey: ['villages', 'listings'] });
              addNotification('Stock levels updated', 'info');
              break;

            case 'sync_update':
              queryClient.invalidateQueries({ queryKey: ['stats'] });
              addNotification('System synchronized', 'info');
              break;

            default:
              console.log('[WebSocket] Unknown message type:', message.type);
          }
        } catch (error) {
          console.error('[WebSocket] Error parsing message:', error);
        }
      };

      ws.onerror = (event) => {
        console.error('[WebSocket] Error:', event);
        addNotification('Connection error - retrying', 'warning');
      };

      ws.onclose = () => {
        console.log('[WebSocket] Disconnected');
        wsRef.current = null;

        if (!isManualCloseRef.current && enabled) {
          if (reconnectCountRef.current < maxReconnectAttempts) {
            reconnectCountRef.current += 1;
            const delay = reconnectInterval * Math.pow(2, reconnectCountRef.current - 1);
            console.log(`[WebSocket] Reconnecting in ${delay}ms (attempt ${reconnectCountRef.current})`);

            reconnectTimeoutRef.current = setTimeout(() => {
              connect();
            }, delay);
          } else {
            addNotification('Connection lost - max reconnect attempts exceeded', 'error');
          }
        }
      };

      wsRef.current = ws;
    } catch (error) {
      console.error('[WebSocket] Connection failed:', error);
      addNotification('Failed to connect to live updates', 'error');
    }
  }, [enabled, url, reconnectInterval, maxReconnectAttempts, queryClient, addNotification]);

  const disconnect = useCallback(() => {
    isManualCloseRef.current = true;

    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
    }

    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.close();
    }

    wsRef.current = null;
  }, []);

  useEffect(() => {
    if (enabled) {
      isManualCloseRef.current = false;
      connect();
    }

    return () => {
      disconnect();
    };
  }, [enabled, connect, disconnect]);

  return {
    isConnected: wsRef.current?.readyState === WebSocket.OPEN,
    connect,
    disconnect,
  };
}
