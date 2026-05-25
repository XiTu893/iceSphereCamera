import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme_config.dart';
import '../../widgets/panorama_view_widget.dart';

/// 全景查看页面
/// 全屏显示全景图片，支持手势拖拽和缩放
class PanoramaViewerPage extends StatefulWidget {
  /// 全景图片URL
  final String? panoramaUrl;

  /// 全景图片本地路径
  final String? panoramaPath;

  /// 场景名称
  final String? sceneName;

  const PanoramaViewerPage({
    super.key,
    this.panoramaUrl,
    this.panoramaPath,
    this.sceneName,
  });

  @override
  State<PanoramaViewerPage> createState() => _PanoramaViewerPageState();
}

class _PanoramaViewerPageState extends State<PanoramaViewerPage> {
  bool _showUI = true;

  /// 切换UI显示
  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    // 根据UI显示状态切换系统UI
    if (_showUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 全景查看器
          GestureDetector(
            onTap: _toggleUI,
            child: PanoramaViewWidget(
              imagePath: widget.panoramaPath,
              imageUrl: widget.panoramaUrl,
              showControls: _showUI,
            ),
          ),

          // 顶部栏
          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

          // 底部提示
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomHint(),
            ),
        ],
      ),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity( 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // 返回按钮
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity( 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            // 场景名称
            Expanded(
              child: Text(
                widget.sceneName ?? '全景查看',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 全屏按钮
            GestureDetector(
              onTap: _toggleUI,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity( 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部提示
  Widget _buildBottomHint() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: Text(
            '拖拽旋转 · 双指缩放 · 点击隐藏界面',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
