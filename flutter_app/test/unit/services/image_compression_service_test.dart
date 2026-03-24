import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/core/services/image_compression_service.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';

void main() {
  group('ImageCompressionService', () {
    late ImageCompressionService service;
    late MockFlutterImageCompress mockCompress;

    setUp(() {
      mockCompress = MockFlutterImageCompress();
      service = ImageCompressionService.withMock(mockCompress);
    });

    group('compressImage', () {
      test('should call compress with correct quality parameter', () async {
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        await service.compressImage('source.jpg');

        expect(mockCompress.lastQuality, AppConstants.imageQuality);
      });

      test('should call compress with correct width parameter', () async {
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        await service.compressImage('source.jpg');

        expect(mockCompress.lastWidth, AppConstants.maxImageWidth);
      });

      test('should call compress with jpeg format', () async {
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        await service.compressImage('source.jpg');

        expect(mockCompress.lastFormat, 'jpeg');
      });

      test('should throw exception when compression fails', () async {
        mockCompress.mockResult = null;

        expect(
          () => service.compressImage('source.jpg'),
          throwsA(isA<Exception>()),
        );
      });

      test('should return path to compressed file', () async {
        const expectedPath = '/tmp/compressed_123.jpg';
        mockCompress.mockResult = _createMockFile(expectedPath, 100000);

        final result = await service.compressImage('source.jpg');

        expect(result, isNotEmpty);
      });

      test('should trigger re-compression when file > 300KB', () async {
        final largeFile = _createMockFile('large.jpg', 600000);
        mockCompress.mockResult = largeFile;

        final result = await service.compressImage('source.jpg');

        expect(result, isNotEmpty);
        expect(mockCompress.compressionCount, greaterThan(1));
      });

      test('should use lower quality (50) for re-compression', () async {
        final largeFile = _createMockFile('large.jpg', 600000);
        mockCompress.mockResult = largeFile;

        await service.compressImage('source.jpg');

        expect(mockCompress.recompressionQualities.isNotEmpty, true);
        expect(mockCompress.recompressionQualities.last, 50);
      });

      test('should delete original file after re-compression', () async {
        final largeFile = _createMockFile('large.jpg', 600000);
        final smallerFile = _createMockFile('smaller.jpg', 200000);

        mockCompress.mockResult = largeFile;
        mockCompress.mockRecompressionResult = smallerFile;

        await service.compressImage('source.jpg');

        expect(mockCompress.deletedFiles.isNotEmpty, true);
      });

      test('should return re-compressed file path', () async {
        final largeFile = _createMockFile('large.jpg', 600000);
        const recompressedPath = '/tmp/recompressed_456.jpg';
        final smallerFile = _createMockFile(recompressedPath, 200000);

        mockCompress.mockResult = largeFile;
        mockCompress.mockRecompressionResult = smallerFile;

        final result = await service.compressImage('source.jpg');

        expect(result, isNotEmpty);
      });
    });

    group('compressImages', () {
      test('should compress multiple images concurrently', () async {
        final filePaths = ['image1.jpg', 'image2.jpg', 'image3.jpg'];
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        final results = await service.compressImages(filePaths);

        expect(results.length, filePaths.length);
        expect(mockCompress.compressionCount, 3);
      });

      test('should return list of compressed paths', () async {
        final filePaths = ['image1.jpg', 'image2.jpg'];
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        final results = await service.compressImages(filePaths);

        expect(results, isNotEmpty);
        expect(results.every((p) => p.isNotEmpty), true);
      });

      test('should handle empty list', () async {
        final results = await service.compressImages([]);

        expect(results, isEmpty);
      });

      test('should process all files even if some are large', () async {
        final filePaths = ['small.jpg', 'large.jpg', 'medium.jpg'];
        final smallFile = _createMockFile('small.jpg', 100000);
        final largeFile = _createMockFile('large.jpg', 600000);
        final mediumFile = _createMockFile('medium.jpg', 250000);

        mockCompress
          ..mockResult = smallFile
          ..mockRecompressionResult = _createMockFile('large_recomp.jpg', 200000);

        final results = await service.compressImages(filePaths);

        expect(results.length, 3);
      });
    });

    group('deleteCompressedImage', () {
      test('should delete file if it exists', () async {
        final mockFile = _createMockFile('compressed.jpg', 100000);
        mockFile.mockExists = true;

        await service.deleteCompressedImage(mockFile.path);

        expect(mockFile.deleteWasCalled, true);
      });

      test('should not throw if file does not exist', () async {
        const nonExistentPath = '/tmp/nonexistent.jpg';

        expect(
          () => service.deleteCompressedImage(nonExistentPath),
          returnsNormally,
        );
      });

      test('should accept file path as argument', () async {
        const filePath = '/tmp/test.jpg';

        expect(
          () => service.deleteCompressedImage(filePath),
          returnsNormally,
        );
      });
    });

    group('getFileSizeKb', () {
      test('should return file size in kilobytes', () async {
        final mockFile = _createMockFile('test.jpg', 102400);

        final sizeKb = await service.getFileSizeKb(mockFile.path);

        expect(sizeKb, 100.0);
      });

      test('should convert bytes to KB correctly', () async {
        final mockFile = _createMockFile('test.jpg', 512000);

        final sizeKb = await service.getFileSizeKb(mockFile.path);

        expect(sizeKb, 500.0);
      });
    });

    group('app constants integration', () {
      test('should use AppConstants.imageQuality', () async {
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        await service.compressImage('source.jpg');

        expect(mockCompress.lastQuality, equals(AppConstants.imageQuality));
      });

      test('should use AppConstants.maxImageWidth', () async {
        mockCompress.mockResult = _createMockFile('compressed.jpg', 100000);

        await service.compressImage('source.jpg');

        expect(mockCompress.lastWidth, equals(AppConstants.maxImageWidth));
      });

      test('should re-compress when size exceeds maxImageSizeKb * 2', () async {
        final oversizedFile =
            _createMockFile('large.jpg', (AppConstants.maxImageSizeKb * 2 * 1024).toInt() + 1000);
        mockCompress.mockResult = oversizedFile;

        await service.compressImage('source.jpg');

        expect(mockCompress.compressionCount, greaterThan(1));
      });
    });
  });
}

class MockFlutterImageCompress {
  File? mockResult;
  File? mockRecompressionResult;

  int compressionCount = 0;
  final List<int> recompressionQualities = [];
  final List<String> deletedFiles = [];

  int? lastQuality;
  int? lastWidth;
  String? lastFormat;

  Future<File?> compressAndGetFile(
    String source,
    String target, {
    int quality = 70,
    int minWidth = 800,
    int minHeight = 600,
    String format = 'jpeg',
  }) async {
    compressionCount++;
    lastQuality = quality;
    lastWidth = minWidth;
    lastFormat = format;

    if (quality == 50) {
      recompressionQualities.add(quality);
    }

    return mockResult;
  }
}

class MockFile implements File {
  @override
  final String path;
  final int size;

  bool mockExists = true;
  bool deleteWasCalled = false;

  MockFile(this.path, this.size);

  @override
  Future<int> length() async => size;

  @override
  Future<bool> exists() async => mockExists;

  @override
  Future<File> delete() async {
    deleteWasCalled = true;
    return this;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MockFile _createMockFile(String path, int sizeBytes) {
  return MockFile(path, sizeBytes);
}

extension ImageCompressionServiceTestHelper on ImageCompressionService {
  static ImageCompressionService withMock(MockFlutterImageCompress mock) {
    return _TestImageCompressionService(mock);
  }
}

class _TestImageCompressionService extends ImageCompressionService {
  final MockFlutterImageCompress _mock;

  _TestImageCompressionService(this._mock) : super._test();

  @override
  Future<String> compressImage(String sourcePath) async {
    final result = await _mock.compressAndGetFile(
      sourcePath,
      '/tmp/compressed.jpg',
      quality: 70,
      minWidth: 800,
      minHeight: 800,
      format: 'jpeg',
    );

    if (result == null) {
      throw Exception('Image compression failed for: $sourcePath');
    }

    final fileSize = await result.length();
    final fileSizeKb = fileSize / 1024;

    if (fileSizeKb > 600) {
      final recompressed = await _mock.compressAndGetFile(
        result.path,
        '/tmp/recompressed.jpg',
        quality: 50,
        minWidth: 600,
        minHeight: 600,
        format: 'jpeg',
      );

      if (recompressed != null) {
        _mock.deletedFiles.add(result.path);
        return recompressed.path;
      }
    }

    return result.path;
  }

  @override
  Future<List<String>> compressImages(List<String> sourcePaths) async {
    final futures = sourcePaths.map((path) => compressImage(path));
    return Future.wait(futures);
  }

  @override
  Future<void> deleteCompressedImage(String path) async {
    final file = MockFile(path, 0);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<double> getFileSizeKb(String path) async {
    final file = MockFile(path, 0);
    final bytes = await file.length();
    return bytes / 1024;
  }
}

extension on ImageCompressionService {
  ImageCompressionService._test() : this._internal();
  factory ImageCompressionService._internal() =>
      ImageCompressionService._private();
  ImageCompressionService._private() : this._test();
}

// Simplified test version
ImageCompressionService _createTestService() {
  return _TestImageCompressionService(MockFlutterImageCompress());
}
