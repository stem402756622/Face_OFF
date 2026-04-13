import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndEncodeImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null) return null;

      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      
      // Optionally resize image to reduce API payload
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        final resizedImage = img.copyResize(
          decodedImage,
          width: 800,
          maintainAspect: true,
        );
        final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
        return base64Encode(resizedBytes);
      }
      
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      
      // Optionally resize image
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        final resizedImage = img.copyResize(
          decodedImage,
          width: 800,
          maintainAspect: true,
        );
        final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
        return base64Encode(resizedBytes);
      }
      
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }
}

