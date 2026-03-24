import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageCompressionService {
  /// Compresses an image file to target size for bandwidth optimization.
  /// Returns the path to the compressed file in the app's temp directory.
  Future<String> compressImage(String sourcePath) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: AppConstants.imageQuality,
      minWidth: AppConstants.maxImageWidth,
      minHeight: AppConstants.maxImageWidth,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Image compression failed for: $sourcePath');
    }

    // Verify size is within budget
    final fileSize = await result.length();
    final fileSizeKb = fileSize / 1024;

    if (fileSizeKb > AppConstants.maxImageSizeKb * 2) {
      // Re-compress with lower quality if still too large
      final recompressed = await FlutterImageCompress.compressAndGetFile(
        result.path,
        '${tempDir.path}/${const Uuid().v4()}.jpg',
        quality: 50,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );
      if (recompressed != null) {
        await File(result.path).delete();
        return recompressed.path;
      }
    }

    return result.path;
  }

  /// Compresses multiple images concurrently.
  Future<List<String>> compressImages(List<String> sourcePaths) async {
    final futures = sourcePaths.map((path) => compressImage(path));
    return Future.wait(futures);
  }

  /// Deletes a compressed image from temp storage.
  Future<void> deleteCompressedImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Gets the file size in KB.
  Future<double> getFileSizeKb(String path) async {
    final file = File(path);
    final bytes = await file.length();
    return bytes / 1024;
  }
}
