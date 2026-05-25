import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';

/// 3D球面引导组件
/// 在拍摄全景时显示3D球体引导，标记各拍摄位置
class SphereGuideWidget extends StatefulWidget {
  /// 已完成的拍摄位置索引列表
  final List<int> capturedPositions;

  /// 当前需要拍摄的位置索引（-1表示无）
  final int currentPosition;

  /// 陀螺仪旋转角度（弧度）
  final double gyroX;

  /// 陀螺仪旋转角度（弧度）
  final double gyroY;

  /// 球体大小
  final double size;

  /// 拍摄位置总数（水平8个 + 顶部1个 + 底部1个 = 10个）
  final int totalPositions;

  const SphereGuideWidget({
    super.key,
    this.capturedPositions = const [],
    this.currentPosition = -1,
    this.gyroX = 0,
    this.gyroY = 0,
    this.size = 200,
    this.totalPositions = 10,
  });

  @override
  State<SphereGuideWidget> createState() => _SphereGuideWidgetState();
}

class _SphereGuideWidgetState extends State<SphereGuideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // 脉冲动画控制器，用于当前位置标记的脉冲效果
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 获取所有拍摄位置的3D坐标
  /// 水平8个位置（赤道面上每隔45度一个）+ 顶部 + 底部
  List<_SpherePoint> _getShootingPositions() {
    final positions = <_SpherePoint>[];
    const radius = 1.0;

    // 水平8个位置 - 赤道面上每隔45度
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      positions.add(_SpherePoint(
        index: i,
        x: radius * cos(angle),
        y: 0,
        z: radius * sin(angle),
        label: 'H${i + 1}',
      ));
    }

    // 顶部位置
    positions.add(_SpherePoint(
      index: 8,
      x: 0,
      y: radius,
      z: 0,
      label: '顶',
    ));

    // 底部位置
    positions.add(_SpherePoint(
      index: 9,
      x: 0,
      y: -radius,
      z: 0,
      label: '底',
    ));

    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            painter: _SphereGuidePainter(
              capturedPositions: widget.capturedPositions,
              currentPosition: widget.currentPosition,
              gyroX: widget.gyroX,
              gyroY: widget.gyroY,
              pulseValue: _pulseController.value,
              shootingPositions: _getShootingPositions(),
            ),
          );
        },
      ),
    );
  }
}

/// 球面上的点
class _SpherePoint {
  final int index;
  final double x;
  final double y;
  final double z;
  final String label;

  const _SpherePoint({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    required this.label,
  });
}

/// 3D球面引导绘制器
class _SphereGuidePainter extends CustomPainter {
  final List<int> capturedPositions;
  final int currentPosition;
  final double gyroX;
  final double gyroY;
  final double pulseValue;
  final List<_SpherePoint> shootingPositions;

  _SphereGuidePainter({
    required this.capturedPositions,
    required this.currentPosition,
    required this.gyroX,
    required this.gyroY,
    required this.pulseValue,
    required this.shootingPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;

    // 绘制背景半透明圆
    final bgPaint = Paint()
      ..color = const Color(0xFF1A237E).withOpacity( 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 绘制经纬线
    _drawGridLines(canvas, center, radius);

    // 绘制拍摄位置标记
    _drawPositionMarkers(canvas, center, radius);

    // 绘制方向箭头（当前位置指示）
    if (currentPosition >= 0 && currentPosition < shootingPositions.length) {
      _drawDirectionArrow(canvas, center, radius);
    }
  }

  /// 绘制经纬线
  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity( 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 应用陀螺仪旋转
    final rotX = gyroX;
    final rotY = gyroY;

    // 绘制纬线（水平圆环）
    for (int lat = -60; lat <= 60; lat += 30) {
      final latRad = lat * pi / 180;
      final latRadius = radius * cos(latRad);
      final latY = center.dy - radius * sin(latRad);

      final path = Path();
      for (int lon = 0; lon <= 360; lon += 5) {
        final lonRad = lon * pi / 180;
        // 应用Y轴旋转
        final adjustedLon = lonRad + rotY;
        final x = center.dx + latRadius * sin(adjustedLon);
        final y = latY + latRadius * cos(adjustedLon) * sin(rotX) * 0.1;

        // 简单的深度判断：只绘制前半部分
        final z = cos(adjustedLon);
        if (z > -0.2) {
          if (lon == 0 || z < 0.05) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // 绘制经线（垂直圆弧）
    for (int lon = 0; lon < 360; lon += 45) {
      final lonRad = (lon * pi / 180) + rotY;
      final path = Path();
      bool firstPoint = true;

      for (int lat = -90; lat <= 90; lat += 5) {
        final latRad = lat * pi / 180;
        final x = center.dx + radius * cos(latRad) * sin(lonRad);
        final y = center.dy - radius * sin(latRad);
        final z = cos(latRad) * cos(lonRad);

        if (z > -0.1) {
          if (firstPoint) {
            path.moveTo(x, y);
            firstPoint = false;
          } else {
            path.lineTo(x, y);
          }
        } else {
          firstPoint = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // 绘制赤道线（加粗）
    final equatorPaint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity( 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final equatorPath = Path();
    for (int lon = 0; lon <= 360; lon += 3) {
      final lonRad = (lon * pi / 180) + rotY;
      final x = center.dx + radius * sin(lonRad);
      final y = center.dy;
      final z = cos(lonRad);

      if (z > -0.1) {
        if (lon == 0) {
          equatorPath.moveTo(x, y);
        } else {
          equatorPath.lineTo(x, y);
        }
      }
    }
    canvas.drawPath(equatorPath, equatorPaint);
  }

  /// 绘制拍摄位置标记
  void _drawPositionMarkers(Canvas canvas, Offset center, double radius) {
    for (final point in shootingPositions) {
      // 应用陀螺仪旋转
      final rotatedX = _rotateX(point.x, point.y, point.z, rotX: gyroX);
      final rotatedY = _rotateY(point.x, point.y, point.z, rotX: gyroX, rotY: gyroY);
      final rotatedZ = _rotateZ(point.x, point.y, point.z, rotY: gyroY);

      // 3D到2D投影
      final screenX = center.dx + radius * rotatedX;
      final screenY = center.dy - radius * rotatedY;
      final depth = rotatedZ;

      // 只绘制面向观察者的标记
      if (depth < -0.1) continue;

      // 根据深度调整透明度
      final alpha = (0.3 + 0.7 * ((depth + 1) / 2)).clamp(0.0, 1.0);

      final isCaptured = capturedPositions.contains(point.index);
      final isCurrent = point.index == currentPosition;

      if (isCurrent) {
        // 当前位置：蓝色脉冲圆
        _drawCurrentMarker(canvas, screenX, screenY, alpha);
      } else if (isCaptured) {
        // 已拍摄：绿色实心圆
        _drawCapturedMarker(canvas, screenX, screenY, alpha);
      } else {
        // 未拍摄：灰色空心圆
        _drawUncapturedMarker(canvas, screenX, screenY, alpha);
      }

      // 绘制标签
      _drawLabel(canvas, screenX, screenY + 16, point.label, alpha);
    }
  }

  /// 绘制当前位置标记（蓝色脉冲）
  void _drawCurrentMarker(Canvas canvas, double x, double y, double alpha) {
    // 外圈脉冲效果
    final pulseRadius = 12.0 + 8.0 * pulseValue;
    final pulseAlpha = (1.0 - pulseValue) * 0.5 * alpha;
    final pulsePaint = Paint()
      ..color = Color.fromARGB(
        (pulseAlpha * 255).round(),
        30,
        136,
        229,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(x, y), pulseRadius, pulsePaint);

    // 内圈实心
    final innerPaint = Paint()
      ..color = Color.fromARGB(
        (alpha * 255).round(),
        30,
        136,
        229,
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 8, innerPaint);

    // 白色内点
    final dotPaint = Paint()
      ..color = Color.fromARGB(
        (alpha * 255).round(),
        255,
        255,
        255,
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 3, dotPaint);
  }

  /// 绘制已拍摄标记（绿色实心）
  void _drawCapturedMarker(Canvas canvas, double x, double y, double alpha) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (alpha * 255).round(),
        76,
        175,
        80,
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 6, paint);

    // 绘制对勾
    final checkPaint = Paint()
      ..color = Color.fromARGB(
        (alpha * 255).round(),
        255,
        255,
        255,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final checkPath = Path()
      ..moveTo(x - 3, y)
      ..lineTo(x - 1, y + 2.5)
      ..lineTo(x + 3, y - 2);
    canvas.drawPath(checkPath, checkPaint);
  }

  /// 绘制未拍摄标记（灰色空心）
  void _drawUncapturedMarker(Canvas canvas, double x, double y, double alpha) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (alpha * 200).round(),
        158,
        158,
        158,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(x, y), 6, paint);
  }

  /// 绘制方向箭头
  void _drawDirectionArrow(Canvas canvas, Offset center, double radius) {
    if (currentPosition < 0 || currentPosition >= shootingPositions.length) return;

    final point = shootingPositions[currentPosition];
    final rotatedX = _rotateX(point.x, point.y, point.z, rotX: gyroX);
    final rotatedY = _rotateY(point.x, point.y, point.z, rotX: gyroX, rotY: gyroY);

    final targetX = center.dx + radius * rotatedX;
    final targetY = center.dy - radius * rotatedY;

    // 从中心到目标位置绘制箭头
    final arrowPaint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity( 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final direction = Offset(targetX - center.dx, targetY - center.dy);
    final directionLength = direction.distance;
    if (directionLength > 0) {
      final normalizedDirection = direction / directionLength;
      // 箭头起点（距中心一定距离）
      final arrowStart = center + normalizedDirection * 30;
      // 箭头终点（距目标一定距离）
      final arrowEnd = Offset(targetX, targetY) - normalizedDirection * 20;

      canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

      // 箭头头部
      final arrowHeadSize = 8.0;
      final angle = atan2(direction.dy, direction.dx);
      final arrowPath = Path()
        ..moveTo(arrowEnd.dx, arrowEnd.dy)
        ..lineTo(
          arrowEnd.dx - arrowHeadSize * cos(angle - pi / 6),
          arrowEnd.dy - arrowHeadSize * sin(angle - pi / 6),
        )
        ..moveTo(arrowEnd.dx, arrowEnd.dy)
        ..lineTo(
          arrowEnd.dx - arrowHeadSize * cos(angle + pi / 6),
          arrowEnd.dy - arrowHeadSize * sin(angle + pi / 6),
        );
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  /// 绘制文字标签
  void _drawLabel(Canvas canvas, double x, double y, String label, double alpha) {
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: Color.fromARGB((alpha * 220).round(), 255, 255, 255),
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  /// 绕X轴旋转
  double _rotateX(double x, double y, double z, {double rotX = 0}) {
    return x;
  }

  /// 绕Y轴旋转后的Y坐标
  double _rotateY(double x, double y, double z, {double rotX = 0, double rotY = 0}) {
    final cosX = cos(rotX);
    final sinX = sin(rotX);
    return y * cosX - z * sinX;
  }

  /// 绕Y轴旋转后的Z坐标
  double _rotateZ(double x, double y, double z, {double rotY = 0}) {
    final cosY = cos(rotY);
    final sinY = sin(rotY);
    final cosX = cos(rotX);
    final sinX = sin(rotX);
    // 先绕X轴旋转，再绕Y轴旋转
    final y1 = y * cosX - z * sinX;
    final z1 = y * sinX + z * cosX;
    return z1 * cosY + x * sinY;
  }

  @override
  bool shouldRepaint(_SphereGuidePainter oldDelegate) {
    return oldDelegate.capturedPositions != capturedPositions ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.gyroX != gyroX ||
        oldDelegate.gyroY != gyroY ||
        oldDelegate.pulseValue != pulseValue;
  }
}
