export interface Farmer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  village: string;
  villageId: string;
  crops: string[];
  status: 'active' | 'inactive' | 'pending';
  lastActive: string;
  joinedDate: string;
  profileImage?: string;
  totalListings: number;
  totalRevenue: number;
}

export interface Village {
  id: string;
  name: string;
  district: string;
  state: string;
  latitude: number;
  longitude: number;
  farmerCount: number;
  totalStock: number;
  avgStockHealth: number;
  lastSyncTime: string;
}

export interface CropListing {
  id: string;
  farmerId: string;
  farmerName: string;
  cropType: string;
  quantity: number;
  unit: string;
  pricePerUnit: number;
  totalValue: number;
  description: string;
  images?: string[];
  createdAt: string;
  expiresAt: string;
  status: 'active' | 'sold' | 'expired';
}

export interface OrderItem {
  id: string;
  listingId: string;
  quantity: number;
  unit: string;
  pricePerUnit: number;
  subtotal: number;
}

export interface Order {
  id: string;
  farmerId: string;
  farmerName: string;
  buyerId: string;
  items: OrderItem[];
  totalAmount: number;
  status: 'pending' | 'confirmed' | 'dispatched' | 'delivered' | 'cancelled';
  paymentStatus: 'unpaid' | 'partial' | 'paid';
  createdAt: string;
  confirmedAt?: string;
  dispatchedAt?: string;
  deliveredAt?: string;
  deliveryAddress?: string;
  notes?: string;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  category: string;
  price: number;
  stock: number;
  sku: string;
  image?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Payment {
  id: string;
  orderId: string;
  farmerId: string;
  farmerName: string;
  amount: number;
  method: 'upi' | 'bank' | 'cash';
  upiRef?: string;
  bankRef?: string;
  status: 'pending' | 'successful' | 'failed';
  createdAt: string;
  processedAt?: string;
  notes?: string;
}

export interface DashboardStats {
  activeFarmers: number;
  farmersChange: number;
  listingsToday: number;
  listingsChange: number;
  revenueThisWeek: number;
  revenueChange: number;
  syncFailures: number;
  syncFailuresChange: number;
  totalOrders: number;
  pendingOrders: number;
  deliveredOrders: number;
}

export interface MapMarker {
  id: string;
  village: string;
  lat: number;
  lng: number;
  farmersCount: number;
  stockLevel: number;
  stockHealthPercent: number;
  color: 'high' | 'medium' | 'low';
}

export interface FilterState {
  cropType: string | null;
  dateRange: {
    start: string | null;
    end: string | null;
  };
  village: string | null;
  stockLevel: 'all' | 'high' | 'medium' | 'low';
}

export interface MapViewport {
  lat: number;
  lng: number;
  zoom: number;
}

export interface WebSocketMessage {
  type: 'order_update' | 'payment_update' | 'farmer_update' | 'stock_update' | 'sync_update';
  data: unknown;
  timestamp: string;
}
