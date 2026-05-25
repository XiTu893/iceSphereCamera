import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme_config.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'stitching_progress_page.dart';

/// 全景上传页面
/// 选择图片并提交拼接任务
class PanoramaUploadPage extends StatefulWidget {
  final int houseId;

  const PanoramaUploadPage({super.key, required this.houseId});

  @override
  State<PanoramaUploadPage> createState() => _PanoramaUploadPageState();
}

class _PanoramaUploadPageState extends State<PanoramaUploadPage> {
  final _sceneNameController = TextEditingController();
  final List<String> _selectedImagePaths = [];
  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _sceneNameController.dispose();
    super.dispose();
  }

  /// 从相册选择图片
  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImagePaths.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败：$e'),
            backgroundColor: ThemeConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 移除已选图片
  void _removeImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  /// 提交拼接任务
  Future<void> _handleSubmit() async {
    if (_selectedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择全景图片'),
          backgroundColor: ThemeConfig.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_sceneNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入场景名称'),
          backgroundColor: ThemeConfig.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final task = await ApiService.createStitchingTask(
        houseId: widget.houseId,
        sceneName: _sceneNameController.text.trim(),
        imagePaths: _selectedImagePaths,
      );

      if (mounted) {
        // 跳转到拼接进度页面
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StitchingProgressPage(
              taskId: task.taskId,
              imagePaths: _selectedImagePaths,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: ThemeConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传全景'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 场景名称输入
            TextFormField(
              controller: _sceneNameController,
              decoration: const InputDecoration(
                labelText: '场景名称',
                prefixIcon: Icon(Icons.label_outline, color: ThemeConfig.primaryColor),
                hintText: '例如：客厅、卧室、厨房',
              ),
            ),
            const SizedBox(height: 20),
            // 图片选择区域
            _buildImageSection(),
            const SizedBox(height: 24),
            // 提交按钮
            RoundedButton(
              text: '提交拼接',
              onPressed: _handleSubmit,
              isLoading: _isSubmitting,
              icon: Icons.cloud_upload,
            ),
            const SizedBox(height: 12),
            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeConfig.infoColor.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: ThemeConfig.infoColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '建议上传8-10张覆盖360度的照片以获得最佳拼接效果。照片之间应有30%-50%的重叠区域。',
                      style: TextStyle(
                        color: ThemeConfig.infoColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择区域
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '全景图片',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ThemeConfig.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedImagePaths.isNotEmpty)
              Text(
                '已选${_selectedImagePaths.length}张',
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConfig.textSecondaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // 图片网格
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 已选图片缩略图
            ..._selectedImagePaths.asMap().entries.map((entry) {
              return _ImageThumbnail(
                imagePath: entry.value,
                index: entry.key,
                onRemove: _removeImage,
              );
            }),
            // 添加图片按钮
            _AddImageButton(onTap: _pickImages),
          ],
        ),
      ],
    );
  }
}

/// 图片缩略图组件
class _ImageThumbnail extends StatelessWidget {
  final String imagePath;
  final int index;
  final Function(int) onRemove;

  const _ImageThumbnail({
    required this.imagePath,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // 删除按钮
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: ThemeConfig.errorColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
        // 序号
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity( 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}

/// 添加图片按钮
class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: ThemeConfig.primaryColor.withOpacity( 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeConfig.primaryColor.withOpacity( 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: ThemeConfig.primaryColor, size: 28),
            SizedBox(height: 4),
            Text(
              '添加',
              style: TextStyle(color: ThemeConfig.primaryColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
