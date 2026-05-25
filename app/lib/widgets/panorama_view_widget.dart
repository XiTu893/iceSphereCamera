import 'dart:io';
import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';

/// 全景查看组件
/// 封装panorama包，提供手势拖拽和缩放功能的全景查看器
class PanoramaViewWidget extends StatefulWidget {
  /// 全景图片路径（本地或网络）
  final String? imagePath;

  /// 全景图片URL
  final String? imageUrl;

  /// 是否显示导航控件
  final bool showControls;

  /// 初始水平视角（度）
  final double initialLongitude;

  /// 初始垂直视角（度）
  final double initialLatitude;

  /// 热点数据
  final List<Hotspot>? hotspots;

  /// 视角变化回调
  final void Function(double longitude, double latitude, double tilt)? onViewChanged;

  /// 点击回调
  final VoidCallback? onTap;

  const PanoramaViewWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.showControls = true,
    this.initialLongitude = 0,
    this.initialLatitude = 0,
    this.hotspots,
    this.onViewChanged,
    this.onTap,
  });

  @override
  State<PanoramaViewWidget> createState() => _PanoramaViewWidgetState();
}

class _PanoramaViewWidgetState extends State<PanoramaViewWidget> {
  final PanoramaController _controller = PanoramaController();
  double _longitude = 0;
  double _latitude = 0;
  double _zoom = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 全景查看器
        Panorama(
          controller: _controller,
          animSpeed: 0.0,
          sensorControl: SensorControl.orientation,
          longitude: widget.initialLongitude,
          latitude: widget.initialLatitude,
          zoom: _zoom,
          onViewChanged: (longitude, latitude, tilt) {
            setState(() {
              _longitude = longitude;
              _latitude = latitude;
            });
            widget.onViewChanged?.call(longitude, latitude, tilt);
          },
          onTap: (longitude, latitude, tilt) {
            widget.onTap?.call();
          },
          child: _buildImage(),
          hotspots: widget.hotspots ?? [],
        ),

        // 导航控件
        if (widget.showControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildControls(),
          ),

        // 视角信息
        if (widget.showControls)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildViewInfo(),
          ),
      ],
    );
  }

  /// 构建全景图片
  Widget _buildImage() {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.file(File(widget.imagePath!));
    }
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF1E88E5),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      );
    }
    return const Center(
      child: Text('未提供全景图片', style: TextStyle(color: Colors.grey)),
    );
  }

  /// 构建控制按钮
  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 放大
        _ControlButton(
          icon: Icons.add,
          onTap: () {
            setState(() {
              _zoom = (_zoom + 0.2).clamp(0.5, 3.0);
            });
          },
        ),
        const SizedBox(height: 8),
        // 缩小
        _ControlButton(
          icon: Icons.remove,
          onTap: () {
            setState(() {
              _zoom = (_zoom - 0.2).clamp(0.5, 3.0);
            });
          },
        ),
        const SizedBox(height: 8),
        // 重置视角
        _ControlButton(
          icon: Icons.center_focus_strong,
          onTap: () {
            _controller.animTo(
              longitude: 0,
              latitude: 0,
              zoom: 1.0,
            );
            setState(() {
              _zoom = 1.0;
            });
          },
        ),
      ],
    );
  }

  /// 构建视角信息
  Widget _buildViewInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '经度: ${_longitude.toStringAsFixed(1)}°  纬度: ${_latitude.toStringAsFixed(1)}°',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// 控制按钮
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
