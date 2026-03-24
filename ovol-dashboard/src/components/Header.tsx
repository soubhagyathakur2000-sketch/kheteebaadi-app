'use client';

import { useSidebarStore } from '@/lib/store';
import { Bars3Icon } from '@heroicons/react/24/outline';
import Link from 'next/link';

export default function Header() {
  const { toggle } = useSidebarStore();

  return (
    <header className="border-b border-gray-200 bg-white shadow-sm">
      <div className="flex items-center justify-between px-6 py-4">
        <div className="flex items-center gap-4">
          <button
            onClick={toggle}
            className="rounded-lg p-2 hover:bg-gray-100 lg:hidden"
            aria-label="Toggle sidebar"
          >
            <Bars3Icon className="h-6 w-6" />
          </button>
          <Link href="/" className="flex items-center gap-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-kheteebaadi-primary text-white font-bold">
              K
            </div>
            <span className="hidden font-semibold text-gray-900 sm:inline">
              OVOL Dashboard
            </span>
          </Link>
        </div>

        <div className="flex items-center gap-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-kheteebaadi-primary text-white font-medium">
            P
          </div>
        </div>
      </div>
    </header>
  );
}
