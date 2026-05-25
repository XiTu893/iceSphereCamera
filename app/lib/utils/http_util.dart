import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

/// HTTP工具类
/// 封装Dio实例，提供统一的网络请求配置
class HttpUtil {
  HttpUtil._();

  static Dio? _dio;

  /// 获取Dio单例实例
  static Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  /// 创建Dio实例并配置
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加拦截器
    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_LogInterceptor());

    return dio;
  }

  /// GET请求
  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST请求
  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT请求
  static Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE请求
  static Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 上传文件
  static Future<Response> upload(
    String path, {
    required FormData formData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    return await dio.post(
      path,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }
}

/// 认证拦截器
/// 自动在请求头中注入Token
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 从本地存储获取Token
    final token = StorageService.getString(StorageKeys.token);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 检查响应中的Token更新
    final newToken = response.data?['token'] as String?;
    if (newToken != null && newToken.isNotEmpty) {
      StorageService.setString(StorageKeys.token, newToken);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401未授权，清除登录状态并跳转登录页
    if (err.response?.statusCode == 401) {
      await StorageService.remove(StorageKeys.token);
      await StorageService.remove(StorageKeys.user);
    }
    handler.next(err);
  }
}

/// 日志拦截器
/// 在调试模式下打印请求和响应日志
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('━━━ HTTP请求 ━━━');
      print('方法: ${options.method}');
      print('地址: ${options.uri}');
      print('参数: ${options.data}');
      print('头部: ${options.headers}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('━━━ HTTP响应 ━━━');
      print('地址: ${response.requestOptions.uri}');
      print('状态码: ${response.statusCode}');
      print('数据: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('━━━ HTTP错误 ━━━');
      print('地址: ${err.requestOptions.uri}');
      print('类型: ${err.type}');
      print('消息: ${err.message}');
      if (err.response != null) {
        print('状态码: ${err.response?.statusCode}');
        print('数据: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}
