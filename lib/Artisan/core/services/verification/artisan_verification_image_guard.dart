import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class VerificationImageGuardResult {
  const VerificationImageGuardResult._({required this.isValid, this.message});

  const VerificationImageGuardResult.valid() : this._(isValid: true);

  const VerificationImageGuardResult.invalid(String message)
    : this._(isValid: false, message: message);

  final bool isValid;
  final String? message;
}

class ArtisanVerificationImageGuard {
  ArtisanVerificationImageGuard()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: false,
          enableContours: false,
          enableClassification: false,
          minFaceSize: 0.15,
        ),
      );

  final FaceDetector _faceDetector;

  Future<VerificationImageGuardResult> validateSelfie(
    XFile file, {
    required String invalidMessage,
  }) async {
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.length != 1) {
        return VerificationImageGuardResult.invalid(invalidMessage);
      }

      final face = faces.first;
      final box = face.boundingBox;
      final faceArea = box.width * box.height;
      if (faceArea < 30000) {
        return VerificationImageGuardResult.invalid(invalidMessage);
      }

      return const VerificationImageGuardResult.valid();
    } catch (_) {
      return const VerificationImageGuardResult.valid();
    }
  }

  Future<void> close() async {
    await _faceDetector.close();
  }
}
