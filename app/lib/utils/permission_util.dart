import 'package:permission_handler/permission_handler.dart';

/// 权限请求工具类
/// 统一管理应用所需的各种权限请求
class PermissionUtil {
  PermissionUtil._();

  /// 请求相机权限
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 请求存储权限
  static Future<bool> requestStorage() async {
    // Android 13+ 不再需要 READ_EXTERNAL_STORAGE
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    // 降级尝试旧版存储权限
    final fallbackStatus = await Permission.storage.request();
    return fallbackStatus.isGranted;
  }

  /// 请求传感器权限
  static Future<bool> requestSensors() async {
    final status = await Permission.sensors.request();
    return status.isGranted;
  }

  /// 请求位置权限
  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// 请求拍摄全景所需的所有权限
  /// 包括：相机、存储、传感器
  static Future<bool> requestPanoramaPermissions() async {
    final cameraGranted = await requestCamera();
    if (!cameraGranted) return false;

    final storageGranted = await requestStorage();
    if (!storageGranted) return false;

    final sensorsGranted = await requestSensors();
    // 传感器权限不是必须的，仅影响引导精度
    return true;
  }

  /// 检查相机权限是否已授权
  static Future<bool> isCameraGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// 检查存储权限是否已授权
  static Future<bool> isStorageGranted() async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;
    final fallbackStatus = await Permission.storage.status;
    return fallbackStatus.isGranted;
  }

  /// 检查传感器权限是否已授权
  static Future<bool> isSensorsGranted() async {
    final status = await Permission.sensors.status;
    return status.isGranted;
  }

  /// 打开应用设置页面
  /// 当权限被永久拒绝时，引导用户手动开启
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// 获取权限状态描述
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '未授权';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limited:
        return '部分授权';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.provisional:
        return '临时授权';
      default:
        return '未知状态';
    }
  }
}
