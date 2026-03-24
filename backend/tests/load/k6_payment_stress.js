import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { SharedArray } from 'k6/data';
import { Counter, Trend, Gauge } from 'k6/metrics';

// Custom metrics
const duplicatePayments = new Counter('duplicate_payments');
const paymentLatency = new Trend('payment_latency');
const concurrentPayments = new Gauge('concurrent_payments');

// Test configuration focused on payment endpoints under stress
export const options = {
  stages: [
    { duration: '1m', target: 500 },   // Ramp to 500 VUs
    { duration: '5m', target: 500 },   // Stress test for 5 minutes
    { duration: '1m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1500', 'p(99)<2000'],
    http_req_failed: ['<1%'],
    'duplicate_payments': ['<5'],
    'payment_latency': ['p(99)<2000'],
  },
  maxRedirects: 0,
};

// Pre-generated payment data
const paymentData = new SharedArray('payment_data', function () {
  const data = [];
  for (let i = 0; i < 10000; i++) {
    data.push({
      orderId: `order_${i}`,
      amount: Math.floor(Math.random() * 500000) + 50000,
      customerId: `cust_${i % 500}`,
      paymentId: `pay_init_${i}`,
    });
  }
  return data;
});

// Store for tracking processed payments
const processedPayments = new SharedArray('processed_payments', function () {
  return [];
});

export default function () {
  const paymentRecord = paymentData[Math.floor(Math.random() * paymentData.length)];

  const headers = {
    'Content-Type': 'application/json',
    'X-Request-ID': `stress_test_${Date.now()}_${Math.random()}`,
  };

  // Stress test: Multiple VUs making concurrent payment initiation
  group('concurrent_payment_creation', function () {
    const paymentPayload = JSON.stringify({
      order_id: paymentRecord.orderId,
      amount: paymentRecord.amount,
      currency: 'INR',
      customer_id: paymentRecord.customerId,
      description: 'Payment for order',
    });

    concurrentPayments.add(1);

    const startTime = Date.now();
    const res = http.post(
      'http://localhost:8000/api/v1/payments/create',
      paymentPayload,
      { headers }
    );
    const latency = Date.now() - startTime;

    paymentLatency.add(latency);
    concurrentPayments.add(-1);

    check(res, {
      'payment creation succeeded': (r) => r.status >= 200 && r.status < 300,
      'response contains payment_id': (r) => r.body.includes('payment_id'),
      'response time acceptable': (r) => latency < 1500,
      'no server errors': (r) => r.status < 500,
    });

    if (res.status === 200) {
      try {
        const responseData = JSON.parse(res.body);
        if (responseData.payment_id) {
          processedPayments.push(responseData.payment_id);
        }
      } catch (e) {
        // Parse error, continue
      }
    }
  });

  sleep(0.1);

  // Stress test: Multiple webhook handlers with same payment_id
  group('concurrent_webhook_handling', function () {
    const paymentId = paymentRecord.paymentId;

    const webhookPayload = JSON.stringify({
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: paymentId,
            amount: paymentRecord.amount,
            currency: 'INR',
            status: 'captured',
            order_id: paymentRecord.orderId,
            notes: {},
          },
        },
      },
    });

    // Simulate multiple concurrent webhook deliveries
    for (let i = 0; i < 5; i++) {
      const res = http.post(
        'http://localhost:8000/api/v1/webhooks/razorpay',
        webhookPayload,
        {
          headers: {
            ...headers,
            'X-Razorpay-Signature': `webhook_sig_${paymentId}_${i}`,
          },
        }
      );

      check(res, {
        'webhook processed': (r) => r.status >= 200 && r.status < 300,
        'no duplicate processing error': (r) => !r.body.includes('duplicate'),
        'webhook accepted': (r) => r.status !== 409,
      });

      if (res.body.includes('duplicate')) {
        duplicatePayments.add(1);
      }
    }
  });

  sleep(Math.random() * 0.5);

  // Verify payment status to ensure no duplicates
  group('payment_status_verification', function () {
    const verifyRes = http.get(
      `http://localhost:8000/api/v1/payments/status/${paymentRecord.paymentId}`,
      { headers }
    );

    check(verifyRes, {
      'payment status fetch succeeded': (r) => r.status >= 200 && r.status < 300,
      'payment data returned': (r) => r.body.length > 0,
    });
  });

  sleep(Math.random() * 1);
}
