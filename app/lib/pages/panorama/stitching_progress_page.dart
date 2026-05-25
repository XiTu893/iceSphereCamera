import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/theme_config.dart';
import '../../models/panorama.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'panorama_viewer_page.dart';

/// 拼接进度页面
/// 显示全景图片拼接进度，轮询后端获取状态
class StitchingProgressPage extends StatefulWidget {
  /// 拼接任务ID
  final String? taskId;

  /// 已拍摄的图片路径列表
  final List<String> imagePaths;

  const StitchingProgressPage({
    super.key,
    this.taskId,
    this.imagePaths = const [],
  });

  @override
  State<StitchingProgressPage> createState() => _StitchingProgressPageState();
}

class _StitchingProgressPageState extends State<StitchingProgressPage>
    with TickerProviderStateMixin {
  StitchingTask? _task;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  // 动画控制器
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // 如果有任务ID，开始轮询
    if (widget.taskId != null) {
      _startPolling();
    } else {
      // 没有任务ID，模拟进度
      _simulateProgress();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  /// 开始轮询拼接进度
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _fetchProgress();
    });
    // 立即查询一次
    _fetchProgress();
  }

  /// 获取拼接进度
  Future<void> _fetchProgress() async {
    if (widget.taskId == null) return;

    try {
      final task = await ApiService.getStitchingProgress(widget.taskId!);
      if (mounted) {
        setState(() {
          _task = task;
          _isLoading = false;
        });

        // 更新进度动画
        final targetProgress = task.progress ?? 0;
        _progressAnimation = Tween<double>(
          begin: _progressAnimation.value,
          end: targetProgress,
        ).animate(CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeInOut,
        ));
        _progressController.forward(from: 0);

        // 拼接完成或失败时停止轮询
        if (task.isCompleted || task.isFailed) {
          _pollTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// 模拟拼接进度（无任务ID时使用）
  void _simulateProgress() {
    setState(() {
      _isLoading = false;
      _task = StitchingTask(
        taskId: 'local',
        status: 'PROCESSING',
        progress: 0,
        totalImages: widget.imagePaths.length,
        processedImages: 0,
      );
    });

    double progress = 0;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      progress += 0.05;
      if (progress >= 1.0) {
        progress = 1.0;
        timer.cancel();
        setState(() {
          _task = _task!.copyWith(
            progress: 1.0,
            status: 'COMPLETED',
            processedImages: widget.imagePaths.length,
          );
        });
      } else {
        setState(() {
          _task = _task!.copyWith(
            progress: progress,
            processedImages: (progress * widget.imagePaths.length).round(),
          );
        });
      }

      // 更新进度动画
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.forward(from: 0);
    });
  }

  /// 查看拼接结果
  void _viewResult() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanoramaViewerPage(
          panoramaUrl: _task?.resultUrl,
          sceneName: '拼接结果',
        ),
      ),
    );
  }

  /// 返回首页
  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全景拼接'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: '正在准备拼接任务...');
    }

    if (_error != null && _task == null) {
      return ErrorState(
        message: '加载拼接进度失败：$_error',
        onRetry: _fetchProgress,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // 进度动画
          _buildProgressAnimation(),
          const SizedBox(height: 32),
          // 状态信息
          _buildStatusInfo(),
          const Spacer(flex: 1),
          // 操作按钮
          _buildActions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 构建进度动画
  Widget _buildProgressAnimation() {
    final isCompleted = _task?.isCompleted ?? false;
    final isFailed = _task?.isFailed ?? false;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度环
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(180, 180),
                painter: _ProgressRingPainter(
                  progress: _progressAnimation.value,
                  color: isFailed
                      ? ThemeConfig.errorColor
                      : isCompleted
                          ? ThemeConfig.successColor
                          : ThemeConfig.primaryColor,
                ),
              );
            },
          ),
          // 中心内容
          if (isFailed)
            const Icon(Icons.error_outline, size: 48, color: ThemeConfig.errorColor)
          else if (isCompleted)
            const Icon(Icons.check_circle_outline, size: 48, color: ThemeConfig.successColor)
          else
            SpinKitFoldingCube(
              color: ThemeConfig.primaryColor,
              size: 36,
            ),
        ],
      ),
    );
  }

  /// 构建状态信息
  Widget _buildStatusInfo() {
    final isCompleted = _task?.isCompleted ?? false;
    final isFailed = _task?.isFailed ?? false;

    return Column(
      children: [
        Text(
          isFailed
              ? '拼接失败'
              : isCompleted
                  ? '拼接完成'
                  : '正在拼接全景图片...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isFailed
                ? ThemeConfig.errorColor
                : isCompleted
                    ? ThemeConfig.successColor
                    : ThemeConfig.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isFailed
              ? (_task?.errorMessage ?? '拼接过程中出现错误，请重试')
              : isCompleted
                  ? '全景图片已成功生成，点击查看结果'
                  : _task?.progressLabel ?? '0%',
          style: TextStyle(
            fontSize: 14,
            color: isFailed
                ? ThemeConfig.errorColor
                : ThemeConfig.textSecondaryColor,
          ),
        ),
        if (!isCompleted && !isFailed && _task?.totalImages != null) ...[
          const SizedBox(height: 4),
          Text(
            '已处理 ${_task?.processedImages ?? 0} / ${_task?.totalImages ?? 0} 张图片',
            style: const TextStyle(
              fontSize: 12,
              color: ThemeConfig.textHintColor,
            ),
          ),
        ],
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActions() {
    final isCompleted = _task?.isCompleted ?? false;
    final isFailed = _task?.isFailed ?? false;

    if (isCompleted) {
      return Column(
        children: [
          RoundedButton(
            text: '查看全景',
            onPressed: _viewResult,
            icon: Icons.panorama,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _goHome,
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

    if (isFailed) {
      return Column(
        children: [
          RoundedButton(
            text: '重新拼接',
            onPressed: () {
              // 重新提交拼接任务
            },
            icon: Icons.refresh,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _goHome,
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

    // 正在处理中
    return OutlinedButton(
      onPressed: _goHome,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text('后台处理，返回首页'),
    );
  }
}

/// 进度环绘制器
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // 背景环
    final bgPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14159265,
      false,
      bgPaint,
    );

    // 进度环
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      2 * 3.14159265 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
