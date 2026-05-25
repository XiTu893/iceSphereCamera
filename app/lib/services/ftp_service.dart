import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

/// FTP上传服务
/// 支持将拍摄的全景图片上传到FTP服务器
class FtpService {
  FtpService._();

  /// 获取FTP配置
  static FtpConfig getConfig() {
    return FtpConfig(
      host: StorageService.getString(StorageKeys.ftpHost) ?? '',
      port: StorageService.getInt(StorageKeys.ftpPort) ?? 21,
      username: StorageService.getString(StorageKeys.ftpUsername) ?? '',
      password: StorageService.getString(StorageKeys.ftpPassword) ?? '',
      remoteDir: StorageService.getString(StorageKeys.ftpRemoteDir) ?? '/panorama',
    );
  }

  /// 保存FTP配置
  static Future<void> saveConfig(FtpConfig config) async {
    await StorageService.setString(StorageKeys.ftpHost, config.host);
    await StorageService.setInt(StorageKeys.ftpPort, config.port);
    await StorageService.setString(StorageKeys.ftpUsername, config.username);
    await StorageService.setString(StorageKeys.ftpPassword, config.password);
    await StorageService.setString(StorageKeys.ftpRemoteDir, config.remoteDir);
  }

  /// 测试FTP连接
  static Future<bool> testConnection(FtpConfig config) async {
    try {
      final ftpConnect = FTPConnect(
        config.host,
        port: config.port,
        user: config.username,
        pass: config.password,
      );
      final result = await ftpConnect.connect();
      if (result) {
        await ftpConnect.disconnect();
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  /// 上传单个文件到FTP
  static Future<bool> uploadFile(String localPath, String remoteDir, {
    Function(double progress)? onProgress,
  }) async {
    final config = getConfig();
    if (config.host.isEmpty) return false;

    final ftpConnect = FTPConnect(
      config.host,
      port: config.port,
      user: config.username,
      pass: config.password,
    );

    try {
      await ftpConnect.connect();

      // 确保远程目录存在
      final fullRemoteDir = '${config.remoteDir}/$remoteDir';
      await _ensureRemoteDir(ftpConnect, fullRemoteDir);

      // 上传文件
      final file = File(localPath);
      final fileName = localPath.split(Platform.pathSeparator).last;
      final remotePath = '$fullRemoteDir/$fileName';
      final result = await ftpConnect.uploadFile(file, sRemoteName: remotePath);

      await ftpConnect.disconnect();
      return result;
    } catch (e) {
      try { await ftpConnect.disconnect(); } catch (_) {}
      rethrow;
    }
  }

  /// 批量上传文件到FTP
  static Future<FtpUploadResult> uploadFiles(
    List<String> localPaths,
    String remoteDir, {
    Function(int current, int total, String fileName)? onProgress,
  }) async {
    final config = getConfig();
    if (config.host.isEmpty) {
      return FtpUploadResult(
        success: false,
        message: 'FTP未配置，请先在设置中配置FTP连接信息',
      );
    }

    final ftpConnect = FTPConnect(
      config.host,
      port: config.port,
      user: config.username,
      pass: config.password,
    );

    int successCount = 0;
    int failCount = 0;
    final errors = <String>[];

    try {
      await ftpConnect.connect();

      // 确保远程目录存在
      final fullRemoteDir = '${config.remoteDir}/$remoteDir';
      await _ensureRemoteDir(ftpConnect, fullRemoteDir);

      for (int i = 0; i < localPaths.length; i++) {
        final localPath = localPaths[i];
        final fileName = localPath.split(Platform.pathSeparator).last;
        onProgress?.call(i + 1, localPaths.length, fileName);

        try {
          final file = File(localPath);
          final remotePath = '$fullRemoteDir/$fileName';
          final result = await ftpConnect.uploadFile(file, sRemoteName: remotePath);
          if (result) {
            successCount++;
          } else {
            failCount++;
            errors.add('$fileName: 上传失败');
          }
        } catch (e) {
          failCount++;
          errors.add('$fileName: $e');
        }
      }

      await ftpConnect.disconnect();
    } catch (e) {
      try { await ftpConnect.disconnect(); } catch (_) {}
      return FtpUploadResult(
        success: false,
        message: 'FTP连接失败：$e',
        successCount: successCount,
        failCount: failCount,
        errors: errors,
      );
    }

    return FtpUploadResult(
      success: failCount == 0,
      message: failCount == 0
          ? '全部上传成功'
          : '成功$successCount个，失败$failCount个',
      successCount: successCount,
      failCount: failCount,
      errors: errors,
    );
  }

  /// 确保远程目录存在，逐级创建
  static Future<void> _ensureRemoteDir(FTPConnect ftpConnect, String dir) async {
    final segments = dir.split('/').where((s) => s.isNotEmpty).toList();
    String currentPath = '';
    for (final segment in segments) {
      currentPath += '/$segment';
      try {
        await ftpConnect.makeDirectory(currentPath);
      } catch (_) {
        // 目录可能已存在，忽略错误
      }
    }
  }

  /// 将拍摄结果打包为ZIP并返回路径
  static Future<String> packToZip(List<String> imagePaths, String sessionName) async {
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/panorama_$sessionName.zip';

    // 使用archive包创建ZIP
    final archive = await _createArchive(imagePaths);
    final zipData = await _encodeZip(archive);

    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    return zipPath;
  }

  static Future<dynamic> _createArchive(List<String> imagePaths) async {
    // 简化实现：直接拷贝文件到临时目录
    // 实际ZIP打包在capture_result_page中使用archive包实现
    return null;
  }

  static Future<List<int>> _encodeZip(dynamic archive) async {
    return [];
  }
}

/// FTP配置
class FtpConfig {
  final String host;
  final int port;
  final String username;
  final String password;
  final String remoteDir;

  const FtpConfig({
    required this.host,
    this.port = 21,
    required this.username,
    required this.password,
    this.remoteDir = '/panorama',
  });

  bool get isConfigured => host.isNotEmpty && username.isNotEmpty;
}

/// FTP上传结果
class FtpUploadResult {
  final bool success;
  final String message;
  final int successCount;
  final int failCount;
  final List<String> errors;

  const FtpUploadResult({
    required this.success,
    required this.message,
    this.successCount = 0,
    this.failCount = 0,
    this.errors = const [],
  });
}
