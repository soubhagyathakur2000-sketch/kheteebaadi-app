import '@testing-library/jest-dom';
import { expect, afterEach, vi } from 'vitest';
import { cleanup } from '@testing-library/react';

afterEach(() => {
  cleanup();
});

// Mock window.matchMedia for responsive tests
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  disconnect() {}
  observe() {}
  takeRecords() {
    return [];
  }
  unobserve() {}
} as any;

// Mock Mapbox GL
vi.mock('mapbox-gl', () => ({
  default: {
    Map: vi.fn(() => ({
      on: vi.fn(),
      off: vi.fn(),
      addSource: vi.fn(),
      removeSource: vi.fn(),
      addLayer: vi.fn(),
      removeLayer: vi.fn(),
      getSource: vi.fn(),
      getLayer: vi.fn(),
      queryRenderedFeatures: vi.fn(() => []),
      project: vi.fn((coords) => ({ x: 0, y: 0 })),
      unproject: vi.fn((point) => ({ lng: 0, lat: 0 })),
      remove: vi.fn(),
      getCanvas: vi.fn(() => ({
        style: {},
      })),
      fitBounds: vi.fn(),
      jumpTo: vi.fn(),
      panTo: vi.fn(),
      zoomTo: vi.fn(),
    })),
    Marker: vi.fn(() => ({
      addTo: vi.fn(function() { return this; }),
      setLngLat: vi.fn(function() { return this; }),
      setPopup: vi.fn(function() { return this; }),
      remove: vi.fn(),
      getElement: vi.fn(() => document.createElement('div')),
    })),
    Popup: vi.fn(() => ({
      setLngLat: vi.fn(function() { return this; }),
      setHTML: vi.fn(function() { return this; }),
      addTo: vi.fn(function() { return this; }),
      remove: vi.fn(),
    })),
  },
}));

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
};
global.localStorage = localStorageMock as any;

// Mock sessionStorage
const sessionStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
};
global.sessionStorage = sessionStorageMock as any;

// Mock fetch for API tests
if (!global.fetch) {
  global.fetch = vi.fn();
}

// Suppress console errors during tests
const originalError = console.error;
beforeAll(() => {
  console.error = vi.fn((...args) => {
    if (
      typeof args[0] === 'string' &&
      (args[0].includes('Warning: ReactDOM.render') ||
        args[0].includes('Not implemented: HTMLFormElement.prototype.submit'))
    ) {
      return;
    }
    originalError.call(console, ...args);
  });
});

afterAll(() => {
  console.error = originalError;
});
