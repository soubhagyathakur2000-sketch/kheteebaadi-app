import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/core/services/camera_service.dart';
import 'package:kheteebaadi/core/services/image_compression_service.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/providers/crop_listing_provider.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/screens/listing_preview_screen.dart';

class CropListingScreen extends ConsumerStatefulWidget {
  final String userId;
  final String villageId;

  const CropListingScreen({
    Key? key,
    required this.userId,
    required this.villageId,
  }) : super(key: key);

  @override
  ConsumerState<CropListingScreen> createState() => _CropListingScreenState();
}

class _CropListingScreenState extends ConsumerState<CropListingScreen> {
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  late ImagePicker _imagePicker;
  late CameraService _cameraService;
  late ImageCompressionService _compressionService;

  final List<String> _cropTypes = [
    'Wheat',
    'Rice',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Groundnut',
    'Soybean',
    'Onion',
    'Potato',
    'Tomato',
  ];

  final _cropTypeController = TextEditingController();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _imagePicker = ImagePicker();
    _cameraService = getIt<CameraService>();
    _compressionService = getIt<ImageCompressionService>();
  }

  @override
  void dispose() {
    _cropTypeController.dispose();
    _cropNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.errorMsg}')),
          );
        },
        onStatus: (status) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech to text not available')),
      );
    }
  }

  void _startListening(TextEditingController controller) async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              controller.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _captureImage() async {
    try {
      final imagePath = await _cameraService.captureImage();
      if (imagePath != null) {
        final compressedPath = await _compressionService.compressImage(imagePath);
        if (!mounted) return;
        ref
            .read(cropListingFormProvider(
              (userId: widget.userId, villageId: widget.villageId),
            ).notifier)
            .addImage(compressedPath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final compressedPath =
            await _compressionService.compressImage(pickedFile.path);
        if (!mounted) return;
        ref
            .read(cropListingFormProvider(
              (userId: widget.userId, villageId: widget.villageId),
            ).notifier)
            .addImage(compressedPath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  void _submitForm(WidgetRef ref) async {
    final formNotifier = ref.read(
      cropListingFormProvider(
        (userId: widget.userId, villageId: widget.villageId),
      ).notifier,
    );

    // Update form state from controllers
    formNotifier.setCropType(_cropTypeController.text);
    formNotifier.setCropName(_cropNameController.text);
    final quantity = double.tryParse(_quantityController.text);
    if (quantity != null) formNotifier.setQuantity(quantity);

    final price = double.tryParse(_priceController.text);
    formNotifier.setExpectedPrice(price);

    formNotifier.setDescription(_descriptionController.text);

    final listingId = await formNotifier.submit();
    if (!mounted) return;

    if (listingId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ListingPreviewScreen(
            listingId: listingId,
            userId: widget.userId,
          ),
        ),
      );
    } else {
      final state = ref.read(
        cropListingFormProvider(
          (userId: widget.userId, villageId: widget.villageId),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to create listing'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(
      cropListingFormProvider(
        (userId: widget.userId, villageId: widget.villageId),
      ),
    );

    final isOnline = ref.watch(
      Provider<Future<bool>>((ref) async => getIt<NetworkInfo>().isConnected()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Your Crop'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Offline indicator
            if (!formState.isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.warningOrange,
                child: Row(
                  children: const [
                    Icon(Icons.cloud_off, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are offline. Changes will be synced when online.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image capture section
                  _buildImageSection(),
                  const SizedBox(height: 24),

                  // Crop type dropdown
                  _buildSectionLabel('Crop Type'),
                  const SizedBox(height: 8),
                  _buildCropTypeField(),
                  const SizedBox(height: 20),

                  // Crop name
                  _buildSectionLabel('Crop Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _cropNameController,
                    label: 'Enter crop name',
                    onVoicePressed: () => _startListening(_cropNameController),
                    isListening: _isListening,
                  ),
                  const SizedBox(height: 20),

                  // Quantity stepper
                  _buildSectionLabel('Quantity (Quintals)'),
                  const SizedBox(height: 8),
                  _buildQuantityStepper(),
                  const SizedBox(height: 20),

                  // Expected price
                  _buildSectionLabel('Expected Price per Quintal (₹)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _priceController,
                    label: 'Optional',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildSectionLabel('Description'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Add notes about your crop',
                    maxLines: 3,
                    onVoicePressed: () =>
                        _startListening(_descriptionController),
                    isListening: _isListening,
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: formState.isSubmitting
                          ? null
                          : () => _submitForm(ref),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: formState.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Review & Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'OpenSans',
        color: Colors.black87,
      ),
    );
  }

  Widget _buildImageSection() {
    final formState = ref.watch(
      cropListingFormProvider(
        (userId: widget.userId, villageId: widget.villageId),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Crop Photos (Max 3)'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: formState.imagePaths.length + 1,
            itemBuilder: (context, index) {
              if (index == formState.imagePaths.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: formState.imagePaths.length < 3
                        ? () => _showImageSourceDialog()
                        : null,
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: formState.imagePaths.length < 3
                              ? AppTheme.primaryGreen
                              : AppTheme.borderGray,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: formState.imagePaths.length < 3
                            ? AppTheme.primaryGreenLight.withOpacity(0.1)
                            : AppTheme.lightGray,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: formState.imagePaths.length < 3
                                ? AppTheme.primaryGreen
                                : AppTheme.neutralGray,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formState.imagePaths.length < 3 ? 'Add Photo' : 'Max',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'OpenSans',
                              color: formState.imagePaths.length < 3
                                  ? AppTheme.primaryGreen
                                  : AppTheme.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(formState.imagePaths[index]),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(cropListingFormProvider(
                                (
                                  userId: widget.userId,
                                  villageId: widget.villageId
                                ),
                              ).notifier)
                              .removeImage(formState.imagePaths[index]);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.errorRed,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Photo Source'),
        content: const Text('Select camera or gallery'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureImage();
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage();
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildCropTypeField() {
    final formState = ref.watch(
      cropListingFormProvider(
        (userId: widget.userId, villageId: widget.villageId),
      ),
    );

    return DropdownButtonFormField<String>(
      value: _cropTypeController.text.isEmpty ? null : _cropTypeController.text,
      items: _cropTypes.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _cropTypeController.text = value;
          ref
              .read(cropListingFormProvider(
                (userId: widget.userId, villageId: widget.villageId),
              ).notifier)
              .setCropType(value);
        }
      },
      decoration: InputDecoration(
        hintText: 'Select crop type',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGray),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: quantity > 0
                ? () {
                    _quantityController.text = (quantity - 1).toStringAsFixed(0);
                    ref
                        .read(cropListingFormProvider(
                          (userId: widget.userId, villageId: widget.villageId),
                        ).notifier)
                        .setQuantity(quantity - 1);
                  }
                : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: quantity > 0
                    ? AppTheme.primaryGreen
                    : AppTheme.borderGray,
              ),
              child: const Icon(Icons.remove, color: Colors.white),
            ),
          ),
          Text(
            quantity.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'OpenSans',
            ),
          ),
          GestureDetector(
            onTap: () {
              _quantityController.text = (quantity + 1).toStringAsFixed(0);
              ref
                  .read(cropListingFormProvider(
                    (userId: widget.userId, villageId: widget.villageId),
                  ).notifier)
                  .setQuantity(quantity + 1);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    VoidCallback? onVoicePressed,
    bool isListening = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : null,
      decoration: InputDecoration(
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        suffixIcon: onVoicePressed != null
            ? GestureDetector(
                onTap: onVoicePressed,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.mic,
                    color: isListening
                        ? AppTheme.errorRed
                        : AppTheme.neutralGray,
                    size: 24,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

extension on File {
  // This is a placeholder - the actual File widget will be used
}
