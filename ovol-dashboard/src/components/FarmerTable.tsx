'use client';

import { Farmer } from '@/lib/types';
import { format } from 'date-fns';
import Link from 'next/link';
import { Skeleton } from '@/components/Skeleton';
import clsx from 'clsx';

interface FarmerTableProps {
  farmers: Farmer[];
  isLoading?: boolean;
  onRowClick?: (farmer: Farmer) => void;
}

export default function FarmerTable({
  farmers,
  isLoading = false,
  onRowClick,
}: FarmerTableProps) {
  return (
    <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white shadow-sm">
      <table className="w-full">
        <thead>
          <tr className="border-b border-gray-200 bg-gray-50">
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Name
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Phone
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Village
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Crops
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Listings
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Status
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-700">
              Last Active
            </th>
          </tr>
        </thead>
        <tbody>
          {isLoading ? (
            <>
              {[...Array(5)].map((_, i) => (
                <tr key={i} className="border-b border-gray-200">
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-32" />
                  </td>
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-24" />
                  </td>
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-28" />
                  </td>
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-32" />
                  </td>
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-16" />
                  </td>
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-20" />
                  </td>
                  <td className="px-6 py-4">
                    <Skeleton className="h-4 w-24" />
                  </td>
                </tr>
              ))}
            </>
          ) : farmers && farmers.length > 0 ? (
            farmers.map((farmer) => (
              <tr
                key={farmer.id}
                onClick={() => onRowClick?.(farmer)}
                className={clsx(
                  'border-b border-gray-200 hover:bg-gray-50 transition-colors',
                  onRowClick && 'cursor-pointer',
                )}
              >
                <td className="px-6 py-4 text-sm font-medium text-gray-900">
                  {farmer.name}
                </td>
                <td className="px-6 py-4 text-sm text-gray-700">{farmer.phone}</td>
                <td className="px-6 py-4 text-sm text-gray-700">{farmer.village}</td>
                <td className="px-6 py-4 text-sm text-gray-700">
                  {farmer.crops.slice(0, 2).join(', ')}
                  {farmer.crops.length > 2 && ` +${farmer.crops.length - 2}`}
                </td>
                <td className="px-6 py-4 text-sm font-medium text-gray-900">
                  {farmer.totalListings}
                </td>
                <td className="px-6 py-4 text-sm">
                  <span
                    className={clsx(
                      'inline-flex rounded-full px-3 py-1 text-xs font-semibold',
                      farmer.status === 'active'
                        ? 'bg-green-100 text-green-800'
                        : farmer.status === 'pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-gray-100 text-gray-800',
                    )}
                  >
                    {farmer.status.charAt(0).toUpperCase() + farmer.status.slice(1)}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-700">
                  {format(new Date(farmer.lastActive), 'MMM d, yyyy')}
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={7} className="px-6 py-8 text-center text-gray-500">
                No farmers found
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
