import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// 全景查看组件
/// 使用WebView + Three.js实现球形全景渲染，替代panorama插件
/// 彻底消除motion_sensors依赖（Kotlin版本冲突问题）
class PanoramaViewWidget extends StatefulWidget {
  /// 全景图片路径（本地）
  final String? imagePath;

  /// 全景图片URL（网络）
  final String? imageUrl;

  /// 是否显示导航控件
  final bool showControls;

  /// 视角变化回调
  final void Function(double longitude, double latitude)? onViewChanged;

  /// 点击回调
  final VoidCallback? onTap;

  const PanoramaViewWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.showControls = true,
    this.onViewChanged,
    this.onTap,
  });

  @override
  State<PanoramaViewWidget> createState() => _PanoramaViewWidgetState();
}

class _PanoramaViewWidgetState extends State<PanoramaViewWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  double _fov = 75;
  String? _localServerPath;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // 获取图片源
    String imageSrc = '';
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      imageSrc = widget.imageUrl!;
    } else if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      // 本地文件需要通过WebView的allowFileAccess加载
      imageSrc = 'file://${widget.imagePath}';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (imageSrc.isNotEmpty) {
              _controller.runJavaScript('loadPanorama("$imageSrc");');
            }
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'PanoramaChannel',
        onMessageReceived: (message) {
          // 处理来自JS的消息（视角变化等）
          final data = message.message;
          if (data.startsWith('view:')) {
            final parts = data.substring(5).split(',');
            if (parts.length == 2) {
              final lon = double.tryParse(parts[0]) ?? 0;
              final lat = double.tryParse(parts[1]) ?? 0;
              widget.onViewChanged?.call(lon, lat);
            }
          } else if (data == 'tap') {
            widget.onTap?.call();
          }
        },
      );

    // 加载Three.js全景HTML
    final htmlContent = _buildPanoramaHtml();
    final tempDir = await getTemporaryDirectory();
    final htmlFile = File('${tempDir.path}/panorama_viewer.html');
    await htmlFile.writeAsString(htmlContent);
    _localServerPath = htmlFile.path;

    await _controller.loadFile(_localServerPath!);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView全景查看器
        WebViewWidget(controller: _controller),

        // 加载指示器
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
          ),

        // 导航控件
        if (widget.showControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildControls(),
          ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: Icons.add,
          onTap: () {
            _fov = (_fov - 10).clamp(30, 120);
            _controller.runJavaScript('setFov($_fov);');
          },
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: Icons.remove,
          onTap: () {
            _fov = (_fov + 10).clamp(30, 120);
            _controller.runJavaScript('setFov($_fov);');
          },
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: Icons.center_focus_strong,
          onTap: () {
            _fov = 75;
            _controller.runJavaScript('resetView();');
          },
        ),
      ],
    );
  }

  /// 生成Three.js全景HTML页面
  String _buildPanoramaHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; }
    body { overflow: hidden; background: #000; }
    canvas { display: block; width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <script type="importmap">
  {
    "imports": {
      "three": "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js",
      "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"
    }
  }
  </script>
  <script type="module">
    import * as THREE from 'three';

    let camera, scene, renderer, sphere;
    let isUserDragging = false;
    let previousMouseX = 0, previousMouseY = 0;
    let lon = 0, lat = 0, phi = 0, theta = 0;
    let targetLon = 0, targetLat = 0;
    let fov = 75;

    function init() {
      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera(fov, window.innerWidth / window.innerHeight, 0.1, 1000);
      renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setPixelRatio(window.devicePixelRatio);
      document.body.appendChild(renderer.domElement);

      // 创建球体
      const geometry = new THREE.SphereGeometry(500, 60, 40);
      geometry.scale(-1, 1, 1); // 翻转使纹理在内部
      const material = new THREE.MeshBasicMaterial({ color: 0x333333 });
      sphere = new THREE.Mesh(geometry, material);
      scene.add(sphere);

      // 事件监听
      renderer.domElement.addEventListener('pointerdown', onPointerDown);
      renderer.domElement.addEventListener('pointermove', onPointerMove);
      renderer.domElement.addEventListener('pointerup', onPointerUp);
      renderer.domElement.addEventListener('wheel', onWheel);
      window.addEventListener('resize', onResize);

      // 触摸缩放
      let lastTouchDist = 0;
      renderer.domElement.addEventListener('touchstart', (e) => {
        if (e.touches.length === 2) {
          lastTouchDist = getTouchDist(e.touches);
        }
      });
      renderer.domElement.addEventListener('touchmove', (e) => {
        if (e.touches.length === 2) {
          const dist = getTouchDist(e.touches);
          fov += (lastTouchDist - dist) * 0.1;
          fov = Math.max(30, Math.min(120, fov));
          camera.fov = fov;
          camera.updateProjectionMatrix();
          lastTouchDist = dist;
        }
      });

      animate();
    }

    function getTouchDist(touches) {
      const dx = touches[0].clientX - touches[1].clientX;
      const dy = touches[0].clientY - touches[1].clientY;
      return Math.sqrt(dx * dx + dy * dy);
    }

    function onPointerDown(e) {
      isUserDragging = true;
      previousMouseX = e.clientX;
      previousMouseY = e.clientY;
    }

    function onPointerMove(e) {
      if (!isUserDragging) return;
      const dx = e.clientX - previousMouseX;
      const dy = e.clientY - previousMouseY;
      targetLon -= dx * 0.2;
      targetLat += dy * 0.2;
      targetLat = Math.max(-85, Math.min(85, targetLat));
      previousMouseX = e.clientX;
      previousMouseY = e.clientY;
    }

    function onPointerUp() {
      isUserDragging = false;
    }

    function onWheel(e) {
      fov += e.deltaY * 0.05;
      fov = Math.max(30, Math.min(120, fov));
      camera.fov = fov;
      camera.updateProjectionMatrix();
    }

    function onResize() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }

    function animate() {
      requestAnimationFrame(animate);
      lon += (targetLon - lon) * 0.1;
      lat += (targetLat - lat) * 0.1;
      phi = THREE.MathUtils.degToRad(90 - lat);
      theta = THREE.MathUtils.degToRad(lon);
      const target = new THREE.Vector3(
        500 * Math.sin(phi) * Math.cos(theta),
        500 * Math.cos(phi),
        500 * Math.sin(phi) * Math.sin(theta)
      );
      camera.lookAt(target);
      renderer.render(scene, camera);
    }

    // 暴露给Flutter的接口
    window.loadPanorama = function(src) {
      const loader = new THREE.TextureLoader();
      loader.load(src, (texture) => {
        texture.colorSpace = THREE.SRGBColorSpace;
        sphere.material = new THREE.MeshBasicMaterial({ map: texture });
        sphere.material.needsUpdate = true;
      }, undefined, (err) => {
        console.error('加载全景图失败:', err);
      });
    };

    window.setFov = function(newFov) {
      fov = newFov;
      camera.fov = fov;
      camera.updateProjectionMatrix();
    };

    window.resetView = function() {
      targetLon = 0;
      targetLat = 0;
      fov = 75;
      camera.fov = fov;
      camera.updateProjectionMatrix();
    };

    init();
  </script>
</body>
</html>
''';
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
          color: Colors.black.withOpacity(0.5),
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
