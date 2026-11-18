import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionDenied implements Exception {
  const CameraPermissionDenied();

  @override
  String toString() =>
      'Нет доступа к камере. Можно продолжить без фото или разрешить камеру в настройках.';
}

class CameraService {
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> takeAvatarPhoto() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied || status.isDenied || status.isRestricted) {
      throw const CameraPermissionDenied();
    }
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 720,
    );
    if (image == null) {
      return null;
    }
    final docs = await getApplicationDocumentsDirectory();
    final target = File(p.join(docs.path, 'avatar.jpg'));
    await File(image.path).copy(target.path);
    return target.path;
  }
}
