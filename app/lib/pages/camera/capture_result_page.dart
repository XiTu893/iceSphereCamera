import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import '../../config/theme_config.dart';
import '../../services/ftp_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common_widgets.dart';
import 'ftp_settings_page.dart';

/// 拍摄结果管理页面
/// 拍摄完成后，用户可以选择：
/// 1. 保存到本地（已自动保存）
/// 2. 复制/分享到PC（通过系统分享功能）
/// 3. 上传到FTP服务器
/// 4. 上传到云端拼接
class CaptureResultPage extends StatefulWidget {
  /// 拍摄的图片路径列表
  final List<String> imagePaths;

  /// 拍摄会话名称
  final String sessionName;

  const CaptureResultPage({
    super.key,
    required this.imagePaths,
    required this.sessionName,
  });

  @override
  State<CaptureResultPage> createState() => _CaptureResultPageState();
}

class _CaptureResultPageState extends State<CaptureResultPage> {
  bool _isUploadingFtp = false;
  bool _isPackingZip = false;
  double _ftpProgress = 0;
  String _ftpStatus = '';
  FtpUploadResult? _ftpResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍摄完成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拍摄结果概览
            _buildSummaryCard(),
            const SizedBox(height: 16),
            // 图片预览网格
            _buildImageGrid(),
            const SizedBox(height: 24),
            // 操作按钮区域
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  /// 构建拍摄结果概览卡片
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConfig.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: ThemeConfig.successColor,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            '拍摄完成',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.successColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '会话：${widget.sessionName}',
            style: const TextStyle(
              fontSize: 13,
              color: ThemeConfig.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共${widget.imagePaths.length}张图片',
            style: const TextStyle(
              fontSize: 13,
              color: ThemeConfig.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图片预览网格
  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '拍摄图片',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ThemeConfig.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.imagePaths.asMap().entries.map((entry) {
            return _buildImageThumbnail(entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  /// 图片缩略图
  Widget _buildImageThumbnail(String path, int index) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮区域
  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 本地保存状态
        _buildLocalSaveInfo(),
        const SizedBox(height: 16),
        // 分享/复制到PC
        RoundedButton(
          text: '分享/导出到PC',
          onPressed: _isPackingZip ? null : _shareToPC,
          icon: Icons.share,
          isLoading: _isPackingZip,
        ),
        const SizedBox(height: 12),
        // FTP上传
        _buildFtpUploadSection(),
        const SizedBox(height: 12),
        // 云端拼接
        RoundedButton(
          text: '上传云端拼接',
          onPressed: _uploadToCloud,
          icon: Icons.cloud_upload,
          color: ThemeConfig.primaryColor,
        ),
        const SizedBox(height: 24),
        // 返回首页
        OutlinedButton(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('返回首页'),
        ),
      ],
    );
  }

  /// 本地保存信息
  Widget _buildLocalSaveInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeConfig.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_saved, color: ThemeConfig.infoColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '已保存到本地',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.infoColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '可通过USB连接手机，在文件管理器中找到拍摄图片',
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeConfig.infoColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FTP上传区域
  Widget _buildFtpUploadSection() {
    final ftpConfig = FtpService.getConfig();
    final isFtpConfigured = ftpConfig.isConfigured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isFtpConfigured)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FtpSettingsPage()),
                );
                setState(() {}); // 刷新FTP配置状态
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('请先配置FTP服务器'),
            ),
          ),
        RoundedButton(
          text: '上传到FTP服务器',
          onPressed: isFtpConfigured && !_isUploadingFtp ? _uploadToFtp : null,
          icon: Icons.upload_file,
          color: Colors.orange,
          isLoading: _isUploadingFtp,
        ),
        // FTP上传进度
        if (_isUploadingFtp) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _ftpProgress),
          const SizedBox(height: 4),
          Text(
            _ftpStatus,
            style: const TextStyle(fontSize: 12, color: ThemeConfig.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
        // FTP上传结果
        if (_ftpResult != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _ftpResult!.success
                  ? ThemeConfig.successColor.withValues(alpha: 0.1)
                  : ThemeConfig.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _ftpResult!.message,
              style: TextStyle(
                fontSize: 12,
                color: _ftpResult!.success
                    ? ThemeConfig.successColor
                    : ThemeConfig.errorColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 分享/导出到PC
  Future<void> _shareToPC() async {
    setState(() {
      _isPackingZip = true;
    });

    try {
      // 将图片打包为ZIP
      final zipPath = await _packImagesToZip();

      setState(() {
        _isPackingZip = false;
      });

      if (zipPath != null && mounted) {
        // 使用系统分享功能（可通过USB/蓝牙/邮件等方式传到PC）
        final result = await Share.shareXFiles(
          [XFile(zipPath)],
          text: '全景拍摄素材 - ${widget.sessionName}',
          subject: '全景拍摄素材',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPackingZip = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打包失败：$e'),
            backgroundColor: ThemeConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 将图片打包为ZIP文件
  Future<String?>> _packImagesToZip() async {
    try {
      final archive = Archive();

      for (int i = 0; i < widget.imagePaths.length; i++) {
        final filePath = widget.imagePaths[i];
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = filePath.split(Platform.pathSeparator).last;
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/panorama_${widget.sessionName}.zip';
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);

      return zipPath;
    } catch (e) {
      return null;
    }
  }

  /// 上传到FTP
  Future<void> _uploadToFtp() async {
    setState(() {
      _isUploadingFtp = true;
      _ftpProgress = 0;
      _ftpStatus = '正在连接FTP服务器...';
      _ftpResult = null;
    });

    try {
      final result = await FtpService.uploadFiles(
        widget.imagePaths,
        widget.sessionName,
        onProgress: (current, total, fileName) {
          if (mounted) {
            setState(() {
              _ftpProgress = current / total;
              _ftpStatus = '正在上传 $current/$total: $fileName';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isUploadingFtp = false;
          _ftpResult = result;
          _ftpStatus = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingFtp = false;
          _ftpResult = FtpUploadResult(
            success: false,
            message: '上传失败：$e',
          );
          _ftpStatus = '上传失败';
        });
      }
    }
  }

  /// 上传到云端拼接
  void _uploadToCloud() {
    // 跳转到拼接进度页面
    Navigator.of(context).pushNamed(
      '/stitching_progress',
      arguments: {'imagePaths': widget.imagePaths},
    );
  }
}
