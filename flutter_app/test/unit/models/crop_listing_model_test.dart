import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/features/crop_listing/data/models/crop_listing_model.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('CropListingModel', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('should create instance from complete JSON data', () {
        final json = {
          'id': 'listing_1',
          'user_id': 'user_123',
          'crop_type': 'Wheat',
          'crop_name': 'Indian Wheat',
          'quantity_quintals': 100.5,
          'expected_price_per_quintal': 2500.0,
          'description': 'High quality wheat',
          'image_paths': ['path1.jpg', 'path2.jpg'],
          'status': 'draft',
          'village_id': 'village_123',
          'synced': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = CropListingModel.fromJson(json);

        expect(model.id, 'listing_1');
        expect(model.userId, 'user_123');
        expect(model.cropType, 'Wheat');
        expect(model.cropName, 'Indian Wheat');
        expect(model.quantityQuintals, 100.5);
        expect(model.expectedPricePerQuintal, 2500.0);
        expect(model.description, 'High quality wheat');
        expect(model.imagePaths, ['path1.jpg', 'path2.jpg']);
        expect(model.status, CropListingStatus.draft);
        expect(model.villageId, 'village_123');
        expect(model.synced, false);
      });

      test('should use defaults for null optional fields', () {
        final json = {
          'id': 'listing_1',
          'user_id': 'user_123',
          'crop_type': 'Rice',
          'crop_name': 'Basmati Rice',
          'quantity_quintals': 50.0,
          'image_paths': [],
          'status': 'draft',
          'village_id': 'village_123',
          'synced': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = CropListingModel.fromJson(json);

        expect(model.expectedPricePerQuintal, null);
        expect(model.description, null);
        expect(model.imagePaths, []);
      });

      test('should handle missing optional keys gracefully', () {
        final json = {
          'id': 'listing_1',
          'user_id': 'user_123',
          'crop_type': 'Corn',
          'crop_name': 'Maize',
          'quantity_quintals': 75.0,
          'image_paths': [],
          'status': 'synced',
          'village_id': 'village_456',
          'synced': true,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        expect(() => CropListingModel.fromJson(json), returnsNormally);
        final model = CropListingModel.fromJson(json);
        expect(model.id, isNotEmpty);
      });
    });

    group('toJson and round-trip', () {
      test('should produce JSON that converts back to identical object', () {
        final original = CropListingModel(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test Wheat',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: 2500.0,
          description: 'Test description',
          imagePaths: ['path1.jpg', 'path2.jpg'],
          status: CropListingStatus.pendingSync,
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = CropListingModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.cropType, original.cropType);
        expect(restored.cropName, original.cropName);
        expect(restored.quantityQuintals, original.quantityQuintals);
        expect(restored.expectedPricePerQuintal, original.expectedPricePerQuintal);
        expect(restored.description, original.description);
        expect(restored.imagePaths, original.imagePaths);
        expect(restored.status, original.status);
        expect(restored.villageId, original.villageId);
        expect(restored.synced, original.synced);
      });
    });

    group('CropListingStatus.fromValue', () {
      test('should parse "draft" status correctly', () {
        expect(CropListingStatus.fromValue('draft'), CropListingStatus.draft);
      });

      test('should parse "pending_sync" status correctly', () {
        expect(
          CropListingStatus.fromValue('pending_sync'),
          CropListingStatus.pendingSync,
        );
      });

      test('should parse "synced" status correctly', () {
        expect(CropListingStatus.fromValue('synced'), CropListingStatus.synced);
      });

      test('should parse "sold" status correctly', () {
        expect(CropListingStatus.fromValue('sold'), CropListingStatus.sold);
      });

      test('should default to draft for unknown status', () {
        expect(
          CropListingStatus.fromValue('unknown_status'),
          CropListingStatus.draft,
        );
        expect(
          CropListingStatus.fromValue(''),
          CropListingStatus.draft,
        );
      });

      test('should be case-insensitive', () {
        expect(
          CropListingStatus.fromValue('DRAFT'),
          CropListingStatus.draft,
        );
        expect(
          CropListingStatus.fromValue('Pending_Sync'),
          CropListingStatus.pendingSync,
        );
      });
    });

    group('fromDriftEntity', () {
      test('should parse valid JSON image paths', () {
        final entity = CropListingEntity(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test Wheat',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: 2500.0,
          description: 'Test',
          imagePathsJson: jsonEncode(['path1.jpg', 'path2.jpg']),
          status: 'draft',
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final model = CropListingModel.fromDriftEntity(entity);

        expect(model.imagePaths, ['path1.jpg', 'path2.jpg']);
      });

      test('should handle empty image paths JSON', () {
        final entity = CropListingEntity(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test Wheat',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: null,
          description: null,
          imagePathsJson: '[]',
          status: 'draft',
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final model = CropListingModel.fromDriftEntity(entity);

        expect(model.imagePaths, []);
      });

      test('should return empty list for malformed image JSON without crashing', () {
        final entity = CropListingEntity(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test Wheat',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: null,
          description: null,
          imagePathsJson: 'invalid{json}format',
          status: 'draft',
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(
          () => CropListingModel.fromDriftEntity(entity),
          returnsNormally,
        );
        final model = CropListingModel.fromDriftEntity(entity);
        expect(model.imagePaths, []);
      });

      test('should convert status using CropListingStatus.fromValue', () {
        final entity = CropListingEntity(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Rice',
          cropName: 'Basmati',
          quantityQuintals: 50.0,
          expectedPricePerQuintal: null,
          description: null,
          imagePathsJson: '[]',
          status: 'synced',
          villageId: 'village_456',
          synced: true,
          createdAt: now,
          updatedAt: now,
        );

        final model = CropListingModel.fromDriftEntity(entity);

        expect(model.status, CropListingStatus.synced);
      });
    });

    group('toCompanion', () {
      test('should produce CropListingsCompanion with all required fields', () {
        final model = CropListingModel(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test Wheat',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: 2500.0,
          description: 'High quality',
          imagePaths: ['path1.jpg'],
          status: CropListingStatus.synced,
          villageId: 'village_123',
          synced: true,
          createdAt: now,
          updatedAt: now,
        );

        final companion = model.toCompanion();

        expect(companion.id.present, true);
        expect(companion.userId.present, true);
        expect(companion.cropType.present, true);
        expect(companion.cropName.present, true);
        expect(companion.quantityQuintals.present, true);
        expect(companion.expectedPricePerQuintal.present, true);
        expect(companion.description.present, true);
        expect(companion.imagePathsJson.present, true);
        expect(companion.status.present, true);
        expect(companion.villageId.present, true);
        expect(companion.synced.present, true);
        expect(companion.createdAt.present, true);
        expect(companion.updatedAt.present, true);
      });

      test('should encode image paths as JSON in companion', () {
        final imagePaths = ['path1.jpg', 'path2.jpg', 'path3.jpg'];
        final model = CropListingModel(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: null,
          description: null,
          imagePaths: imagePaths,
          status: CropListingStatus.draft,
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final companion = model.toCompanion();
        final encodedJson = companion.imagePathsJson.value;

        expect(
          jsonDecode(encodedJson),
          imagePaths,
        );
      });

      test('should handle null optional fields in companion', () {
        final model = CropListingModel(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Rice',
          cropName: 'Basmati',
          quantityQuintals: 50.0,
          expectedPricePerQuintal: null,
          description: null,
          imagePaths: [],
          status: CropListingStatus.draft,
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final companion = model.toCompanion();

        expect(companion.expectedPricePerQuintal.present, false);
        expect(companion.description.present, false);
      });

      test('should set status as string value in companion', () {
        final model = CropListingModel(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Test',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: null,
          description: null,
          imagePaths: [],
          status: CropListingStatus.pendingSync,
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final companion = model.toCompanion();

        expect(companion.status.value, 'pending_sync');
      });
    });

    group('copyWith', () {
      test('should create new instance with updated fields', () {
        final original = CropListingModel(
          id: 'listing_1',
          userId: 'user_123',
          cropType: 'Wheat',
          cropName: 'Original',
          quantityQuintals: 100.0,
          expectedPricePerQuintal: 2500.0,
          description: 'Original description',
          imagePaths: ['path1.jpg'],
          status: CropListingStatus.draft,
          villageId: 'village_123',
          synced: false,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          cropName: 'Updated',
          status: CropListingStatus.synced,
        );

        expect(updated.cropName, 'Updated');
        expect(updated.status, CropListingStatus.synced);
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
      });
    });
  });
}
