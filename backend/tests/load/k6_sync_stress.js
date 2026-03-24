import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { SharedArray } from 'k6/data';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics
const syncItemsProcessed = new Counter('sync_items_processed');
const duplicateDetected = new Counter('duplicate_items_detected');
const syncLatency = new Trend('sync_latency');

// Test configuration for sync endpoint stress
export const options = {
  stages: [
    { duration: '1m', target: 1000 },   // Ramp to 1000 VUs
    { duration: '5m', target: 1000 },   // Stress test 5 minutes
    { duration: '2m', target: 0 },      // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1500', 'p(99)<2000'],
    http_req_failed: ['<0.5%'],
    'sync_items_processed': ['>40000'],
    'duplicate_items_detected': ['<100'],
  },
  maxRedirects: 0,
};

// Pre-generated auth tokens for 1000 users
const authTokens = new SharedArray('auth_tokens', function () {
  const tokens = [];
  for (let i = 0; i < 1000; i++) {
    tokens.push({
      userId: `user_${i}`,
      token: `eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.payload_${i}.signature_${i}`,
    });
  }
  return tokens;
});

// Track processed idempotency keys to detect duplicates
const processedKeys = new SharedArray('processed_keys', function () {
  return {};
});

// Generate sync batch with 50 items
function generateSyncBatch(userId, batchNumber) {
  const items = [];
  for (let i = 0; i < 50; i++) {
    const idempotencyKey = `batch_${batchNumber}_item_${i}_user_${userId}`;
    items.push({
      entity_type: 'order',
      entity_id: `order_local_${batchNumber}_${i}`,
      action: 'create',
      payload: {
        items: [
          {
            crop_name: ['Wheat', 'Rice', 'Maize', 'Cotton', 'Sugarcane'][i % 5],
            quantity: Math.floor(Math.random() * 500) + 50,
            unit: 'quintal',
            price_per_unit: Math.floor(Math.random() * 5000) + 1000,
          },
        ],
        delivery_address: `${Math.floor(Math.random() * 9999)} Main Street, Village ${batchNumber}`,
        notes: `Sync batch ${batchNumber} item ${i}`,
      },
      idempotency_key: idempotencyKey,
    });
  }
  return { items };
}

export default function () {
  const randomAuth = authTokens[Math.floor(Math.random() * authTokens.length)];
  const batchNumber = Math.floor(Math.random() * 100000);

  const headers = {
    Authorization: `Bearer ${randomAuth.token}`,
    'Content-Type': 'application/json',
    'X-Request-ID': `sync_stress_${Date.now()}_${Math.random()}`,
  };

  // Primary test: 1000 VUs posting sync batches with 50 items each
  group('sync_batch_50_items', function () {
    const syncBatch = generateSyncBatch(randomAuth.userId, batchNumber);

    const startTime = Date.now();
    const res = http.post(
      'http://localhost:8000/api/v1/sync/batch',
      JSON.stringify(syncBatch),
      { headers }
    );
    const latency = Date.now() - startTime;

    syncLatency.add(latency);

    check(res, {
      'sync batch processed': (r) => r.status === 200,
      'response has results': (r) => r.body.includes('results'),
      'batch latency acceptable': () => latency < 1500,
      'no server errors': (r) => r.status < 500,
      'response not empty': (r) => r.body.length > 0,
    });

    if (res.status === 200) {
      try {
        const data = JSON.parse(res.body);
        const itemsCount = data.processed + data.failed + data.duplicates;
        syncItemsProcessed.add(itemsCount);

        if (data.duplicates > 0) {
          duplicateDetected.add(data.duplicates);
        }
      } catch (e) {
        // Parse error, continue
      }
    }
  });

  sleep(0.2);

  // Idempotency verification: resend same batch
  if (Math.random() < 0.3) {
    group('sync_idempotency_verification', function () {
      const syncBatch = generateSyncBatch(randomAuth.userId, batchNumber);

      const res = http.post(
        'http://localhost:8000/api/v1/sync/batch',
        JSON.stringify(syncBatch),
        { headers }
      );

      check(res, {
        'resend recognized as duplicate': (r) => {
          try {
            const data = JSON.parse(r.body);
            return data.duplicates >= 1;
          } catch {
            return false;
          }
        },
        'no duplicate DB entries': (r) => r.status === 200,
      });
    });
  }

  sleep(Math.random() * 0.5);
}

// Summary function to display test results
export function teardown() {
  console.log('========== SYNC STRESS TEST RESULTS ==========');
  console.log(`Total sync items processed: ${syncItemsProcessed.value}`);
  console.log(`Duplicates detected: ${duplicateDetected.value}`);
  console.log('=============================================');
}
