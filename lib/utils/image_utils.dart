import 'dart:io'; // TAMBAHKAN INI
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  static img.Image? convertToImage(File file) {
    try {
      final imageData = file.readAsBytesSync();
      return img.decodeImage(imageData);
    } catch (e) {
      print('Error converting file to image: $e');
      return null;
    }
  }

  static img.Image? convertBytesToImage(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      print('Error converting bytes to image: $e');
      return null;
    }
  }

  static Uint8List convertImageToBytes(img.Image image) {
    return Uint8List.fromList(img.encodeJpg(image));
  }
}