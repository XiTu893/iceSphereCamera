import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/house.dart';
import '../models/panorama.dart';
import '../utils/http_util.dart';

/// API服务类
/// 封装所有与后端交互的API接口
class ApiService {
  ApiService._();

  // ========== 认证相关 ==========

  /// 用户登录
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await HttpUtil.post(
      ApiConfig.login,
      data: {
        'phone': phone,
        'password': password,
      },
    );
    return _handleResponse(response);
  }

  /// 用户注册
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    String? userType,
  }) async {
    final response = await HttpUtil.post(
      ApiConfig.register,
      data: {
        'phone': phone,
        'password': password,
        'userType': userType ?? 'OWNER',
      },
    );
    return _handleResponse(response);
  }

  /// 退出登录
  static Future<void> logout() async {
    await HttpUtil.post(ApiConfig.logout);
  }

  // ========== 房源相关 ==========

  /// 获取房源列表
  static Future<List<House>> getHouseList({
    int page = 1,
    int size = 20,
    String? keyword,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    final response = await HttpUtil.get(
      ApiConfig.houseList,
      queryParameters: queryParams,
    );
    final data = _handleResponse(response);
    final list = data['list'] as List? ?? data as List? ?? [];
    return list.map((json) => House.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// 获取房源详情
  static Future<House> getHouseDetail(int houseId) async {
    final response = await HttpUtil.get(ApiConfig.houseDetail(houseId));
    final data = _handleResponse(response);
    return House.fromJson(data);
  }

  /// 创建房源
  static Future<House> createHouse(Map<String, dynamic> houseData) async {
    final response = await HttpUtil.post(
      ApiConfig.houseCreate,
      data: houseData,
    );
    final data = _handleResponse(response);
    return House.fromJson(data);
  }

  /// 更新房源
  static Future<House> updateHouse(int houseId, Map<String, dynamic> houseData) async {
    final response = await HttpUtil.put(
      ApiConfig.houseUpdate(houseId),
      data: houseData,
    );
    final data = _handleResponse(response);
    return House.fromJson(data);
  }

  /// 删除房源
  static Future<void> deleteHouse(int houseId) async {
    await HttpUtil.delete(ApiConfig.houseDelete(houseId));
  }

  // ========== 全景相关 ==========

  /// 获取全景场景列表
  static Future<List<Panorama>> getPanoramaList(int houseId) async {
    final response = await HttpUtil.get(ApiConfig.panoramaList(houseId));
    final data = _handleResponse(response);
    final list = data['list'] as List? ?? data as List? ?? [];
    return list.map((json) => Panorama.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// 获取全景详情
  static Future<Panorama> getPanoramaDetail(int panId) async {
    final response = await HttpUtil.get(ApiConfig.panoramaDetail(panId));
    final data = _handleResponse(response);
    return Panorama.fromJson(data);
  }

  /// 上传全景图片
  static Future<Map<String, dynamic>> uploadPanorama({
    required int houseId,
    required String sceneName,
    required List<String> imagePaths,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('houseId', houseId.toString()),
      MapEntry('sceneName', sceneName),
    ]);
    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(path),
      ));
    }
    final response = await HttpUtil.upload(
      ApiConfig.panoramaUpload,
      formData: formData,
    );
    return _handleResponse(response);
  }

  /// 创建拼接任务
  static Future<StitchingTask> createStitchingTask({
    required int houseId,
    required String sceneName,
    required List<String> imagePaths,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('houseId', houseId.toString()),
      MapEntry('sceneName', sceneName),
    ]);
    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(path),
      ));
    }
    final response = await HttpUtil.upload(
      ApiConfig.stitchingCreate,
      formData: formData,
    );
    final data = _handleResponse(response);
    return StitchingTask.fromJson(data);
  }

  /// 查询拼接进度
  static Future<StitchingTask> getStitchingProgress(String taskId) async {
    final response = await HttpUtil.get(ApiConfig.stitchingProgress(taskId));
    final data = _handleResponse(response);
    return StitchingTask.fromJson(data);
  }

  // ========== 用户相关 ==========

  /// 获取用户信息
  static Future<User> getUserProfile() async {
    final response = await HttpUtil.get(ApiConfig.userProfile);
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  /// 更新用户信息
  static Future<User> updateUserProfile(Map<String, dynamic> userData) async {
    final response = await HttpUtil.put(
      ApiConfig.userUpdate,
      data: userData,
    );
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  // ========== 私有方法 ==========

  /// 统一处理响应数据
  static Map<String, dynamic> _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // 检查业务状态码
      final code = data['code'] as int?;
      if (code != null && code != 0 && code != 200) {
        final message = data['message'] as String? ?? '请求失败';
        throw ApiException(code: code, message: message);
      }
      // 返回数据部分
      return data['data'] as Map<String, dynamic>? ?? data;
    }
    return {};
  }
}

/// API异常类
class ApiException implements Exception {
  final int? code;
  final String message;

  ApiException({this.code, required this.message});

  @override
  String toString() => 'ApiException: [$code] $message';
}
