'use client';

import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { Skeleton } from '@/components/Skeleton';

const COLORS = ['#2E7D32', '#43A047', '#81C784', '#C8E6C9'];
const CHART_COLORS = {
  primary: '#2E7D32',
  success: '#43A047',
  warning: '#FFA726',
  error: '#E53935',
};

// Mock data - replace with real API calls
const weeklyRevenueData = [
  { week: 'Week 1', revenue: 45000, target: 50000 },
  { week: 'Week 2', revenue: 52000, target: 50000 },
  { week: 'Week 3', revenue: 48000, target: 50000 },
  { week: 'Week 4', revenue: 61000, target: 50000 },
  { week: 'Week 5', revenue: 55000, target: 50000 },
];

const topCropsData = [
  { name: 'Rice', volume: 850 },
  { name: 'Wheat', volume: 720 },
  { name: 'Cotton', volume: 650 },
  { name: 'Sugarcane', volume: 580 },
  { name: 'Maize', volume: 420 },
  { name: 'Vegetables', volume: 350 },
  { name: 'Pulses', volume: 280 },
  { name: 'Fruits', volume: 240 },
  { name: 'Spices', volume: 180 },
  { name: 'Others', volume: 120 },
];

const orderStatusData = [
  { name: 'Delivered', value: 340, fill: COLORS[0] },
  { name: 'Dispatched', value: 120, fill: COLORS[1] },
  { name: 'Confirmed', value: 85, fill: COLORS[2] },
  { name: 'Pending', value: 45, fill: COLORS[3] },
];

const farmerSignupData = [
  { month: 'Jan', farmers: 120 },
  { month: 'Feb', farmers: 150 },
  { month: 'Mar', farmers: 180 },
  { month: 'Apr', farmers: 220 },
  { month: 'May', farmers: 280 },
  { month: 'Jun', farmers: 320 },
];

export default function AnalyticsPage() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['stats'],
    queryFn: () => apiClient.getStats(),
  });

  const { data: ordersData, isLoading: ordersLoading } = useQuery({
    queryKey: ['orders'],
    queryFn: () => apiClient.getOrders({ limit: 100 }),
  });

  return (
    <div className="space-y-8 p-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        <p className="mt-2 text-gray-600">Performance metrics and insights</p>
      </div>

      {/* Key Metrics */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {statsLoading ? (
          <>
            {[...Array(4)].map((_, i) => (
              <Skeleton key={i} className="h-20" />
            ))}
          </>
        ) : stats ? (
          <>
            <MetricCard
              label="Active Farmers"
              value={stats.activeFarmers}
              change={`+${stats.farmersChange}%`}
            />
            <MetricCard
              label="Total Orders"
              value={stats.totalOrders}
              change={`${stats.totalOrders - stats.pendingOrders} delivered`}
            />
            <MetricCard
              label="Revenue This Week"
              value={`₹${(stats.revenueThisWeek / 100000).toFixed(1)}L`}
              change={`+${stats.revenueChange}%`}
            />
            <MetricCard
              label="Sync Success Rate"
              value={`${100 - Math.min(stats.syncFailures, 100)}%`}
              change={`${stats.syncFailures} failures`}
            />
          </>
        ) : null}
      </div>

      {/* Charts Grid */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Weekly Revenue */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Weekly Revenue Trend</h2>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={weeklyRevenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="week" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="revenue"
                stroke={CHART_COLORS.primary}
                strokeWidth={2}
                dot={{ fill: CHART_COLORS.primary }}
                name="Actual"
              />
              <Line
                type="monotone"
                dataKey="target"
                stroke={CHART_COLORS.warning}
                strokeWidth={2}
                strokeDasharray="5 5"
                dot={{ fill: CHART_COLORS.warning }}
                name="Target"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Top 10 Crops */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Top 10 Crops by Volume</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={topCropsData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} />
              <YAxis />
              <Tooltip />
              <Bar dataKey="volume" fill={CHART_COLORS.primary} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Order Status Distribution */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Order Status Distribution</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={orderStatusData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, value }) => `${name}: ${value}`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {orderStatusData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.fill} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Farmer Signup Trend */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Farmer Signup Trend</h2>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={farmerSignupData}>
              <defs>
                <linearGradient id="colorFarmers" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={CHART_COLORS.primary} stopOpacity={0.8} />
                  <stop offset="95%" stopColor={CHART_COLORS.primary} stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="farmers"
                stroke={CHART_COLORS.primary}
                fillOpacity={1}
                fill="url(#colorFarmers)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Summary Stats */}
      {ordersData && (
        <div className="grid gap-6 md:grid-cols-3">
          <div className="rounded-lg border border-gray-200 bg-white p-6">
            <p className="text-sm font-medium text-gray-600">Average Order Value</p>
            <p className="mt-2 text-3xl font-bold text-gray-900">
              ₹
              {ordersData.orders.length > 0
                ? Math.round(
                    ordersData.orders.reduce((sum, o) => sum + o.totalAmount, 0) /
                      ordersData.orders.length,
                  ).toLocaleString()
                : '0'}
            </p>
          </div>
          <div className="rounded-lg border border-gray-200 bg-white p-6">
            <p className="text-sm font-medium text-gray-600">Payment Success Rate</p>
            <p className="mt-2 text-3xl font-bold text-kheteebaadi-success">
              {ordersData.orders.length > 0
                ? Math.round(
                    (ordersData.orders.filter((o) => o.paymentStatus === 'paid').length /
                      ordersData.orders.length) *
                      100,
                  )
                : 0}
              %
            </p>
          </div>
          <div className="rounded-lg border border-gray-200 bg-white p-6">
            <p className="text-sm font-medium text-gray-600">Delivery Success Rate</p>
            <p className="mt-2 text-3xl font-bold text-kheteebaadi-success">
              {ordersData.orders.length > 0
                ? Math.round(
                    (ordersData.orders.filter((o) => o.status === 'delivered').length /
                      ordersData.orders.length) *
                      100,
                  )
                : 0}
              %
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

function MetricCard({
  label,
  value,
  change,
}: {
  label: string;
  value: string | number;
  change: string;
}) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
      <p className="text-sm font-medium text-gray-600">{label}</p>
      <p className="mt-2 text-2xl font-bold text-gray-900">{value}</p>
      <p className="mt-1 text-xs text-gray-500">{change}</p>
    </div>
  );
}
