import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme_config.dart';
import '../../utils/permission_util.dart';
import '../../widgets/sphere_guide_widget.dart';
import '../../widgets/common_widgets.dart';
import '../panorama/stitching_progress_page.dart';

/// 相机引导拍摄页面
/// 这是应用的核心功能页面：
/// - 使用3D球面引导组件显示拍摄位置
/// - 使用传感器获取手机方向
/// - 使用相机插件进行拍摄
/// - 支持自动拍摄（手机到达正确角度时）
/// - 水平360度8个位置 + 顶部 + 底部 = 10个拍摄位置
class CameraGuidePage extends StatefulWidget {
  const CameraGuidePage({super.key});

  @override
  State<CameraGuidePage> createState() => _CameraGuidePageState();
}

class _CameraGuidePageState extends State<CameraGuidePage> {
  // 相机相关
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  String? _cameraError;

  // 传感器相关
  double _gyroX = 0; // 陀螺仪X轴数据（俯仰角）
  double _gyroY = 0; // 陀螺仪Y轴数据（偏航角）
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _magnetometerSubscription;

  // 拍摄状态
  final List<int> _capturedPositions = [];
  int _currentPosition = 0; // 当前需要拍摄的位置索引
  final int _totalPositions = 10; // 总拍摄位置数
  bool _isCapturing = false;
  final List<String> _capturedImagePaths = [];

  // 自动拍摄相关
  bool _autoCapture = true;
  Timer? _autoCaptureTimer;
  bool _isAtCorrectAngle = false;

  // 拍摄位置定义
  // 水平8个位置（0-7）: 赤道面上每隔45度
  // 顶部（8）: 仰角90度
  // 底部（9）: 俯角90度
  final List<_ShootingPosition> _shootingPositions = [];

  @override
  void initState() {
    super.initState();
    _initShootingPositions();
    _initCamera();
    _initSensors();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _autoCaptureTimer?.cancel();
    super.dispose();
  }

  /// 初始化拍摄位置
  void _initShootingPositions() {
    // 水平8个位置
    for (int i = 0; i < 8; i++) {
      _shootingPositions.add(_ShootingPosition(
        index: i,
        targetYaw: i * 45.0, // 偏航角（0, 45, 90, ..., 315度）
        targetPitch: 0.0, // 俯仰角（水平）
        label: '水平${i + 1}',
      ));
    }
    // 顶部
    _shootingPositions.add(_ShootingPosition(
      index: 8,
      targetYaw: 0.0,
      targetPitch: 90.0,
      label: '顶部',
    ));
    // 底部
    _shootingPositions.add(_ShootingPosition(
      index: 9,
      targetYaw: 0.0,
      targetPitch: -90.0,
      label: '底部',
    ));
  }

  /// 初始化相机
  Future<void> _initCamera() async {
    // 请求相机权限
    final hasPermission = await PermissionUtil.requestCamera();
    if (!hasPermission) {
      setState(() {
        _cameraError = '相机权限被拒绝，请在设置中开启';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = '未检测到相机设备';
        });
        return;
      }

      // 使用后置摄像头
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = '相机初始化失败：$e';
      });
    }
  }

  /// 初始化传感器
  void _initSensors() {
    // 使用加速度计和磁力计计算手机方向
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((AccelerometerEvent event) {
      // 简单的方向计算
      setState(() {
        _gyroX = _normalizeAngle(event.x * 0.05 + _gyroX * 0.95);
        _gyroY = _normalizeAngle(event.y * 0.05 + _gyroY * 0.95);
      });
      _checkAutoCapture();
    });

    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((MagnetometerEvent event) {
      // 磁力计辅助方向计算
    });
  }

  /// 角度归一化
  double _normalizeAngle(double angle) {
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return angle;
  }

  /// 检查是否到达正确角度，触发自动拍摄
  void _checkAutoCapture() {
    if (!_autoCapture || _isCapturing || _currentPosition >= _totalPositions) {
      return;
    }

    final position = _shootingPositions[_currentPosition];
    // 计算当前角度与目标角度的偏差
    final yawDiff = (_gyroY - position.targetYaw).abs();
    final pitchDiff = (_gyroX - position.targetPitch).abs();

    // 角度偏差在10度以内视为到达正确位置
    const threshold = 10.0;
    final wasAtCorrectAngle = _isAtCorrectAngle;
    _isAtCorrectAngle = yawDiff < threshold && pitchDiff < threshold;

    // 在正确角度停留1秒后自动拍摄
    if (_isAtCorrectAngle && !wasAtCorrectAngle) {
      _autoCaptureTimer?.cancel();
      _autoCaptureTimer = Timer(const Duration(seconds: 1), () {
        if (_isAtCorrectAngle && !_isCapturing) {
          _capturePhoto();
        }
      });
    } else if (!_isAtCorrectAngle) {
      _autoCaptureTimer?.cancel();
    }
  }

  /// 拍摄照片
  Future<void> _capturePhoto() async {
    if (_isCapturing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();

      // 保存拍摄路径
      _capturedImagePaths.add(photo.path);
      _capturedPositions.add(_currentPosition);

      if (mounted) {
        // 拍摄成功反馈
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已拍摄：${_shootingPositions[_currentPosition].label}'),
            duration: const Duration(seconds: 1),
            backgroundColor: ThemeConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _isCapturing = false;
          // 移动到下一个位置
          if (_currentPosition < _totalPositions - 1) {
            _currentPosition++;
          } else {
            // 所有位置拍摄完成
            _onCaptureComplete();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拍摄失败：$e'),
            backgroundColor: ThemeConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 所有位置拍摄完成
  void _onCaptureComplete() {
    // 导航到拼接进度页面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StitchingProgressPage(
          imagePaths: _capturedImagePaths,
        ),
      ),
    );
  }

  /// 手动拍摄按钮
  void _onManualCapture() {
    _capturePhoto();
  }

  /// 切换自动拍摄
  void _toggleAutoCapture() {
    setState(() {
      _autoCapture = !_autoCapture;
    });
    if (!_autoCapture) {
      _autoCaptureTimer?.cancel();
    }
  }

  /// 重置拍摄
  void _resetCapture() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置拍摄'),
        content: const Text('确定要重置所有拍摄进度吗？已拍摄的照片将被丢弃。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedPositions.clear();
                _capturedImagePaths.clear();
                _currentPosition = 0;
                _isCapturing = false;
              });
            },
            child: const Text('确定', style: TextStyle(color: ThemeConfig.errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 相机预览
          _buildCameraPreview(),
          // 顶部信息栏
          _buildTopBar(),
          // 3D球面引导
          _buildSphereGuide(),
          // 底部控制栏
          _buildBottomControls(),
          // 拍摄进度
          _buildProgressIndicator(),
          // 角度引导提示
          _buildAngleHint(),
        ],
      ),
    );
  }

  /// 构建相机预览
  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              _cameraError!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text('正在初始化相机...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 360,
          height: _cameraController!.value.previewSize?.width ?? 640,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  /// 构建顶部信息栏
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              // 自动拍摄开关
              GestureDetector(
                onTap: _toggleAutoCapture,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _autoCapture
                        ? ThemeConfig.primaryColor.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoCapture ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _autoCapture ? '自动' : '手动',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 重置按钮
              GestureDetector(
                onTap: _resetCapture,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建3D球面引导
  Widget _buildSphereGuide() {
    return Positioned(
      top: 60,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(4),
        child: SphereGuideWidget(
          capturedPositions: _capturedPositions,
          currentPosition: _currentPosition < _totalPositions ? _currentPosition : -1,
          gyroX: _gyroX * 0.01745329, // 角度转弧度
          gyroY: _gyroY * 0.01745329,
          size: 120,
        ),
      ),
    );
  }

  /// 构建底部控制栏
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 当前位置信息
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentPosition < _totalPositions
                          ? _shootingPositions[_currentPosition].label
                          : '拍摄完成',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_currentPosition < _totalPositions)
                      Text(
                        '目标角度：偏航${_shootingPositions[_currentPosition].targetYaw.toStringAsFixed(0)}° '
                        '俯仰${_shootingPositions[_currentPosition].targetPitch.toStringAsFixed(0)}°',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // 拍摄按钮
              GestureDetector(
                onTap: _isCapturing ? null : _onManualCapture,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isAtCorrectAngle && _autoCapture
                          ? ThemeConfig.successColor
                          : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isCapturing
                          ? Colors.grey
                          : _isAtCorrectAngle && _autoCapture
                              ? ThemeConfig.successColor
                              : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // 已拍摄数量
              Expanded(
                child: Text(
                  '${_capturedPositions.length}/$_totalPositions',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建拍摄进度指示器
  Widget _buildProgressIndicator() {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(_totalPositions, (index) {
          final isCaptured = _capturedPositions.contains(index);
          final isCurrent = index == _currentPosition;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isCaptured
                    ? ThemeConfig.successColor
                    : isCurrent
                        ? ThemeConfig.primaryColor
                        : Colors.white24,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建角度引导提示
  Widget _buildAngleHint() {
    if (_currentPosition >= _totalPositions) return const SizedBox.shrink();

    final position = _shootingPositions[_currentPosition];
    return Positioned(
      top: 190,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isAtCorrectAngle
                ? ThemeConfig.successColor.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAtCorrectAngle ? Icons.check_circle : Icons.explore,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isAtCorrectAngle
                    ? '角度正确，正在拍摄...'
                    : '请旋转手机至目标角度',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 拍摄位置定义
class _ShootingPosition {
  final int index;
  final double targetYaw; // 目标偏航角（度）
  final double targetPitch; // 目标俯仰角（度）
  final String label;

  const _ShootingPosition({
    required this.index,
    required this.targetYaw,
    required this.targetPitch,
    required this.label,
  });
}
