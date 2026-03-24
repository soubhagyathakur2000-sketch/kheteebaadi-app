'use client';

import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api';
import MapView from '@/components/MapView';
import { useFilterStore } from '@/lib/store';
import { Village } from '@/lib/types';
import { useState } from 'react';
import {
  XMarkIcon,
  FunnelIcon,
} from '@heroicons/react/24/outline';
import clsx from 'clsx';

export default function MapPage() {
  const { data: villages = [], isLoading } = useQuery({
    queryKey: ['villages'],
    queryFn: () => apiClient.getVillages(),
  });

  const { cropType, stockLevel, setFilter, clearFilters } = useFilterStore();
  const [selectedVillage, setSelectedVillage] = useState<Village | null>(null);
  const [showFilters, setShowFilters] = useState(false);

  const handleVillageClick = (village: Village) => {
    setSelectedVillage(village);
  };

  return (
    <div className="relative h-screen w-full">
      {/* Map */}
      {!isLoading && <MapView villages={villages} onVillageClick={handleVillageClick} />}

      {/* Filter Panel */}
      <div className="absolute right-0 top-0 z-10 m-4 flex gap-2">
        <button
          onClick={() => setShowFilters(!showFilters)}
          className="flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 shadow-md hover:bg-gray-50"
        >
          <FunnelIcon className="h-5 w-5" />
          Filters
        </button>
      </div>

      {showFilters && (
        <div className="absolute right-4 top-16 z-10 w-80 rounded-lg border border-gray-200 bg-white p-6 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900">Filters</h3>
            <button
              onClick={() => setShowFilters(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-4">
            {/* Crop Type Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Crop Type
              </label>
              <select
                value={cropType || ''}
                onChange={(e) => setFilter('cropType', e.target.value || null)}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-kheteebaadi-primary focus:outline-none focus:ring-1 focus:ring-kheteebaadi-primary"
              >
                <option value="">All Crops</option>
                <option value="rice">Rice</option>
                <option value="wheat">Wheat</option>
                <option value="cotton">Cotton</option>
                <option value="sugarcane">Sugarcane</option>
                <option value="maize">Maize</option>
                <option value="vegetables">Vegetables</option>
              </select>
            </div>

            {/* Stock Level Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Stock Level
              </label>
              <div className="space-y-2">
                {[
                  { value: 'all', label: 'All Levels' },
                  { value: 'high', label: 'High (66%+)' },
                  { value: 'medium', label: 'Medium (33-65%)' },
                  { value: 'low', label: 'Low (<33%)' },
                ].map((option) => (
                  <label key={option.value} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="stock-level"
                      value={option.value}
                      checked={stockLevel === option.value}
                      onChange={(e) => setFilter('stockLevel', e.target.value)}
                      className="h-4 w-4 border-gray-300 text-kheteebaadi-primary focus:ring-kheteebaadi-primary"
                    />
                    <span className="text-sm text-gray-700">{option.label}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Clear Filters */}
            <button
              onClick={clearFilters}
              className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Clear All Filters
            </button>
          </div>
        </div>
      )}

      {/* Village Details Sidebar */}
      {selectedVillage && (
        <div className="absolute bottom-0 left-0 z-10 m-4 max-h-96 w-96 overflow-y-auto rounded-lg border border-gray-200 bg-white p-6 shadow-lg">
          <div className="flex items-start justify-between mb-4">
            <div>
              <h3 className="font-bold text-lg text-gray-900">{selectedVillage.name}</h3>
              <p className="text-sm text-gray-600">
                {selectedVillage.district}, {selectedVillage.state}
              </p>
            </div>
            <button
              onClick={() => setSelectedVillage(null)}
              className="text-gray-400 hover:text-gray-600"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-3 text-sm">
            <div>
              <p className="text-gray-600">Active Farmers</p>
              <p className="text-lg font-semibold text-gray-900">{selectedVillage.farmerCount}</p>
            </div>

            <div>
              <p className="text-gray-600">Total Stock</p>
              <p className="text-lg font-semibold text-gray-900">
                {selectedVillage.totalStock} units
              </p>
            </div>

            <div>
              <p className="text-gray-600">Stock Health</p>
              <div className="mt-2 flex items-center gap-2">
                <div className="h-2 flex-1 rounded-full bg-gray-200">
                  <div
                    className={clsx(
                      'h-2 rounded-full',
                      selectedVillage.avgStockHealth >= 66
                        ? 'bg-kheteebaadi-success'
                        : selectedVillage.avgStockHealth >= 33
                          ? 'bg-kheteebaadi-warning'
                          : 'bg-kheteebaadi-error',
                    )}
                    style={{ width: `${selectedVillage.avgStockHealth}%` }}
                  />
                </div>
                <span className="font-semibold text-gray-900">
                  {selectedVillage.avgStockHealth}%
                </span>
              </div>
            </div>

            <div>
              <p className="text-gray-600">Last Sync</p>
              <p className="text-gray-900">
                {new Date(selectedVillage.lastSyncTime).toLocaleString()}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
