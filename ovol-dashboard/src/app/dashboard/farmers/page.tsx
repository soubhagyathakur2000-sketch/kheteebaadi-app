'use client';

import { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api';
import { useFilterStore } from '@/lib/store';
import FarmerTable from '@/components/FarmerTable';
import { Farmer } from '@/lib/types';
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline';

export default function FarmersPage() {
  const [page, setPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFarmer, setSelectedFarmer] = useState<Farmer | null>(null);
  const { village, stockLevel } = useFilterStore();

  const { data: farmersData, isLoading } = useQuery({
    queryKey: ['farmers', page, searchTerm, village],
    queryFn: () =>
      apiClient.getFarmers({
        page,
        limit: 20,
        village: village || undefined,
        search: searchTerm || undefined,
      }),
  });

  const farmers = useMemo(() => {
    if (!farmersData?.farmers) return [];
    return farmersData.farmers;
  }, [farmersData]);

  const totalPages = farmersData?.limit ? Math.ceil(farmersData.total / farmersData.limit) : 1;

  return (
    <div className="space-y-6 p-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Farmers</h1>
        <p className="mt-2 text-gray-600">Manage your farmer network</p>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <MagnifyingGlassIcon className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
        <input
          type="text"
          placeholder="Search farmers by name or phone..."
          value={searchTerm}
          onChange={(e) => {
            setSearchTerm(e.target.value);
            setPage(1);
          }}
          className="w-full rounded-lg border border-gray-300 pl-10 pr-4 py-2 text-sm focus:border-kheteebaadi-primary focus:outline-none focus:ring-1 focus:ring-kheteebaadi-primary"
        />
      </div>

      {/* Filters */}
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Filter by Status
            </label>
            <select className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-kheteebaadi-primary focus:outline-none focus:ring-1 focus:ring-kheteebaadi-primary">
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="pending">Pending</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sort By
            </label>
            <select className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-kheteebaadi-primary focus:outline-none focus:ring-1 focus:ring-kheteebaadi-primary">
              <option value="recent">Most Recent</option>
              <option value="listings">Most Listings</option>
              <option value="revenue">Highest Revenue</option>
            </select>
          </div>
        </div>
      </div>

      {/* Table */}
      <FarmerTable
        farmers={farmers}
        isLoading={isLoading}
        onRowClick={setSelectedFarmer}
      />

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <button
            onClick={() => setPage(Math.max(1, page - 1))}
            disabled={page === 1}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <span className="text-sm text-gray-700">
            Page {page} of {totalPages}
          </span>
          <button
            onClick={() => setPage(Math.min(totalPages, page + 1))}
            disabled={page === totalPages}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}

      {/* Farmer Detail Modal */}
      {selectedFarmer && (
        <FarmerDetailModal
          farmer={selectedFarmer}
          onClose={() => setSelectedFarmer(null)}
        />
      )}
    </div>
  );
}

function FarmerDetailModal({
  farmer,
  onClose,
}: {
  farmer: Farmer;
  onClose: () => void;
}) {
  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-40 bg-black bg-opacity-50"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="fixed left-1/2 top-1/2 z-50 max-h-96 w-full max-w-2xl -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-lg border border-gray-200 bg-white p-8 shadow-lg">
        <div className="flex items-start justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">{farmer.name}</h2>
            <p className="mt-1 text-gray-600">{farmer.phone}</p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 text-2xl"
          >
            ×
          </button>
        </div>

        <div className="grid gap-6 md:grid-cols-2">
          <div>
            <p className="text-sm font-medium text-gray-600">Village</p>
            <p className="mt-1 text-gray-900">{farmer.village}</p>
          </div>
          <div>
            <p className="text-sm font-medium text-gray-600">Status</p>
            <p className="mt-1">
              <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${
                farmer.status === 'active'
                  ? 'bg-green-100 text-green-800'
                  : farmer.status === 'pending'
                    ? 'bg-yellow-100 text-yellow-800'
                    : 'bg-gray-100 text-gray-800'
              }`}>
                {farmer.status.charAt(0).toUpperCase() + farmer.status.slice(1)}
              </span>
            </p>
          </div>
          <div>
            <p className="text-sm font-medium text-gray-600">Crops</p>
            <p className="mt-1 text-gray-900">{farmer.crops.join(', ')}</p>
          </div>
          <div>
            <p className="text-sm font-medium text-gray-600">Total Listings</p>
            <p className="mt-1 text-2xl font-bold text-kheteebaadi-primary">
              {farmer.totalListings}
            </p>
          </div>
          <div>
            <p className="text-sm font-medium text-gray-600">Total Revenue</p>
            <p className="mt-1 text-2xl font-bold text-kheteebaadi-success">
              ₹{farmer.totalRevenue.toLocaleString()}
            </p>
          </div>
          <div>
            <p className="text-sm font-medium text-gray-600">Joined Date</p>
            <p className="mt-1 text-gray-900">
              {new Date(farmer.joinedDate).toLocaleDateString()}
            </p>
          </div>
        </div>

        <div className="mt-8 flex gap-3">
          <button className="flex-1 rounded-lg bg-kheteebaadi-primary px-4 py-2 text-sm font-medium text-white hover:bg-kheteebaadi-primary-dark transition-colors">
            Edit Farmer
          </button>
          <button
            onClick={onClose}
            className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </>
  );
}
