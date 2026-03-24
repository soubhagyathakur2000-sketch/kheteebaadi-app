'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api';
import { useNotificationStore } from '@/lib/store';
import { Payment } from '@/lib/types';
import { CheckCircleIcon, ClockIcon, ExclamationIcon } from '@heroicons/react/24/outline';
import { Skeleton } from '@/components/Skeleton';

export default function PaymentsPage() {
  const [statusFilter, setStatusFilter] = useState<Payment['status'] | 'all'>('all');
  const queryClient = useQueryClient();
  const addNotification = useNotificationStore((state) => state.addNotification);

  const { data: paymentsData, isLoading } = useQuery({
    queryKey: ['payments', statusFilter],
    queryFn: () =>
      apiClient.getPayments({
        limit: 100,
        status: statusFilter === 'all' ? undefined : statusFilter,
      }),
  });

  const verifyMutation = useMutation({
    mutationFn: (paymentId: string) => apiClient.verifyPayment(paymentId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payments'] });
      addNotification('Payment verified successfully', 'success');
    },
    onError: (error) => {
      addNotification(error instanceof Error ? error.message : 'Verification failed', 'error');
    },
  });

  const payments = paymentsData?.payments || [];
  const stuckPayments = payments.filter((p) => p.status === 'pending');

  return (
    <div className="space-y-6 p-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Payments</h1>
        <p className="mt-2 text-gray-600">Manage and reconcile payments</p>
      </div>

      {/* KPIs */}
      <div className="grid gap-4 md:grid-cols-4">
        <KpiCard
          icon={<CheckCircleIcon className="h-6 w-6 text-kheteebaadi-success" />}
          label="Successful"
          value={payments.filter((p) => p.status === 'successful').length}
          color="bg-green-50"
        />
        <KpiCard
          icon={<ClockIcon className="h-6 w-6 text-kheteebaadi-warning" />}
          label="Pending"
          value={payments.filter((p) => p.status === 'pending').length}
          color="bg-yellow-50"
        />
        <KpiCard
          icon={<ExclamationIcon className="h-6 w-6 text-kheteebaadi-error" />}
          label="Failed"
          value={payments.filter((p) => p.status === 'failed').length}
          color="bg-red-50"
        />
        <KpiCard
          label="Total Processed"
          value={`₹${payments.reduce((sum, p) => sum + p.amount, 0).toLocaleString()}`}
          color="bg-blue-50"
        />
      </div>

      {/* Filters */}
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <p className="mb-3 text-sm font-medium text-gray-700">Filter by Status:</p>
        <div className="flex flex-wrap gap-2">
          {[
            { value: 'all', label: 'All Payments' },
            { value: 'successful', label: 'Successful' },
            { value: 'pending', label: 'Pending' },
            { value: 'failed', label: 'Failed' },
          ].map((option) => (
            <button
              key={option.value}
              onClick={() => setStatusFilter(option.value as Payment['status'] | 'all')}
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

      {/* Stuck Payments Alert */}
      {stuckPayments.length > 0 && (
        <div className="rounded-lg border border-kheteebaadi-warning bg-kheteebaadi-warning bg-opacity-10 p-4">
          <p className="font-medium text-kheteebaadi-warning">
            {stuckPayments.length} payment{stuckPayments.length > 1 ? 's' : ''} pending verification
          </p>
          <p className="mt-1 text-sm text-gray-600">
            These payments need manual verification or retry
          </p>
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white shadow-sm">
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
                Method
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                Reference
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                Date
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
                Action
              </th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
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
                      <Skeleton className="h-4 w-16" />
                    </td>
                    <td className="px-6 py-4">
                      <Skeleton className="h-4 w-24" />
                    </td>
                    <td className="px-6 py-4">
                      <Skeleton className="h-4 w-20" />
                    </td>
                    <td className="px-6 py-4">
                      <Skeleton className="h-4 w-24" />
                    </td>
                    <td className="px-6 py-4">
                      <Skeleton className="h-4 w-16" />
                    </td>
                  </tr>
                ))}
              </>
            ) : payments.length > 0 ? (
              payments.map((payment) => (
                <tr
                  key={payment.id}
                  className={`border-b border-gray-200 hover:bg-gray-50 transition-colors ${
                    payment.status === 'pending' ? 'bg-yellow-50' : ''
                  }`}
                >
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">
                    {payment.orderId}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700">
                    {payment.farmerName}
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold text-gray-900">
                    ₹{payment.amount.toLocaleString()}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700">
                    {payment.method.toUpperCase()}
                  </td>
                  <td className="px-6 py-4 text-sm font-mono text-gray-600">
                    {payment.upiRef || payment.bankRef || '-'}
                  </td>
                  <td className="px-6 py-4 text-sm">
                    <span
                      className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${
                        payment.status === 'successful'
                          ? 'bg-green-100 text-green-800'
                          : payment.status === 'pending'
                            ? 'bg-yellow-100 text-yellow-800'
                            : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {payment.status.charAt(0).toUpperCase() + payment.status.slice(1)}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700">
                    {new Date(payment.createdAt).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 text-sm">
                    {payment.status === 'pending' && (
                      <button
                        onClick={() => verifyMutation.mutate(payment.id)}
                        disabled={verifyMutation.isPending}
                        className="rounded-lg bg-kheteebaadi-primary px-3 py-1 text-white hover:bg-kheteebaadi-primary-dark disabled:opacity-50 transition-colors text-xs font-medium"
                      >
                        Verify
                      </button>
                    )}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={8} className="px-6 py-8 text-center text-gray-500">
                  No payments found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function KpiCard({
  icon,
  label,
  value,
  color,
}: {
  icon?: React.ReactNode;
  label: string;
  value: string | number;
  color: string;
}) {
  return (
    <div className={`rounded-lg border border-gray-200 ${color} p-4`}>
      {icon && <div className="mb-2">{icon}</div>}
      <p className="text-sm font-medium text-gray-600">{label}</p>
      <p className="mt-2 text-2xl font-bold text-gray-900">{value}</p>
    </div>
  );
}
