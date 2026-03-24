'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useSidebarStore } from '@/lib/store';
import clsx from 'clsx';
import {
  HomeIcon,
  MapIcon,
  UserGroupIcon,
  ShoppingCartIcon,
  CubeIcon,
  CreditCardIcon,
  ChartBarIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
} from '@heroicons/react/24/outline';

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: HomeIcon },
  { href: '/dashboard/map', label: 'Map View', icon: MapIcon },
  { href: '/dashboard/farmers', label: 'Farmers', icon: UserGroupIcon },
  { href: '/dashboard/orders', label: 'Orders', icon: ShoppingCartIcon },
  { href: '/dashboard/inventory', label: 'Inventory', icon: CubeIcon },
  { href: '/dashboard/payments', label: 'Payments', icon: CreditCardIcon },
  { href: '/dashboard/analytics', label: 'Analytics', icon: ChartBarIcon },
];

export default function Sidebar() {
  const pathname = usePathname();
  const { isOpen, toggle } = useSidebarStore();

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 z-30 bg-black bg-opacity-50 lg:hidden"
          onClick={toggle}
        />
      )}

      {/* Sidebar */}
      <aside
        className={clsx(
          'fixed left-0 top-0 z-40 h-screen w-64 transform bg-white shadow-lg transition-transform duration-300 ease-in-out lg:relative lg:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-kheteebaadi-primary text-white font-bold">
                K
              </div>
              <div>
                <h1 className="font-bold text-gray-900">Kheteebaadi</h1>
                <p className="text-xs text-gray-500">OVOL</p>
              </div>
            </Link>
            <button
              onClick={toggle}
              className="rounded-lg p-2 hover:bg-gray-100 lg:hidden"
            >
              <ChevronLeftIcon className="h-5 w-5" />
            </button>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto px-3 py-6">
          <ul className="space-y-2">
            {navItems.map(({ href, label, icon: Icon }) => {
              const isActive = pathname === href || pathname.startsWith(href + '/');
              return (
                <li key={href}>
                  <Link
                    href={href}
                    onClick={() => {
                      if (window.innerWidth < 1024) {
                        toggle();
                      }
                    }}
                    className={clsx(
                      'flex items-center gap-3 rounded-lg px-4 py-3 font-medium transition-colors',
                      isActive
                        ? 'bg-kheteebaadi-primary-light text-kheteebaadi-primary-dark'
                        : 'text-gray-700 hover:bg-gray-100',
                    )}
                  >
                    <Icon className="h-5 w-5 flex-shrink-0" />
                    <span>{label}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        {/* Footer */}
        <div className="border-t border-gray-200 p-4">
          <button className="w-full rounded-lg bg-kheteebaadi-primary py-2 text-sm font-medium text-white hover:bg-kheteebaadi-primary-dark transition-colors">
            Log Out
          </button>
        </div>
      </aside>

      {/* Collapse button for desktop */}
      <div className="hidden lg:flex items-center">
        <button
          onClick={toggle}
          className="absolute left-64 top-20 z-50 -right-3 flex h-6 w-6 items-center justify-center rounded-full bg-white shadow-md hover:bg-gray-100"
        >
          {isOpen ? (
            <ChevronLeftIcon className="h-4 w-4" />
          ) : (
            <ChevronRightIcon className="h-4 w-4" />
          )}
        </button>
      </div>
    </>
  );
}
