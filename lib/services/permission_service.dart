import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> ensureOverlay() async {
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }
}
