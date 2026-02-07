import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;

class ImageCompressor {
  static Future<File> compress(
    File file, {
    int quality = 70,
    int? maxDimension,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn<_Payload>(
      _compress,
      _Payload(file.path, quality, maxDimension, receivePort.sendPort),
    );
    final resultPath = await receivePort.first as String?;
    if (resultPath == null) return file;
    return File(resultPath);
  }

  static Future<void> _compress(_Payload payload) async {
    try {
      final bytes = await File(payload.path).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        payload.port.send(null);
        return;
      }

      final maxDim = payload.maxDimension;
      if (maxDim != null) {
        final width = decoded.width;
        final height = decoded.height;
        final largest = width > height ? width : height;
        if (largest > maxDim) {
          final scale = maxDim / largest;
          final newW = (width * scale).round();
          final newH = (height * scale).round();
          decoded = img.copyResize(
            decoded,
            width: newW,
            height: newH,
            interpolation: img.Interpolation.average,
          );
        }
      }

      final jpg = img.encodeJpg(decoded, quality: payload.quality);
      final out = File('${payload.path}.compressed.jpg')
        ..writeAsBytesSync(jpg);
      payload.port.send(out.path);
    } catch (_) {
      payload.port.send(null);
    }
  }
}

class _Payload {
  _Payload(this.path, this.quality, this.maxDimension, this.port);
  final String path;
  final int quality;
  final int? maxDimension;
  final SendPort port;
}
