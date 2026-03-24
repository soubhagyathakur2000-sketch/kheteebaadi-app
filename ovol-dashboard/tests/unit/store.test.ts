import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from '../../src/store';

describe('Store - sidebarStore', () => {
  beforeEach(() => {
    const { getState } = useStore;
    getState().resetSidebar?.();
  });

  it('should have initial state with sidebar open', () => {
    const { sidebarStore } = useStore.getState();
    expect(sidebarStore.isOpen).toBe(true);
  });

  it('should toggle sidebar open/closed', () => {
    const state = useStore.getState();
    expect(state.sidebarStore.isOpen).toBe(true);

    state.toggleSidebar();
    expect(state.sidebarStore.isOpen).toBe(false);

    state.toggleSidebar();
    expect(state.sidebarStore.isOpen).toBe(true);
  });
});

describe('Store - filterStore', () => {
  beforeEach(() => {
    const { getState } = useStore;
    getState().clearFilters();
  });

  it('should set individual filter', () => {
    const state = useStore.getState();
    state.setFilter('cropType', 'wheat');

    expect(state.filterStore.cropType).toBe('wheat');
  });

  it('should update filter without affecting others', () => {
    const state = useStore.getState();
    state.setFilter('cropType', 'rice');
    state.setFilter('status', 'active');

    expect(state.filterStore.cropType).toBe('rice');
    expect(state.filterStore.status).toBe('active');
  });

  it('should clear all filters', () => {
    const state = useStore.getState();
    state.setFilter('cropType', 'wheat');
    state.setFilter('status', 'active');
    state.setFilter('stockLevel', 500);

    state.clearFilters();

    expect(state.filterStore.cropType).toBeNull();
    expect(state.filterStore.status).toBeNull();
    expect(state.filterStore.stockLevel).toBeNull();
  });

  it('should combine multiple filters', () => {
    const state = useStore.getState();
    const filters = {
      cropType: 'rice',
      status: 'pending',
      dateFrom: '2024-01-01',
      dateTo: '2024-12-31',
    };

    Object.entries(filters).forEach(([key, value]) => {
      state.setFilter(key as keyof typeof filters, value as any);
    });

    expect(state.filterStore).toMatchObject(filters);
  });
});

describe('Store - mapStore', () => {
  it('should initialize with default viewport', () => {
    const state = useStore.getState();
    expect(state.mapStore.viewport).toBeDefined();
    expect(state.mapStore.viewport.latitude).toBeDefined();
    expect(state.mapStore.viewport.longitude).toBeDefined();
    expect(state.mapStore.viewport.zoom).toBeDefined();
  });

  it('should update viewport coordinates', () => {
    const state = useStore.getState();
    state.setViewport({ latitude: 28.6139, longitude: 77.209, zoom: 12 });

    expect(state.mapStore.viewport.latitude).toBe(28.6139);
    expect(state.mapStore.viewport.longitude).toBe(77.209);
    expect(state.mapStore.viewport.zoom).toBe(12);
  });

  it('should update zoom level independently', () => {
    const state = useStore.getState();
    const initialLat = state.mapStore.viewport.latitude;
    const initialLng = state.mapStore.viewport.longitude;

    state.setViewport({ zoom: 15 });

    expect(state.mapStore.viewport.latitude).toBe(initialLat);
    expect(state.mapStore.viewport.longitude).toBe(initialLng);
    expect(state.mapStore.viewport.zoom).toBe(15);
  });
});
