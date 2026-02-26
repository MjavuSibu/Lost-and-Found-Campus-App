import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class PhotoService {
  static final _picker = ImagePicker();

  static Future<List<XFile>> pickImages({int max = 4}) async {
    final images = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (images.isEmpty) return [];
    return images.take(max).toList();
  }

  static Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
  }

  static Future<String> fileToBase64(XFile file) async {
    final bytes = await File(file.path).readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 600,
      minHeight: 600,
      quality: 60,
    );
    return base64Encode(compressed);
  }

  static Future<List<String>> filesToBase64(List<XFile> files) async {
    final result = <String>[];
    for (final file in files) {
      final b64 = await fileToBase64(file);
      result.add(b64);
    }
    return result;
  }
}