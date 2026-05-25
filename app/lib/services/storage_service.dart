import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
/// 封装SharedPreferences，提供统一的键值对存储操作
class StorageService {
  StorageService._();

  static SharedPreferences? _prefs;

  /// 初始化存储服务
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError('StorageService未初始化，请先调用init()');
    }
    return _prefs!;
  }

  // ========== 基础操作 ==========

  /// 保存字符串
  static Future<bool> setString(String key, String value) async {
    return await _instance.setString(key, value);
  }

  /// 获取字符串
  static String? getString(String key) {
    return _instance.getString(key);
  }

  /// 保存整数
  static Future<bool> setInt(String key, int value) async {
    return await _instance.setInt(key, value);
  }

  /// 获取整数
  static int? getInt(String key) {
    return _instance.getInt(key);
  }

  /// 保存布尔值
  static Future<bool> setBool(String key, bool value) async {
    return await _instance.setBool(key, value);
  }

  /// 获取布尔值
  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  /// 保存双精度浮点数
  static Future<bool> setDouble(String key, double value) async {
    return await _instance.setDouble(key, value);
  }

  /// 获取双精度浮点数
  static double? getDouble(String key) {
    return _instance.getDouble(key);
  }

  /// 保存字符串列表
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _instance.setStringList(key, value);
  }

  /// 获取字符串列表
  static List<String>? getStringList(String key) {
    return _instance.getStringList(key);
  }

  /// 删除指定key
  static Future<bool> remove(String key) async {
    return await _instance.remove(key);
  }

  /// 清除所有数据
  static Future<bool> clear() async {
    return await _instance.clear();
  }

  /// 检查key是否存在
  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }
}

/// 存储键常量
/// 统一管理所有本地存储的key名称
class StorageKeys {
  StorageKeys._();

  /// 用户Token
  static const String token = 'auth_token';

  /// 用户信息JSON
  static const String user = 'user_info';

  /// 是否首次启动
  static const String isFirstLaunch = 'is_first_launch';

  /// 上次选择的房源ID
  static const String lastHouseId = 'last_house_id';

  /// 相机引导设置 - 是否自动拍摄
  static const String autoCapture = 'auto_capture';

  /// 相机引导设置 - 拍摄延迟（毫秒）
  static const String captureDelay = 'capture_delay';
}
