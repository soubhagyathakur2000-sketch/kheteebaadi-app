import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { SharedArray } from 'k6/data';

// Test configuration with realistic harvest season traffic patterns
export const options = {
  stages: [
    { duration: '2m', target: 5000 },  // Ramp up to 5000 VUs
    { duration: '10m', target: 5000 }, // Steady state at 5000
    { duration: '5m', target: 7500 },  // Buyer spike
    { duration: '5m', target: 2500 },  // Payment storm
    { duration: '2m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['<1%'],
    'group_duration{group:::auth}': ['p(99)<1000'],
    'group_duration{group:::order}': ['p(99)<800'],
  },
};

// Pre-generated test data
const authTokens = new SharedArray('auth_tokens', function () {
  const tokens = [];
  for (let i = 0; i < 1000; i++) {
    tokens.push({
      phone: `+919${String(i).padStart(9, '0')}`,
      token: `eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyXyR7aX0iLCJpYXQiOjE2MjUwMDAwMDAsImV4cCI6OTk5OTk5OTk5OX0.test_${i}`,
    });
  }
  return tokens;
});

const crops = [
  { name: 'Wheat', unit: 'quintal', basePrice: 2500 },
  { name: 'Rice', unit: 'quintal', basePrice: 3000 },
  { name: 'Maize', unit: 'quintal', basePrice: 1800 },
  { name: 'Cotton', unit: 'kg', basePrice: 5500 },
  { name: 'Sugarcane', unit: 'quintal', basePrice: 450 },
];

export default function () {
  const randomAuth = authTokens[Math.floor(Math.random() * authTokens.length)];
  const randomCrop = crops[Math.floor(Math.random() * crops.length)];

  const headers = {
    Authorization: `Bearer ${randomAuth.token}`,
    'Content-Type': 'application/json',
  };

  // Simulate farmer upload listing
  group('farmer_listing_upload', function () {
    const listingPayload = JSON.stringify({
      crop_name: randomCrop.name,
      quantity: Math.floor(Math.random() * 1000) + 100,
      unit: randomCrop.unit,
      price_per_unit: randomCrop.basePrice + Math.floor(Math.random() * 500),
      description: 'High quality produce from our farm',
      location: `Village ${Math.floor(Math.random() * 100)}`,
    });

    const res = http.post(
      'http://localhost:8000/api/v1/listings/create',
      listingPayload,
      { headers }
    );

    check(res, {
      'listing creation status is 200-201': (r) => r.status >= 200 && r.status < 300,
      'response has listing_id': (r) => r.body.includes('listing_id'),
    });
  });

  sleep(Math.random() * 2);

  // Simulate buyer searching mandi prices
  group('buyer_mandi_search', function () {
    const searchRes = http.get(
      `http://localhost:8000/api/v1/mandi/prices?crop=${randomCrop.name}&limit=20`,
      { headers }
    );

    check(searchRes, {
      'price list fetch status is 200': (r) => r.status === 200,
      'response has prices array': (r) => r.body.includes('prices'),
    });
  });

  sleep(Math.random() * 1.5);

  // Simulate order creation
  group('order_creation', function () {
    const orderPayload = JSON.stringify({
      items: [
        {
          crop_name: randomCrop.name,
          quantity: Math.floor(Math.random() * 500) + 50,
          unit: randomCrop.unit,
          price_per_unit: randomCrop.basePrice + Math.floor(Math.random() * 300),
        },
      ],
      delivery_address: `${Math.floor(Math.random() * 999)} Main Street, Village, District`,
      notes: 'Deliver ASAP',
    });

    const res = http.post(
      'http://localhost:8000/api/v1/orders/create',
      orderPayload,
      { headers }
    );

    check(res, {
      'order creation status is 200-201': (r) => r.status >= 200 && r.status < 300,
      'response has order_id': (r) => r.body.includes('id'),
      'order has pending status': (r) => r.body.includes('pending'),
    });
  });

  sleep(Math.random() * 2);

  // Simulate payment flow
  group('payment_flow', function () {
    const orderId = `order_${Math.random().toString(36).substr(2, 9)}`;

    const paymentRes = http.post(
      'http://localhost:8000/api/v1/payments/create',
      JSON.stringify({
        order_id: orderId,
        amount: Math.floor(Math.random() * 500000) + 50000,
      }),
      { headers }
    );

    check(paymentRes, {
      'payment creation status is 200-201': (r) => r.status >= 200 && r.status < 300,
      'response has payment_id': (r) => r.body.includes('payment_id'),
    });

    sleep(0.5);

    // Verify payment
    const paymentId = `pay_${Math.random().toString(36).substr(2, 9)}`;
    const verifyRes = http.post(
      'http://localhost:8000/api/v1/payments/verify',
      JSON.stringify({
        payment_id: paymentId,
        signature: `test_sig_${Math.random()}`,
      }),
      { headers }
    );

    check(verifyRes, {
      'payment verification accepted': (r) =>
        r.status === 200 || r.status === 201 || r.status === 400,
    });
  });

  sleep(Math.random() * 3);
}
