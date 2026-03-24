# OVOL Web Dashboard

One Village, One Lead (OVOL) Partner Dashboard for Kheteebaadi AgTech Platform.

## Features

- **Dashboard**: Real-time KPIs and order overview
- **Map View**: Geographic visualization of villages with Mapbox GL JS
- **Farmers Management**: Search, filter, and manage farmer networks
- **Order Pipeline**: Kanban-style order management across statuses
- **Inventory**: Track crop listings and stock levels
- **Payments**: Monitor and reconcile payment transactions
- **Analytics**: Revenue trends, crop volumes, and performance metrics
- **Real-time Updates**: WebSocket integration for live data sync

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **UI Library**: React 18
- **State Management**: Zustand
- **Data Fetching**: TanStack Query
- **Styling**: Tailwind CSS
- **Maps**: Mapbox GL JS
- **Charts**: Recharts
- **Icons**: Heroicons

## Prerequisites

- Node.js 18+ and npm/yarn
- Mapbox account with API token
- Backend API running (default: http://localhost:3001)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ovol-dashboard
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables:
```bash
cp .env.example .env.local
```

Edit `.env.local` and set:
- `NEXT_PUBLIC_API_BASE_URL`: Backend API URL
- `NEXT_PUBLIC_MAPBOX_TOKEN`: Your Mapbox API token
- `NEXT_PUBLIC_WS_URL`: WebSocket server URL

## Development

Start the development server:
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
src/
├── app/                    # Next.js App Router
│   ├── dashboard/         # Dashboard pages
│   ├── layout.tsx         # Root layout with providers
│   └── page.tsx          # Redirect to dashboard
├── components/            # Reusable React components
│   ├── Sidebar.tsx       # Navigation sidebar
│   ├── StatsCard.tsx     # KPI card component
│   ├── FarmerTable.tsx   # Farmer data table
│   ├── OrderKanban.tsx   # Order Kanban board
│   ├── MapView.tsx       # Mapbox integration
│   ├── Notifications.tsx # Toast notifications
│   └── providers/        # Context providers
├── lib/
│   ├── api.ts            # API client
│   ├── types.ts          # TypeScript interfaces
│   └── store.ts          # Zustand stores
└── hooks/
    └── useWebSocket.ts   # WebSocket hook
```

## Key Components

### API Client (`src/lib/api.ts`)
- Centralized fetch wrapper with error handling
- Methods for farmers, orders, payments, villages, listings
- Automatic token injection and response validation

### State Management (`src/lib/store.ts`)
- `useSidebarStore`: Sidebar open/closed state
- `useFilterStore`: Global filter state (crop, village, stock level)
- `useMapStore`: Map viewport state
- `useNotificationStore`: Toast notifications
- `useAuthStore`: Authentication state

### Real-time Updates (`src/hooks/useWebSocket.ts`)
- Auto-reconnection with exponential backoff
- Event-based cache invalidation via TanStack Query
- Message type routing (order, payment, farmer, stock, sync)

### Maps (`src/components/MapView.tsx`)
- Mapbox GL clustering
- Color-coded stock health indicators
- Interactive popups on village selection
- Filter panel for crop type and stock levels

## Available Pages

- `/dashboard` - Main dashboard with KPIs and recent orders
- `/dashboard/map` - Geographic village visualization
- `/dashboard/farmers` - Farmer search, filter, and management
- `/dashboard/orders` - Order pipeline with Kanban board
- `/dashboard/inventory` - Crop listings and stock tracking
- `/dashboard/payments` - Payment reconciliation and verification
- `/dashboard/analytics` - Charts and performance metrics

## Styling

Tailwind CSS is configured with custom Kheteebaadi brand colors:
- Primary: `#2E7D32`
- Primary Dark: `#1B5E20`
- Primary Light: `#81C784`
- Accent: `#EF6C00`
- Success: `#43A047`
- Warning: `#FFA726`
- Error: `#E53935`

Use the `kheteebaadi` color namespace:
```tsx
<div className="bg-kheteebaadi-primary text-white">
  Primary Button
</div>
```

## Build & Deploy

Build for production:
```bash
npm run build
npm start
```

## Environment Variables

See `.env.example` for required configuration:

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_API_BASE_URL` | Backend API base URL |
| `NEXT_PUBLIC_API_TOKEN` | Authorization token |
| `NEXT_PUBLIC_MAPBOX_TOKEN` | Mapbox GL JS API token |
| `NEXT_PUBLIC_WS_URL` | WebSocket server URL |

## Performance Optimizations

- TanStack Query caching with 60s stale time
- Image optimization with Next.js Image component
- Code splitting and lazy loading
- Mobile-responsive sidebar with collapsible state
- Optimistic UI updates for mutations

## Error Handling

- API errors are caught and displayed via toast notifications
- WebSocket reconnection with exponential backoff
- Graceful fallbacks for missing data
- Type-safe error responses

## Contributing

1. Create a feature branch
2. Make changes following the existing patterns
3. Test thoroughly
4. Submit a pull request

## License

Proprietary - Kheteebaadi AgTech Platform
