import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Retorna a versão do SDK do Android, ou 0 em outras plataformas.
  static Future<int> _androidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  /// Solicita permissão para acessar arquivos do dispositivo (documentos, CBR, CBZ).
  ///
  /// - Android >= 11 (API 30+): usa MANAGE_EXTERNAL_STORAGE (acesso total ao FS)
  /// - Android < 11 (API < 30): usa READ_EXTERNAL_STORAGE (permissão clássica)
  /// - Outras plataformas: retorna true diretamente
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _androidSdkVersion();

    if (sdk >= 30) {
      // Android 11+: MANAGE_EXTERNAL_STORAGE para acesso a documentos/arquivos arbitrários
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;

      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied) await openAppSettings();
      return false;
    } else {
      // Android < 11: READ_EXTERNAL_STORAGE clássico
      final status = await Permission.storage.status;
      if (status.isGranted) return true;

      final result = await Permission.storage.request();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied) await openAppSettings();
      return false;
    }
  }

  /// Verifica sem solicitar se a permissão já foi concedida.
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _androidSdkVersion();

    if (sdk >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }
}
