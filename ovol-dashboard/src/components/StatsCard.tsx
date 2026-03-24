'use client';

import { ReactNode } from 'react';
import clsx from 'clsx';
import { ArrowUpIcon, ArrowDownIcon } from '@heroicons/react/24/outline';

interface StatsCardProps {
  icon: ReactNode;
  label: string;
  value: string | number;
  change: number;
  changeLabel?: string;
  trend?: 'up' | 'down';
}

export default function StatsCard({
  icon,
  label,
  value,
  change,
  changeLabel = 'from last week',
  trend = change >= 0 ? 'up' : 'down',
}: StatsCardProps) {
  const isPositive = change >= 0;
  const arrowIcon =
    trend === 'up' ? (
      <ArrowUpIcon className={clsx('h-4 w-4', isPositive ? 'text-kheteebaadi-success' : 'text-kheteebaadi-error')} />
    ) : (
      <ArrowDownIcon className={clsx('h-4 w-4', isPositive ? 'text-kheteebaadi-success' : 'text-kheteebaadi-error')} />
    );

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
      <div className="flex items-start justify-between">
        <div className="flex flex-1 flex-col gap-3">
          <p className="text-sm font-medium text-gray-600">{label}</p>
          <p className="text-3xl font-bold text-gray-900">{value}</p>
        </div>
        <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-kheteebaadi-primary-light text-kheteebaadi-primary">
          {icon}
        </div>
      </div>

      <div className="mt-4 flex items-center gap-1">
        {arrowIcon}
        <span
          className={clsx('text-sm font-medium', isPositive ? 'text-kheteebaadi-success' : 'text-kheteebaadi-error')}
        >
          {Math.abs(change)}%
        </span>
        <span className="text-sm text-gray-600">{changeLabel}</span>
      </div>
    </div>
  );
}
