# OVOL Dashboard - Implementation Guide

## Complete File Structure

### Configuration Files
- `package.json` - Dependencies and scripts
- `next.config.js` - Next.js configuration with mapbox-gl transpiling
- `tsconfig.json` - TypeScript configuration
- `tailwind.config.js` - Tailwind CSS with Kheteebaadi colors
- `postcss.config.js` - PostCSS configuration
- `.gitignore` - Git ignore rules
- `.env.example` - Environment variables template

### Core Application Files
- `src/app/layout.tsx` - Root layout with QueryClientProvider and Sidebar
- `src/app/page.tsx` - Redirect to dashboard
- `src/app/globals.css` - Global styles and Tailwind directives

### Dashboard Pages
- `src/app/dashboard/layout.tsx` - Dashboard layout wrapper
- `src/app/dashboard/page.tsx` - Main dashboard with KPI cards and recent orders
- `src/app/dashboard/map/page.tsx` - Mapbox GL map visualization
- `src/app/dashboard/farmers/page.tsx` - Farmer management with search and filters
- `src/app/dashboard/orders/page.tsx` - Order Kanban board
- `src/app/dashboard/inventory/page.tsx` - Crop listings and stock management
- `src/app/dashboard/payments/page.tsx` - Payment reconciliation
- `src/app/dashboard/analytics/page.tsx` - Analytics with Recharts

### Components
- `src/components/Header.tsx` - Top header with logo and user menu
- `src/components/Sidebar.tsx` - Collapsible navigation sidebar
- `src/components/StatsCard.tsx` - Reusable KPI card with trend indicator
- `src/components/Skeleton.tsx` - Loading skeleton component
- `src/components/Notifications.tsx` - Toast notification system
- `src/components/FarmerTable.tsx` - Reusable farmer data table
- `src/components/MapView.tsx` - Mapbox GL JS wrapper with clustering
- `src/components/OrderKanban.tsx` - Kanban board for order pipeline
- `src/components/providers/QueryProvider.tsx` - TanStack Query provider

### Libraries
- `src/lib/types.ts` - TypeScript interfaces (Farmer, Order, Payment, etc.)
- `src/lib/api.ts` - API client with fetch wrapper
- `src/lib/store.ts` - Zustand stores (sidebar, filters, map, notifications, auth)

### Hooks
- `src/hooks/useWebSocket.ts` - WebSocket connection with auto-reconnect

## Key Features

### 1. Dashboard (`/dashboard`)
- 4 KPI cards: Active Farmers, Listings Today, Revenue, Sync Failures
- Recent orders table (last 10)
- Quick action cards linking to other pages
- Real-time stat updates via WebSocket

### 2. Map View (`/dashboard/map`)
- Full-screen Mapbox GL map
- Village markers with clustering
- Color-coded markers (green=high stock, red=low stock)
- Interactive popups with village details
- Filter panel (crop type, stock level)
- Left sidebar showing selected village details

### 3. Farmers (`/dashboard/farmers`)
- Search bar for name/phone
- Filter by status
- Sortable farmer table (name, phone, village, crops, listings, last active)
- Click row to view farmer details in modal
- Pagination support

### 4. Orders (`/dashboard/orders`)
- Kanban-style order pipeline
- 4 columns: Pending, Confirmed, Dispatched, Delivered
- Order cards show: ID, farmer name, items, amount, date, payment status
- Click arrow button to advance order status
- Filter by status
- Stats cards showing order counts and payment issues

### 5. Inventory (`/dashboard/inventory`)
- Search crop listings
- Table: crop type, farmer, quantity, price, value, status, expiry
- Color-coded status badges
- Summary cards (total listings, active listings, inventory value)

### 6. Payments (`/dashboard/payments`)
- Payment reconciliation table
- Filter by status (all, successful, pending, failed)
- Pending payments highlighted in yellow
- Manual verification button for pending payments
- KPI cards: successful, pending, failed, total processed
- Alert for stuck payments

### 7. Analytics (`/dashboard/analytics`)
- Weekly revenue line chart (actual vs target)
- Top 10 crops bar chart
- Order status distribution pie chart
- Farmer signup trend area chart
- Summary metrics: avg order value, payment success rate, delivery success rate

## Styling

All components use Tailwind CSS with the Kheteebaadi brand color palette:

```
kheteebaadi-primary: #2E7D32 (dark green)
kheteebaadi-primary-dark: #1B5E20 (darker green)
kheteebaadi-primary-light: #81C784 (light green)
kheteebaadi-accent: #EF6C00 (orange)
kheteebaadi-success: #43A047 (success green)
kheteebaadi-warning: #FFA726 (warning orange)
kheteebaadi-error: #E53935 (error red)
```

## API Integration

The API client (`src/lib/api.ts`) provides these methods:

### Farmers
- `getFarmers(params)` - Get farmers with pagination, filters, search
- `getFarmer(id)` - Get single farmer
- `updateFarmer(id, data)` - Update farmer data

### Villages
- `getVillages()` - Get all villages
- `getVillage(id)` - Get single village

### Orders
- `getOrders(params)` - Get orders with filters
- `getOrder(id)` - Get single order
- `createOrder(data)` - Create new order
- `updateOrderStatus(id, status)` - Change order status

### Payments
- `getPayments(params)` - Get payments with filters
- `getPayment(id)` - Get single payment
- `recordPayment(data)` - Record new payment
- `verifyPayment(id)` - Verify pending payment

### Listings
- `getListings(params)` - Get crop listings with filters
- `getListing(id)` - Get single listing

### Other
- `getStats()` - Get dashboard stats
- `getProducts()` - Get product catalog
- `healthCheck()` - API health check

## State Management

### useSidebarStore
```tsx
const { isOpen, toggle, setOpen } = useSidebarStore();
```

### useFilterStore
```tsx
const { cropType, dateRange, village, stockLevel, setFilter, setDateRange, clearFilters } = useFilterStore();
```

### useMapStore
```tsx
const { viewport, setViewport } = useMapStore();
```

### useNotificationStore
```tsx
const { notifications, addNotification, removeNotification, clearNotifications } = useNotificationStore();
```

### useAuthStore
```tsx
const { token, user, setAuth, clearAuth } = useAuthStore();
```

## WebSocket Integration

The `useWebSocket` hook handles real-time updates:

```tsx
useWebSocket({
  url: 'ws://localhost:3001/ws',
  enabled: true,
  reconnectInterval: 3000,
  maxReconnectAttempts: 5,
});
```

Message types automatically invalidate relevant queries:
- `order_update` → invalidates `orders` query
- `payment_update` → invalidates `payments` query
- `farmer_update` → invalidates `farmers` query
- `stock_update` → invalidates `villages` and `listings` queries
- `sync_update` → invalidates `stats` query

## Responsive Design

- **Desktop**: 3-4 columns layout
- **Tablet**: 2-3 columns layout
- **Mobile**: 1 column with collapsible sidebar

Sidebar collapses on screens below 1024px width.

## Environment Variables Required

```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:3001/api
NEXT_PUBLIC_API_TOKEN=your_token_here
NEXT_PUBLIC_MAPBOX_TOKEN=your_mapbox_token
NEXT_PUBLIC_WS_URL=ws://localhost:3001/ws
```

## Development Workflow

1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env.local` and configure
3. Start dev server: `npm run dev`
4. Open http://localhost:3000
5. Make changes and hot reload happens automatically

## Build & Production

```bash
# Build for production
npm run build

# Start production server
npm start

# Type check
npm run lint
```

## Code Organization

- **Pages** handle data fetching and high-level layout
- **Components** are reusable and self-contained
- **Lib** contains utilities, types, and state
- **Hooks** provide custom logic and side effects

All code is fully typed with TypeScript for safety and IDE support.

## Notes

- All pages use 'use client' directive for interactivity
- TanStack Query handles caching with 60s stale time
- Mapbox token must be set before map renders
- WebSocket connection is optional but recommended for real-time features
- Mobile responsive by default using Tailwind breakpoints
- Form inputs use Tailwind for styling (no external form library)
