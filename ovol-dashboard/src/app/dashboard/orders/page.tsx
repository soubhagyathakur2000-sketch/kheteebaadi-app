'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api';
import { useNotificationStore } from '@/lib/store';
import OrderKanban from '@/components/OrderKanban';
import { Order } from '@/lib/types';
import { FunnelIcon } from '@heroicons/react/24/outline';

export default function OrdersPage() {
  const [statusFilter, setStatusFilter] = useState<Order['status'] | 'all'>('all');
  const queryClient = useQueryClient();
  const addNotification = useNotificationStore((state) => state.addNotification);

  const { data: ordersData, isLoading } = useQuery({
    queryKey: ['orders', statusFilter],
    queryFn: () =>
      apiClient.getOrders({
        limit: 100,
        status: statusFilter === 'all' ? undefined : statusFilter,
      }),
  });

  const updateOrderMutation = useMutation({
    mutationFn: (vars: { orderId: string; status: Order['status'] }) =>
      apiClient.updateOrderStatus(vars.orderId, vars.status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      addNotification('Order status updated', 'success');
    },
    onError: (error) => {
      addNotification(error instanceof Error ? error.message : 'Failed to update order', 'error');
    },
  });

  const handleStatusChange = (orderId: string, newStatus: Order['status']) => {
    updateOrderMutation.mutate({ orderId, status: newStatus });
  };

  const orders = ordersData?.orders || [];

  return (
    <div className="space-y-6 p-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Orders</h1>
          <p className="mt-2 text-gray-600">Manage your order pipeline</p>
        </div>
      </div>

      {/* Filters */}
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <div className="flex items-center gap-2 mb-4">
          <FunnelIcon className="h-5 w-5 text-gray-600" />
          <span className="text-sm font-medium text-gray-700">Filter by Status:</span>
        </div>
        <div className="flex flex-wrap gap-2">
          {[
            { value: 'all', label: 'All Orders' },
            { value: 'pending', label: 'Pending' },
            { value: 'confirmed', label: 'Confirmed' },
            { value: 'dispatched', label: 'Dispatched' },
            { value: 'delivered', label: 'Delivered' },
          ].map((option) => (
            <button
              key={option.value}
              onClick={() => setStatusFilter(option.value as Order['status'] | 'all')}
              className={`rounded-full px-4 py-2 text-sm font-medium transition-colors ${
                statusFilter === option.value
                  ? 'bg-kheteebaadi-primary text-white'
                  : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {/* Kanban Board */}
      <div className="rounded-lg border border-gray-200 bg-gray-50 p-6">
        <OrderKanban
          orders={orders}
          isLoading={isLoading}
          onStatusChange={handleStatusChange}
        />
      </div>

      {/* Stats */}
      {ordersData && (
        <div className="grid gap-4 md:grid-cols-4">
          <StatCard
            label="Total Orders"
            value={ordersData.total}
            color="bg-blue-50"
          />
          <StatCard
            label="Pending"
            value={orders.filter((o) => o.status === 'pending').length}
            color="bg-yellow-50"
          />
          <StatCard
            label="Delivered"
            value={orders.filter((o) => o.status === 'delivered').length}
            color="bg-green-50"
          />
          <StatCard
            label="Payment Issues"
            value={orders.filter((o) => o.paymentStatus !== 'paid').length}
            color="bg-red-50"
          />
        </div>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  color,
}: {
  label: string;
  value: number;
  color: string;
}) {
  return (
    <div className={`rounded-lg border border-gray-200 ${color} p-4`}>
      <p className="text-sm font-medium text-gray-600">{label}</p>
      <p className="mt-2 text-3xl font-bold text-gray-900">{value}</p>
    </div>
  );
}
