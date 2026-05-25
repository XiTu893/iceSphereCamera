import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// 认证服务
/// 管理用户登录状态和认证相关操作
class AuthService extends ChangeNotifier {
  User _currentUser = const User();
  bool _isLoading = false;
  String? _error;

  User get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser.isLoggedIn;

  AuthService() {
    _loadUserFromStorage();
  }

  /// 从本地存储加载用户信息
  Future<void> _loadUserFromStorage() async {
    final userJson = StorageService.getString(StorageKeys.user);
    if (userJson != null) {
      try {
        final json = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(json);
        notifyListeners();
      } catch (_) {
        // 数据损坏，清除存储
        await _clearUserData();
      }
    }
  }

  /// 用户登录
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.login(
        phone: phone,
        password: password,
      );

      final user = User.fromJson(result);
      _currentUser = user;

      // 保存用户信息和Token到本地存储
      await _saveUserData(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络连接失败，请检查网络设置';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 用户注册
  Future<bool> register({
    required String phone,
    required String password,
    String? userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.register(
        phone: phone,
        password: password,
        userType: userType,
      );

      final user = User.fromJson(result);
      _currentUser = user;

      // 保存用户信息和Token到本地存储
      await _saveUserData(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络连接失败，请检查网络设置';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      // 即使退出登录API调用失败，也要清除本地数据
    }
    await _clearUserData();
    _currentUser = const User();
    notifyListeners();
  }

  /// 更新用户信息
  void updateUser(User user) {
    _currentUser = user;
    _saveUserData(user);
    notifyListeners();
  }

  /// 保存用户数据到本地存储
  Future<void> _saveUserData(User user) async {
    if (user.token != null) {
      await StorageService.setString(StorageKeys.token, user.token!);
    }
    await StorageService.setString(
      StorageKeys.user,
      jsonEncode(user.toJson()),
    );
  }

  /// 清除本地用户数据
  Future<void> _clearUserData() async {
    await StorageService.remove(StorageKeys.token);
    await StorageService.remove(StorageKeys.user);
  }
}
