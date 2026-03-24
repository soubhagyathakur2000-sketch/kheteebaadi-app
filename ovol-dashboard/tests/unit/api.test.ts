import { describe, it, expect, beforeEach, vi } from 'vitest';
import { getFarmers, getStats, updateOrderStatus } from '../../src/api/client';

vi.stubGlobal('fetch', vi.fn());

describe('API Client', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getFarmers', () => {
    it('should return parsed farmer data on success', async () => {
      const mockData = [
        { id: '1', name: 'Rajesh Kumar', village: 'Village A', crops: ['wheat'] },
        { id: '2', name: 'Priya Singh', village: 'Village B', crops: ['rice'] },
      ];

      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => mockData,
      } as Response);

      const result = await getFarmers();
      expect(result).toEqual(mockData);
      expect(global.fetch).toHaveBeenCalledWith('/api/farmers', expect.any(Object));
    });

    it('should throw AuthError on 401 response', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: false,
        status: 401,
      } as Response);

      await expect(getFarmers()).rejects.toThrow('AuthError');
    });

    it('should throw ServerError on 500 response', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: false,
        status: 500,
      } as Response);

      await expect(getFarmers()).rejects.toThrow('ServerError');
    });

    it('should handle network error', async () => {
      vi.mocked(global.fetch).mockRejectedValueOnce(new Error('Network failed'));

      await expect(getFarmers()).rejects.toThrow('Network failed');
    });
  });

  describe('getStats', () => {
    it('should return dashboard statistics', async () => {
      const mockStats = {
        totalOrders: 150,
        revenue: 250000,
        activeFarmers: 45,
        pendingDeliveries: 12,
      };

      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => mockStats,
      } as Response);

      const result = await getStats();
      expect(result).toEqual(mockStats);
      expect(global.fetch).toHaveBeenCalledWith('/api/stats', expect.any(Object));
    });

    it('should handle stats request error', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: false,
        status: 503,
      } as Response);

      await expect(getStats()).rejects.toThrow();
    });
  });

  describe('updateOrderStatus', () => {
    it('should send correct PATCH payload', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ id: 'order-1', status: 'confirmed' }),
      } as Response);

      await updateOrderStatus('order-1', 'confirmed');

      expect(global.fetch).toHaveBeenCalledWith(
        '/api/orders/order-1',
        expect.objectContaining({
          method: 'PATCH',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
          body: JSON.stringify({ status: 'confirmed' }),
        })
      );
    });

    it('should handle order update error', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: false,
        status: 404,
      } as Response);

      await expect(updateOrderStatus('invalid-id', 'confirmed')).rejects.toThrow();
    });

    it('should validate status parameter', async () => {
      const validStatuses = ['pending', 'confirmed', 'dispatched', 'delivered'];

      for (const status of validStatuses) {
        vi.mocked(global.fetch).mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: async () => ({ id: 'order-1', status }),
        } as Response);

        await updateOrderStatus('order-1', status as any);
        expect(global.fetch).toHaveBeenCalled();
      }
    });
  });

  describe('API error handling', () => {
    it('should handle 400 Bad Request', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: false,
        status: 400,
        json: async () => ({ error: 'Invalid request' }),
      } as Response);

      await expect(getFarmers()).rejects.toThrow();
    });

    it('should handle 403 Forbidden', async () => {
      vi.mocked(global.fetch).mockResolvedValueOnce({
        ok: false,
        status: 403,
        json: async () => ({ error: 'Forbidden' }),
      } as Response);

      await expect(getFarmers()).rejects.toThrow();
    });

    it('should handle timeout', async () => {
      vi.mocked(global.fetch).mockImplementationOnce(() =>
        new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 100))
      );

      await expect(getFarmers()).rejects.toThrow('Timeout');
    });
  });
});
