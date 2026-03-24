import 'package:image_picker/image_picker.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/core/services/image_compression_service.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  final ImageCompressionService _compressionService;

  CameraService({required ImageCompressionService compressionService})
      : _compressionService = compressionService;

  /// Captures a photo from the camera and returns the compressed file path.
  Future<String?> capturePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) return null;

    // Compress the captured image
    final compressedPath = await _compressionService.compressImage(photo.path);
    return compressedPath;
  }

  /// Picks an image from the gallery and returns the compressed file path.
  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image == null) return null;

    final compressedPath = await _compressionService.compressImage(image.path);
    return compressedPath;
  }

  /// Captures multiple photos (up to maxListingImages).
  Future<List<String>> captureMultiplePhotos({int maxCount = 3}) async {
    final List<String> paths = [];

    // For multiple photos, we use pickMultiImage from gallery
    // or let user take photos one by one from camera
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
      limit: maxCount,
    );

    for (final image in images.take(maxCount)) {
      final compressedPath = await _compressionService.compressImage(image.path);
      paths.add(compressedPath);
    }

    return paths;
  }
}
