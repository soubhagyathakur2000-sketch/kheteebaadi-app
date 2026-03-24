import {
  Farmer,
  Village,
  Order,
  Payment,
  DashboardStats,
  CropListing,
  Product,
} from './types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3001/api';
const API_TOKEN = process.env.NEXT_PUBLIC_API_TOKEN || '';

interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
}

interface ApiErrorResponse {
  success: false;
  error: string;
  code?: string;
}

class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public code?: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

const headers = {
  'Content-Type': 'application/json',
  ...(API_TOKEN && { Authorization: `Bearer ${API_TOKEN}` }),
};

async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;

  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...headers,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorData = (await response.json().catch(() => ({
        error: 'Unknown error',
      }))) as ApiErrorResponse;
      throw new ApiError(
        errorData.error || `API Error: ${response.status}`,
        response.status,
        errorData.code,
      );
    }

    const data = (await response.json()) as ApiResponse<T>;

    if (!data.success) {
      throw new ApiError(data.error || 'API request failed', 400);
    }

    return data.data;
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    throw new ApiError(
      error instanceof Error ? error.message : 'Unknown error occurred',
      500,
    );
  }
}

export const apiClient = {
  // Farmers
  async getFarmers(params?: {
    page?: number;
    limit?: number;
    village?: string;
    status?: string;
    search?: string;
  }): Promise<{ farmers: Farmer[]; total: number; page: number; limit: number }> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.village) searchParams.append('village', params.village);
    if (params?.status) searchParams.append('status', params.status);
    if (params?.search) searchParams.append('search', params.search);

    const query = searchParams.toString();
    return fetchApi(`/farmers?${query}`);
  },

  async getFarmer(id: string): Promise<Farmer> {
    return fetchApi(`/farmers/${id}`);
  },

  async updateFarmer(
    id: string,
    data: Partial<Farmer>,
  ): Promise<Farmer> {
    return fetchApi(`/farmers/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  // Villages
  async getVillages(): Promise<Village[]> {
    return fetchApi('/villages');
  },

  async getVillage(id: string): Promise<Village> {
    return fetchApi(`/villages/${id}`);
  },

  // Orders
  async getOrders(params?: {
    page?: number;
    limit?: number;
    status?: string;
    farmerId?: string;
  }): Promise<{ orders: Order[]; total: number; page: number; limit: number }> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.status) searchParams.append('status', params.status);
    if (params?.farmerId) searchParams.append('farmerId', params.farmerId);

    const query = searchParams.toString();
    return fetchApi(`/orders?${query}`);
  },

  async getOrder(id: string): Promise<Order> {
    return fetchApi(`/orders/${id}`);
  },

  async createOrder(data: Partial<Order>): Promise<Order> {
    return fetchApi('/orders', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async updateOrderStatus(
    id: string,
    status: Order['status'],
  ): Promise<Order> {
    return fetchApi(`/orders/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  },

  // Payments
  async getPayments(params?: {
    page?: number;
    limit?: number;
    status?: string;
  }): Promise<{ payments: Payment[]; total: number; page: number; limit: number }> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.status) searchParams.append('status', params.status);

    const query = searchParams.toString();
    return fetchApi(`/payments?${query}`);
  },

  async getPayment(id: string): Promise<Payment> {
    return fetchApi(`/payments/${id}`);
  },

  async recordPayment(data: Partial<Payment>): Promise<Payment> {
    return fetchApi('/payments', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async verifyPayment(id: string): Promise<Payment> {
    return fetchApi(`/payments/${id}/verify`, {
      method: 'POST',
    });
  },

  // Crop Listings
  async getListings(params?: {
    page?: number;
    limit?: number;
    farmerId?: string;
    cropType?: string;
  }): Promise<{ listings: CropListing[]; total: number; page: number; limit: number }> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.farmerId) searchParams.append('farmerId', params.farmerId);
    if (params?.cropType) searchParams.append('cropType', params.cropType);

    const query = searchParams.toString();
    return fetchApi(`/listings?${query}`);
  },

  async getListing(id: string): Promise<CropListing> {
    return fetchApi(`/listings/${id}`);
  },

  // Products
  async getProducts(): Promise<Product[]> {
    return fetchApi('/products');
  },

  // Dashboard Stats
  async getStats(): Promise<DashboardStats> {
    return fetchApi('/stats');
  },

  // Health Check
  async healthCheck(): Promise<{ status: string }> {
    return fetchApi('/health');
  },
};

export { ApiError };
