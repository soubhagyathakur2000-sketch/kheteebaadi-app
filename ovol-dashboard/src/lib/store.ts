import { create } from 'zustand';
import { FilterState, MapViewport } from './types';

interface SidebarStore {
  isOpen: boolean;
  toggle: () => void;
  setOpen: (isOpen: boolean) => void;
}

export const useSidebarStore = create<SidebarStore>((set) => ({
  isOpen: true,
  toggle: () => set((state) => ({ isOpen: !state.isOpen })),
  setOpen: (isOpen: boolean) => set({ isOpen }),
}));

interface FilterStoreState extends FilterState {
  setFilter: (key: keyof FilterState, value: unknown) => void;
  setDateRange: (start: string | null, end: string | null) => void;
  clearFilters: () => void;
}

const initialFilterState: FilterState = {
  cropType: null,
  dateRange: {
    start: null,
    end: null,
  },
  village: null,
  stockLevel: 'all',
};

export const useFilterStore = create<FilterStoreState>((set) => ({
  ...initialFilterState,
  setFilter: (key, value) =>
    set((state) => {
      if (key === 'dateRange' && typeof value === 'object') {
        return {
          dateRange: value as FilterState['dateRange'],
        };
      }
      return {
        [key]: value,
      };
    }),
  setDateRange: (start, end) =>
    set({
      dateRange: {
        start,
        end,
      },
    }),
  clearFilters: () => set(initialFilterState),
}));

interface MapStoreState {
  viewport: MapViewport;
  setViewport: (viewport: Partial<MapViewport>) => void;
}

const initialViewport: MapViewport = {
  lat: 20.5937,
  lng: 78.9629,
  zoom: 5,
};

export const useMapStore = create<MapStoreState>((set) => ({
  viewport: initialViewport,
  setViewport: (viewport) =>
    set((state) => ({
      viewport: {
        ...state.viewport,
        ...viewport,
      },
    })),
}));

interface NotificationStore {
  notifications: Array<{
    id: string;
    type: 'success' | 'error' | 'info' | 'warning';
    message: string;
    timestamp: number;
  }>;
  addNotification: (
    message: string,
    type?: 'success' | 'error' | 'info' | 'warning',
  ) => void;
  removeNotification: (id: string) => void;
  clearNotifications: () => void;
}

export const useNotificationStore = create<NotificationStore>((set) => ({
  notifications: [],
  addNotification: (message, type = 'info') =>
    set((state) => ({
      notifications: [
        ...state.notifications,
        {
          id: `${Date.now()}-${Math.random()}`,
          type,
          message,
          timestamp: Date.now(),
        },
      ],
    })),
  removeNotification: (id) =>
    set((state) => ({
      notifications: state.notifications.filter((n) => n.id !== id),
    })),
  clearNotifications: () => set({ notifications: [] }),
}));

interface AuthStore {
  token: string | null;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
  } | null;
  setAuth: (token: string, user: AuthStore['user']) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthStore>((set) => ({
  token: null,
  user: null,
  setAuth: (token, user) => set({ token, user }),
  clearAuth: () => set({ token: null, user: null }),
}));
