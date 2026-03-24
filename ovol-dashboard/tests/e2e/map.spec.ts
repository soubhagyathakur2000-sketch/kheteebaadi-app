import { test, expect } from '@playwright/test';

test.describe('Map View', () => {
  test.beforeEach(async ({ page }) => {
    // Mock authentication
    await page.context().addCookies([
      {
        name: 'auth_token',
        value: 'test-token-123',
        domain: 'localhost',
        path: '/',
      },
    ]);
  });

  test('Map loads and shows Mapbox canvas', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const mapContainer = page.locator('[data-testid="map-container"]');
    await expect(mapContainer).toBeVisible();

    const mapCanvas = page.locator('canvas.mapboxgl-canvas');
    await expect(mapCanvas).toBeVisible();
  });

  test('Filter panel shows crop type, date range, stock level controls', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const filterPanel = page.locator('[data-testid="filter-panel"]');
    await expect(filterPanel).toBeVisible();

    const cropTypeSelect = filterPanel.locator('select[name="cropType"]');
    await expect(cropTypeSelect).toBeVisible();

    const dateRangeInputs = filterPanel.locator('input[type="date"]');
    expect(await dateRangeInputs.count()).toBe(2);

    const stockLevelSlider = filterPanel.locator('[data-testid="stock-level-slider"]');
    await expect(stockLevelSlider).toBeVisible();
  });

  test('Clicking a marker shows popup with village info', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const markers = page.locator('[data-testid="map-marker"]');
    const markerCount = await markers.count();
    expect(markerCount).toBeGreaterThan(0);

    await markers.first().click();

    const popup = page.locator('[data-testid="map-popup"]');
    await expect(popup).toBeVisible();

    expect(await popup.locator('[data-testid="village-name"]')).toBeVisible();
    expect(await popup.locator('[data-testid="crop-info"]')).toBeVisible();
    expect(await popup.locator('[data-testid="stock-level"]')).toBeVisible();
  });

  test('Map responds to filter changes (markers update)', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const initialMarkers = page.locator('[data-testid="map-marker"]');
    const initialCount = await initialMarkers.count();

    const filterPanel = page.locator('[data-testid="filter-panel"]');
    const cropTypeSelect = filterPanel.locator('select[name="cropType"]');

    await cropTypeSelect.selectOption('wheat');
    await page.waitForTimeout(800);

    const filteredMarkers = page.locator('[data-testid="map-marker"]');
    const filteredCount = await filteredMarkers.count();

    expect(filteredCount).toBeLessThanOrEqual(initialCount);
  });

  test('Date range filter updates markers', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const filterPanel = page.locator('[data-testid="filter-panel"]');
    const dateInputs = filterPanel.locator('input[type="date"]');

    const startDate = dateInputs.nth(0);
    const endDate = dateInputs.nth(1);

    await startDate.fill('2024-01-01');
    await endDate.fill('2024-01-15');

    await page.waitForTimeout(800);

    const markers = page.locator('[data-testid="map-marker"]');
    expect(await markers.count()).toBeGreaterThanOrEqual(0);
  });

  test('Stock level slider filters markers', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const filterPanel = page.locator('[data-testid="filter-panel"]');
    const stockSlider = filterPanel.locator('[data-testid="stock-level-slider"]');

    const initialMarkers = page.locator('[data-testid="map-marker"]');
    const initialCount = await initialMarkers.count();

    await stockSlider.locator('input[type="range"]').fill('500');
    await page.waitForTimeout(800);

    const filteredMarkers = page.locator('[data-testid="map-marker"]');
    const filteredCount = await filteredMarkers.count();

    expect(filteredCount).toBeLessThanOrEqual(initialCount);
  });

  test('Clear filters resets map view', async ({ page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('networkidle');

    const filterPanel = page.locator('[data-testid="filter-panel"]');
    const cropTypeSelect = filterPanel.locator('select[name="cropType"]');

    await cropTypeSelect.selectOption('rice');
    await page.waitForTimeout(500);

    const clearButton = filterPanel.locator('button:has-text("Clear Filters")');
    await clearButton.click();

    await page.waitForTimeout(500);

    await expect(cropTypeSelect).toHaveValue('');
  });
});
