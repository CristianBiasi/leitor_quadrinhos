import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Retorna a versão do SDK do Android, ou null em outras plataformas.
  static Future<int?> _androidSdkVersion() async {
    if (!Platform.isAndroid) return null;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  /// Solicita permissão de armazenamento compatível com todas as versões do Android.
  ///
  /// - Android < 13 (API < 33): usa READ_EXTERNAL_STORAGE
  /// - Android 13-15 (API 33-35): usa READ_MEDIA_IMAGES + READ_MEDIA_VIDEO
  /// - Android 16+ (API 36+): file_picker usa SAF/Photo Picker,
  ///   nenhuma permissão em runtime é necessária — retorna true direto.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _androidSdkVersion() ?? 0;

    // Android 16+ (API 36+): Storage Access Framework não exige permissão
    if (sdk >= 36) return true;

    // Android 13-15 (API 33-35): granular media permissions
    if (sdk >= 33) {
      final images = await Permission.photos.status;
      if (images.isGranted) return true;

      final result = await Permission.photos.request();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied) await openAppSettings();
      return false;
    }

    // Android < 13 (API < 33): permissão de armazenamento clássica
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) await openAppSettings();
    return false;
  }
}
