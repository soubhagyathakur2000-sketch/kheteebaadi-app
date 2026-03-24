'use client';

import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api';
import { useWebSocket } from '@/hooks/useWebSocket';
import StatsCard from '@/components/StatsCard';
import {
  UserGroupIcon,
  ShoppingCartIcon,
  CurrencyRupeeIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/outline';
import Link from 'next/link';
import { format } from 'date-fns';
import { Skeleton } from '@/components/Skeleton';

export default function DashboardPage() {
  useWebSocket();

  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['stats'],
    queryFn: () => apiClient.getStats(),
  });

  const { data: ordersData, isLoading: ordersLoading } = useQuery({
    queryKey: ['orders'],
    queryFn: () => apiClient.getOrders({ limit: 10 }),
  });

  return (
    <div className="space-y-8 p-8">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">Welcome back to your OVOL partner dashboard</p>
      </div>

      {/* Stats Row */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {statsLoading ? (
          <>
            {[...Array(4)].map((_, i) => (
              <Skeleton key={i} className="h-40" />
            ))}
          </>
        ) : stats ? (
          <>
            <StatsCard
              icon={<UserGroupIcon className="h-6 w-6" />}
              label="Active Farmers"
              value={stats.activeFarmers}
              change={stats.farmersChange}
            />
            <StatsCard
              icon={<ShoppingCartIcon className="h-6 w-6" />}
              label="Listings Today"
              value={stats.listingsToday}
              change={stats.listingsChange}
            />
            <StatsCard
              icon={<CurrencyRupeeIcon className="h-6 w-6" />}
              label="Revenue This Week"
              value={`₹${(stats.revenueThisWeek / 100000).toFixed(1)}L`}
              change={stats.revenueChange}
            />
            <StatsCard
              icon={<ExclamationTriangleIcon className="h-6 w-6" />}
              label="Sync Failures"
              value={stats.syncFailures}
              change={stats.syncFailuresChange}
              trend="down"
            />
          </>
        ) : null}
      </div>

      {/* Recent Orders */}
      <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="border-b border-gray-200 px-6 py-4 sm:flex sm:items-center sm:justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Recent Orders</h2>
            <p className="mt-1 text-sm text-gray-600">Last 10 orders across your network</p>
          </div>
          <Link
            href="/dashboard/orders"
            className="mt-3 inline-flex items-center rounded-lg bg-kheteebaadi-primary px-4 py-2 text-sm font-medium text-white hover:bg-kheteebaadi-primary-dark transition-colors sm:mt-0"
          >
            View All Orders
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                  Order ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                  Farmer
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                  Amount
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                  Date
                </th>
              </tr>
            </thead>
            <tbody>
              {ordersLoading ? (
                <>
                  {[...Array(5)].map((_, i) => (
                    <tr key={i} className="border-b border-gray-200">
                      <td className="px-6 py-4">
                        <Skeleton className="h-4 w-24" />
                      </td>
                      <td className="px-6 py-4">
                        <Skeleton className="h-4 w-32" />
                      </td>
                      <td className="px-6 py-4">
                        <Skeleton className="h-4 w-20" />
                      </td>
                      <td className="px-6 py-4">
                        <Skeleton className="h-4 w-24" />
                      </td>
                      <td className="px-6 py-4">
                        <Skeleton className="h-4 w-28" />
                      </td>
                    </tr>
                  ))}
                </>
              ) : ordersData?.orders && ordersData.orders.length > 0 ? (
                ordersData.orders.map((order) => (
                  <tr
                    key={order.id}
                    className="border-b border-gray-200 hover:bg-gray-50 transition-colors"
                  >
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                      {order.id}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-700">{order.farmerName}</td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                      ₹{order.totalAmount.toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <StatusBadge status={order.status} />
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-700">
                      {format(new Date(order.createdAt), 'MMM d, yyyy')}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                    No orders found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <QuickActionCard
          title="Add New Farmer"
          description="Register a farmer to your network"
          href="/dashboard/farmers"
          color="bg-blue-50"
        />
        <QuickActionCard
          title="View Map"
          description="See all villages and stock levels"
          href="/dashboard/map"
          color="bg-green-50"
        />
        <QuickActionCard
          title="Manage Payments"
          description="Reconcile and track payments"
          href="/dashboard/payments"
          color="bg-purple-50"
        />
        <QuickActionCard
          title="View Analytics"
          description="Insights and performance metrics"
          href="/dashboard/analytics"
          color="bg-orange-50"
        />
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const statusConfig: Record<string, { bg: string; text: string }> = {
    pending: { bg: 'bg-yellow-100', text: 'text-yellow-800' },
    confirmed: { bg: 'bg-blue-100', text: 'text-blue-800' },
    dispatched: { bg: 'bg-purple-100', text: 'text-purple-800' },
    delivered: { bg: 'bg-green-100', text: 'text-green-800' },
    cancelled: { bg: 'bg-red-100', text: 'text-red-800' },
  };

  const config = statusConfig[status] || statusConfig.pending;

  return (
    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${config.bg} ${config.text}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

function QuickActionCard({
  title,
  description,
  href,
  color,
}: {
  title: string;
  description: string;
  href: string;
  color: string;
}) {
  return (
    <Link
      href={href}
      className={`rounded-lg border border-gray-200 p-6 ${color} hover:border-gray-300 transition-all hover:shadow-md`}
    >
      <h3 className="font-semibold text-gray-900">{title}</h3>
      <p className="mt-1 text-sm text-gray-600">{description}</p>
    </Link>
  );
}
