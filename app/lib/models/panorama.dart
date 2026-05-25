/// 全景场景模型
class Panorama {
  final int? panId;
  final int? houseId;
  final String? sceneName;
  final String? panUrl;
  final String? hotData;
  final String? createTime;
  final String? updateTime;
  final String? thumbnailUrl;

  const Panorama({
    this.panId,
    this.houseId,
    this.sceneName,
    this.panUrl,
    this.hotData,
    this.createTime,
    this.updateTime,
    this.thumbnailUrl,
  });

  /// 从JSON创建全景对象
  factory Panorama.fromJson(Map<String, dynamic> json) {
    return Panorama(
      panId: json['panId'] as int?,
      houseId: json['houseId'] as int?,
      sceneName: json['sceneName'] as String?,
      panUrl: json['panUrl'] as String?,
      hotData: json['hotData'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'panId': panId,
      'houseId': houseId,
      'sceneName': sceneName,
      'panUrl': panUrl,
      'hotData': hotData,
      'createTime': createTime,
      'updateTime': updateTime,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// 复制并修改部分字段
  Panorama copyWith({
    int? panId,
    int? houseId,
    String? sceneName,
    String? panUrl,
    String? hotData,
    String? createTime,
    String? updateTime,
    String? thumbnailUrl,
  }) {
    return Panorama(
      panId: panId ?? this.panId,
      houseId: houseId ?? this.houseId,
      sceneName: sceneName ?? this.sceneName,
      panUrl: panUrl ?? this.panUrl,
      hotData: hotData ?? this.hotData,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

/// 拼接任务模型
class StitchingTask {
  final String? taskId;
  final int? houseId;
  final String? sceneName;
  final int? totalImages;
  final int? processedImages;
  final double? progress;
  final String? status;
  final String? resultUrl;
  final String? createTime;
  final String? errorMessage;

  const StitchingTask({
    this.taskId,
    this.houseId,
    this.sceneName,
    this.totalImages,
    this.processedImages,
    this.progress,
    this.status,
    this.resultUrl,
    this.createTime,
    this.errorMessage,
  });

  /// 从JSON创建拼接任务对象
  factory StitchingTask.fromJson(Map<String, dynamic> json) {
    return StitchingTask(
      taskId: json['taskId'] as String?,
      houseId: json['houseId'] as int?,
      sceneName: json['sceneName'] as String?,
      totalImages: json['totalImages'] as int?,
      processedImages: json['processedImages'] as int?,
      progress: (json['progress'] as num?)?.toDouble(),
      status: json['status'] as String?,
      resultUrl: json['resultUrl'] as String?,
      createTime: json['createTime'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'houseId': houseId,
      'sceneName': sceneName,
      'totalImages': totalImages,
      'processedImages': processedImages,
      'progress': progress,
      'status': status,
      'resultUrl': resultUrl,
      'createTime': createTime,
      'errorMessage': errorMessage,
    };
  }

  /// 任务状态显示名称
  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return '等待中';
      case 'PROCESSING':
        return '拼接中';
      case 'COMPLETED':
        return '已完成';
      case 'FAILED':
        return '拼接失败';
      default:
        return '未知';
    }
  }

  /// 是否完成
  bool get isCompleted => status == 'COMPLETED';

  /// 是否失败
  bool get isFailed => status == 'FAILED';

  /// 是否正在处理
  bool get isProcessing => status == 'PROCESSING' || status == 'PENDING';

  /// 进度百分比显示
  String get progressLabel {
    if (progress == null) return '0%';
    return '${(progress! * 100).toStringAsFixed(1)}%';
  }
}
