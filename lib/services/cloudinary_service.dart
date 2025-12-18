import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Replace with your Cloudinary credentials
  static const String _cloudName = 'dntpbw4as';
  static const String _uploadPreset = 'clinic_upload';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  /// Upload an image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    String? folder,
  }) async {
    List<String> urls = [];
    for (File file in imageFiles) {
      String? url = await uploadImage(file, folder: folder);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Pick image from gallery and upload
  Future<String?> pickAndUploadImage({String? folder}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      return await uploadImage(File(image.path), folder: folder);
    }
    return null;
  }

  /// Take photo with camera and upload
  Future<String?> takePhotoAndUpload({String? folder}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      return await uploadImage(File(image.path), folder: folder);
    }
    return null;
  }

  /// Delete an image from Cloudinary
  /// Note: Deletion requires server-side implementation with signed requests
  Future<bool> deleteImage(String publicId) async {
    // Cloudinary public API doesn't support deletion
    // You need to implement server-side deletion using your API key and secret
    print('Image deletion requires server-side implementation');
    return false;
  }
}
