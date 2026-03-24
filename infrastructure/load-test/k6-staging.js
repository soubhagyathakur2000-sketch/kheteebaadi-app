import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const baseURL = __ENV.BASE_URL || 'https://staging.kheteebaadi.app';

// Custom metrics
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');
const dashboardLoadDuration = new Trend('dashboard_load_duration');
const farmerSearchDuration = new Trend('farmer_search_duration');
const orderUpdateDuration = new Trend('order_update_duration');

export const options = {
  stages: [
    { duration: '10s', target: 20 },
    { duration: '30s', target: 100 },
    { duration: '20s', target: 50 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    errors: ['rate<0.1'],
    'login_duration': ['p(95)<3000'],
    'dashboard_load_duration': ['p(95)<2000'],
    'farmer_search_duration': ['p(95)<1500'],
    'order_update_duration': ['p(95)<2000'],
    http_req_duration: ['p(95)<3000'],
  },
};

export default function () {
  // Login
  group('Login', () => {
    const loginPayload = JSON.stringify({
      email: `user${__VU}@example.com`,
      password: 'test-password-123',
    });

    const loginParams = {
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const startTime = new Date();
    const loginRes = http.post(`${baseURL}/api/auth/login`, loginPayload, loginParams);
    const endTime = new Date();
    loginDuration.add(endTime - startTime);

    check(loginRes, {
      'login status is 200': (r) => r.status === 200,
      'login has token': (r) => r.json('token') !== null,
    });

    if (loginRes.status !== 200) {
      errorRate.add(1);
      return;
    }

    const token = loginRes.json('token');
    const authHeaders = {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };

    sleep(1);

    // Dashboard load
    group('Dashboard Load', () => {
      const dashboardStart = new Date();
      const dashboardRes = http.get(`${baseURL}/api/dashboard/stats`, authHeaders);
      const dashboardEnd = new Date();
      dashboardLoadDuration.add(dashboardEnd - dashboardStart);

      check(dashboardRes, {
        'dashboard status is 200': (r) => r.status === 200,
        'dashboard has stats': (r) => r.json('data') !== null,
      });

      if (dashboardRes.status !== 200) {
        errorRate.add(1);
      }
    });

    sleep(0.5);

    // Farmer search
    group('Farmer Search', () => {
      const searchStart = new Date();
      const searchRes = http.get(`${baseURL}/api/farmers?search=test&page=1&limit=10`, authHeaders);
      const searchEnd = new Date();
      farmerSearchDuration.add(searchEnd - searchStart);

      check(searchRes, {
        'farmer search status is 200': (r) => r.status === 200,
        'farmer search has results': (r) => r.json('data.results') !== null,
      });

      if (searchRes.status !== 200) {
        errorRate.add(1);
      }
    });

    sleep(0.5);

    // Get orders
    group('Get Orders', () => {
      const ordersRes = http.get(`${baseURL}/api/orders?status=pending&page=1&limit=20`, authHeaders);

      check(ordersRes, {
        'get orders status is 200': (r) => r.status === 200,
        'orders has data': (r) => r.json('data') !== null,
      });

      if (ordersRes.status !== 200) {
        errorRate.add(1);
        return;
      }

      const orders = ordersRes.json('data.orders');
      if (orders && orders.length > 0) {
        const orderId = orders[0].id;

        // Update order status
        group('Update Order Status', () => {
          const updatePayload = JSON.stringify({
            status: 'confirmed',
          });

          const updateStart = new Date();
          const updateRes = http.patch(`${baseURL}/api/orders/${orderId}`, updatePayload, authHeaders);
          const updateEnd = new Date();
          orderUpdateDuration.add(updateEnd - updateStart);

          check(updateRes, {
            'order update status is 200': (r) => r.status === 200,
            'order updated': (r) => r.json('data.status') === 'confirmed',
          });

          if (updateRes.status !== 200) {
            errorRate.add(1);
          }
        });
      }
    });

    sleep(0.5);

    // Get analytics
    group('Get Analytics', () => {
      const analyticsRes = http.get(
        `${baseURL}/api/analytics?startDate=2024-01-01&endDate=2024-12-31`,
        authHeaders
      );

      check(analyticsRes, {
        'analytics status is 200': (r) => r.status === 200,
        'analytics has data': (r) => r.json('data') !== null,
      });

      if (analyticsRes.status !== 200) {
        errorRate.add(1);
      }
    });

    sleep(0.5);

    // Get payments
    group('Get Payments', () => {
      const paymentsRes = http.get(
        `${baseURL}/api/payments?status=completed&page=1&limit=10`,
        authHeaders
      );

      check(paymentsRes, {
        'payments status is 200': (r) => r.status === 200,
        'payments has data': (r) => r.json('data') !== null,
      });

      if (paymentsRes.status !== 200) {
        errorRate.add(1);
      }
    });

    sleep(1);
  });
}
