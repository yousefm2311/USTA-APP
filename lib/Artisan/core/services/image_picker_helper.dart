import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<List<String>> pickImagesAsBase64({int maxImages = 5}) async {
    final images = await _picker.pickMultiImage();
    return Future.wait(images.map((xfile) async {
      final bytes = await File(xfile.path).readAsBytes();
      return base64Encode(bytes);
    }));
  }

  static Future<String?> pickSingleAsBase64() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    final bytes = await File(image.path).readAsBytes();
    return base64Encode(bytes);
    }
}
