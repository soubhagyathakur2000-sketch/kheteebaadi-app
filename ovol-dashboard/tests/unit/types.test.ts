import { describe, it, expect } from 'vitest';
import type { Farmer, Order, Payment, PaymentStatus } from '../../src/types';

describe('Type Validation', () => {
  describe('Farmer interface', () => {
    it('should satisfy Farmer interface with valid object', () => {
      const farmer: Farmer = {
        id: 'farmer-1',
        name: 'Rajesh Kumar',
        email: 'rajesh@example.com',
        phone: '+91-9876543210',
        village: 'Village A',
        district: 'Punjab',
        state: 'Punjab',
        crops: ['wheat', 'rice'],
        totalArea: 10.5,
        registeredDate: new Date('2023-01-15'),
      };

      expect(farmer.id).toBe('farmer-1');
      expect(farmer.name).toBe('Rajesh Kumar');
      expect(farmer.crops).toContain('wheat');
      expect(farmer.totalArea).toBe(10.5);
    });

    it('should have all required Farmer fields', () => {
      const farmer: Farmer = {
        id: 'f1',
        name: 'Test Farmer',
        email: 'test@example.com',
        phone: '+91-1234567890',
        village: 'Test Village',
        district: 'Test District',
        state: 'Test State',
        crops: [],
        totalArea: 5,
        registeredDate: new Date(),
      };

      const requiredFields = ['id', 'name', 'email', 'phone', 'village', 'district', 'state', 'crops', 'totalArea', 'registeredDate'];
      requiredFields.forEach(field => {
        expect(farmer).toHaveProperty(field);
      });
    });
  });

  describe('Order interface', () => {
    it('should satisfy Order interface with all fields', () => {
      const order: Order = {
        id: 'order-1',
        farmerId: 'farmer-1',
        buyerId: 'buyer-1',
        cropType: 'wheat',
        quantity: 100,
        unit: 'kg',
        pricePerUnit: 2500,
        totalPrice: 250000,
        status: 'confirmed',
        createdAt: new Date('2024-01-15'),
        updatedAt: new Date('2024-01-16'),
        deliveryDate: new Date('2024-01-20'),
      };

      expect(order.id).toBe('order-1');
      expect(order.cropType).toBe('wheat');
      expect(order.quantity).toBe(100);
      expect(order.status).toBe('confirmed');
    });

    it('should have all required Order fields', () => {
      const order: Order = {
        id: 'o1',
        farmerId: 'f1',
        buyerId: 'b1',
        cropType: 'rice',
        quantity: 50,
        unit: 'kg',
        pricePerUnit: 3000,
        totalPrice: 150000,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
        deliveryDate: new Date(),
      };

      const requiredFields = [
        'id',
        'farmerId',
        'buyerId',
        'cropType',
        'quantity',
        'unit',
        'pricePerUnit',
        'totalPrice',
        'status',
        'createdAt',
        'updatedAt',
        'deliveryDate',
      ];

      requiredFields.forEach(field => {
        expect(order).toHaveProperty(field);
      });
    });

    it('should validate order status values', () => {
      const validStatuses: Array<Order['status']> = ['pending', 'confirmed', 'dispatched', 'delivered'];

      validStatuses.forEach(status => {
        const order: Order = {
          id: 'o1',
          farmerId: 'f1',
          buyerId: 'b1',
          cropType: 'wheat',
          quantity: 100,
          unit: 'kg',
          pricePerUnit: 2500,
          totalPrice: 250000,
          status,
          createdAt: new Date(),
          updatedAt: new Date(),
          deliveryDate: new Date(),
        };
        expect(order.status).toBe(status);
      });
    });
  });

  describe('Payment interface', () => {
    it('should satisfy Payment interface with valid object', () => {
      const payment: Payment = {
        id: 'payment-1',
        orderId: 'order-1',
        farmerId: 'farmer-1',
        amount: 250000,
        status: 'completed',
        paymentMethod: 'bank_transfer',
        transactionId: 'txn-12345',
        createdAt: new Date('2024-01-15'),
        completedAt: new Date('2024-01-16'),
      };

      expect(payment.id).toBe('payment-1');
      expect(payment.amount).toBe(250000);
      expect(payment.status).toBe('completed');
    });

    it('should have all required Payment fields', () => {
      const payment: Payment = {
        id: 'p1',
        orderId: 'o1',
        farmerId: 'f1',
        amount: 100000,
        status: 'pending',
        paymentMethod: 'upi',
        transactionId: 'txn-1',
        createdAt: new Date(),
        completedAt: undefined,
      };

      expect(payment).toHaveProperty('id');
      expect(payment).toHaveProperty('orderId');
      expect(payment).toHaveProperty('farmerId');
      expect(payment).toHaveProperty('amount');
      expect(payment).toHaveProperty('status');
      expect(payment).toHaveProperty('paymentMethod');
    });
  });

  describe('PaymentStatus enum', () => {
    it('should have correct payment status values', () => {
      const statuses: PaymentStatus[] = ['pending', 'completed', 'failed', 'refunded'];

      statuses.forEach(status => {
        expect(['pending', 'completed', 'failed', 'refunded']).toContain(status);
      });
    });

    it('should validate payment status in Payment object', () => {
      const validStatuses: PaymentStatus[] = ['pending', 'completed', 'failed', 'refunded'];

      validStatuses.forEach(status => {
        const payment: Payment = {
          id: 'p1',
          orderId: 'o1',
          farmerId: 'f1',
          amount: 50000,
          status,
          paymentMethod: 'card',
          transactionId: 'txn-1',
          createdAt: new Date(),
        };
        expect(payment.status).toBe(status);
      });
    });
  });
});
