import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.storage.request();
    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }
}
