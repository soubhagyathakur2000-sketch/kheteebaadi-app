import { test, expect } from '@playwright/test';

test.describe('Dashboard Page', () => {
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

  test('Login page redirects to dashboard', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', 'test@example.com');
    await page.fill('input[type="password"]', 'password123');
    await page.click('button:has-text("Sign In")');

    await page.waitForURL('/dashboard');
    expect(page.url()).toContain('/dashboard');
  });

  test('Dashboard shows 4 KPI stat cards', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const kpiCards = page.locator('[data-testid="kpi-card"]');
    const count = await kpiCards.count();

    expect(count).toBe(4);
    expect(await kpiCards.nth(0).locator('text=Total Orders')).toBeVisible();
    expect(await kpiCards.nth(1).locator('text=Revenue')).toBeVisible();
    expect(await kpiCards.nth(2).locator('text=Active Farmers')).toBeVisible();
    expect(await kpiCards.nth(3).locator('text=Pending Deliveries')).toBeVisible();
  });

  test('Navigate to map view, verify map container renders', async ({ page }) => {
    await page.goto('/dashboard');
    await page.click('a[href="/dashboard/map"]');

    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/map');

    const mapContainer = page.locator('[data-testid="map-container"]');
    await expect(mapContainer).toBeVisible();
  });

  test('Navigate to farmers page, search for a farmer, verify table updates', async ({ page }) => {
    await page.goto('/dashboard');
    await page.click('a[href="/dashboard/farmers"]');

    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/farmers');

    const searchInput = page.locator('input[placeholder="Search farmers..."]');
    await searchInput.fill('Rajesh Kumar');

    await page.waitForTimeout(500);
    const tableRows = page.locator('tbody tr');
    const count = await tableRows.count();

    expect(count).toBeGreaterThan(0);
    expect(await tableRows.first().locator('text=Rajesh Kumar')).toBeVisible();
  });

  test('Navigate to orders page, verify Kanban columns render', async ({ page }) => {
    await page.goto('/dashboard');
    await page.click('a[href="/dashboard/orders"]');

    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/orders');

    const columns = page.locator('[data-testid="kanban-column"]');
    expect(await columns.count()).toBe(4);

    const columnHeaders = ['Pending', 'Confirmed', 'Dispatched', 'Delivered'];
    for (const header of columnHeaders) {
      await expect(page.locator(`text=${header}`)).toBeVisible();
    }
  });

  test('Navigate to payments page, filter by status "failed", verify table filters', async ({ page }) => {
    await page.goto('/dashboard');
    await page.click('a[href="/dashboard/payments"]');

    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/payments');

    const statusFilter = page.locator('select[name="status"]');
    await statusFilter.selectOption('failed');

    await page.waitForTimeout(500);
    const tableRows = page.locator('tbody tr');
    const rows = await tableRows.all();

    for (const row of rows) {
      const statusCell = row.locator('[data-testid="status-cell"]');
      expect(await statusCell.textContent()).toContain('Failed');
    }
  });

  test('Navigate to analytics page, verify chart containers render', async ({ page }) => {
    await page.goto('/dashboard');
    await page.click('a[href="/dashboard/analytics"]');

    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/analytics');

    const charts = page.locator('[data-testid="chart-container"]');
    expect(await charts.count()).toBeGreaterThan(0);

    await expect(charts.first()).toBeVisible();
  });

  test('Sidebar collapses and expands on toggle click', async ({ page }) => {
    await page.goto('/dashboard');

    const sidebar = page.locator('[data-testid="sidebar"]');
    const toggleButton = page.locator('[data-testid="sidebar-toggle"]');

    await expect(sidebar).toHaveAttribute('data-collapsed', 'false');

    await toggleButton.click();
    await expect(sidebar).toHaveAttribute('data-collapsed', 'true');

    await toggleButton.click();
    await expect(sidebar).toHaveAttribute('data-collapsed', 'false');
  });

  test('Mobile viewport (375x812) hides sidebar by default', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/dashboard');

    const sidebar = page.locator('[data-testid="sidebar"]');
    await expect(sidebar).toHaveAttribute('data-collapsed', 'true');

    const toggleButton = page.locator('[data-testid="sidebar-toggle"]');
    await toggleButton.click();

    await expect(sidebar).toHaveAttribute('data-collapsed', 'false');
  });
});
