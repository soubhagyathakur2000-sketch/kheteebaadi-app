import type { Metadata } from 'next';
import { ReactNode } from 'react';
import './globals.css';
import QueryProvider from '@/components/providers/QueryProvider';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import Notifications from '@/components/Notifications';

export const metadata: Metadata = {
  title: 'OVOL Dashboard - Kheteebaadi AgTech',
  description: 'One Village, One Lead - Partner Dashboard',
  viewport: 'width=device-width, initial-scale=1',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <QueryProvider>
          <div className="flex h-screen bg-gray-50">
            {/* Sidebar */}
            <Sidebar />

            {/* Main Content */}
            <div className="flex flex-1 flex-col overflow-hidden">
              {/* Header */}
              <Header />

              {/* Content */}
              <main className="flex-1 overflow-auto">
                <div className="h-full">{children}</div>
              </main>
            </div>

            {/* Notifications */}
            <Notifications />
          </div>
        </QueryProvider>
      </body>
    </html>
  );
}
