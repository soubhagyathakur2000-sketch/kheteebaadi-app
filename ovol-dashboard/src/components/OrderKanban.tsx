'use client';

import { Order } from '@/lib/types';
import { format } from 'date-fns';
import clsx from 'clsx';
import { ChevronRightIcon } from '@heroicons/react/24/outline';

interface OrderKanbanProps {
  orders: Order[];
  isLoading?: boolean;
  onStatusChange?: (orderId: string, newStatus: Order['status']) => void;
}

type OrderStatus = 'pending' | 'confirmed' | 'dispatched' | 'delivered';

const COLUMNS: { status: OrderStatus; label: string }[] = [
  { status: 'pending', label: 'Pending' },
  { status: 'confirmed', label: 'Confirmed' },
  { status: 'dispatched', label: 'Dispatched' },
  { status: 'delivered', label: 'Delivered' },
];

export default function OrderKanban({
  orders,
  isLoading = false,
  onStatusChange,
}: OrderKanbanProps) {
  if (isLoading) {
    return <div className="text-center py-12 text-gray-500">Loading orders...</div>;
  }

  return (
    <div className="overflow-x-auto">
      <div className="flex gap-4 pb-4" style={{ minWidth: 'fit-content' }}>
        {COLUMNS.map((column) => {
          const columnOrders = orders.filter((o) => o.status === column.status);
          return (
            <div key={column.status} className="flex-shrink-0 w-96">
              <div className="kanban-column">
                <div className="mb-4 flex items-center justify-between">
                  <h3 className="font-semibold text-gray-900">{column.label}</h3>
                  <span className="inline-flex rounded-full bg-gray-200 px-3 py-1 text-xs font-semibold text-gray-700">
                    {columnOrders.length}
                  </span>
                </div>

                <div className="space-y-3">
                  {columnOrders.length > 0 ? (
                    columnOrders.map((order) => (
                      <OrderCard
                        key={order.id}
                        order={order}
                        onAdvance={
                          onStatusChange
                            ? () => {
                                const nextStatus = getNextStatus(order.status);
                                if (nextStatus) {
                                  onStatusChange(order.id, nextStatus);
                                }
                              }
                            : undefined
                        }
                      />
                    ))
                  ) : (
                    <div className="py-8 text-center text-gray-400">
                      <p className="text-sm">No orders</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function OrderCard({
  order,
  onAdvance,
}: {
  order: Order;
  onAdvance?: () => void;
}) {
  const statusColors: Record<OrderStatus, string> = {
    pending: 'bg-yellow-50 border-yellow-200',
    confirmed: 'bg-blue-50 border-blue-200',
    dispatched: 'bg-purple-50 border-purple-200',
    delivered: 'bg-green-50 border-green-200',
  };

  return (
    <div
      className={clsx(
        'kanban-card border',
        statusColors[order.status as OrderStatus],
      )}
    >
      <div className="mb-3 flex items-start justify-between">
        <div>
          <p className="text-xs font-semibold text-gray-600 uppercase">
            Order #{order.id.slice(0, 8)}
          </p>
          <p className="mt-1 font-medium text-gray-900">{order.farmerName}</p>
        </div>
        {onAdvance && order.status !== 'delivered' && (
          <button
            onClick={onAdvance}
            className="rounded-lg bg-kheteebaadi-primary p-1 text-white hover:bg-kheteebaadi-primary-dark transition-colors"
            title="Move to next status"
          >
            <ChevronRightIcon className="h-4 w-4" />
          </button>
        )}
      </div>

      <div className="mb-3 space-y-1 text-sm text-gray-700">
        <p className="text-xs font-medium text-gray-600">Items</p>
        <div className="text-sm">
          {order.items.slice(0, 2).map((item) => (
            <p key={item.id} className="text-xs text-gray-600">
              {item.quantity} {item.unit}
            </p>
          ))}
          {order.items.length > 2 && (
            <p className="text-xs text-gray-600">+{order.items.length - 2} more</p>
          )}
        </div>
      </div>

      <div className="border-t border-gray-200 pt-3">
        <div className="flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-900">
            ₹{order.totalAmount.toLocaleString()}
          </p>
          <span
            className={clsx(
              'inline-flex rounded px-2 py-1 text-xs font-semibold',
              order.paymentStatus === 'paid'
                ? 'bg-green-100 text-green-800'
                : order.paymentStatus === 'partial'
                  ? 'bg-yellow-100 text-yellow-800'
                  : 'bg-gray-100 text-gray-800',
            )}
          >
            {order.paymentStatus}
          </span>
        </div>
        <p className="mt-2 text-xs text-gray-500">
          {format(new Date(order.createdAt), 'MMM d')}
        </p>
      </div>
    </div>
  );
}

function getNextStatus(currentStatus: Order['status']): Order['status'] | null {
  const statusFlow: Record<OrderStatus, OrderStatus | null> = {
    pending: 'confirmed',
    confirmed: 'dispatched',
    dispatched: 'delivered',
    delivered: null,
  };
  return statusFlow[currentStatus as OrderStatus] || null;
}
