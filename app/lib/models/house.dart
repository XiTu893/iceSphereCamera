/// 房源模型
class House {
  final int? houseId;
  final int? userId;
  final String? communityName;
  final String? houseType;
  final double? area;
  final double? price;
  final int? status;
  final String? createTime;
  final String? updateTime;
  final String? description;
  final String? address;
  final int? panoramaCount;

  const House({
    this.houseId,
    this.userId,
    this.communityName,
    this.houseType,
    this.area,
    this.price,
    this.status,
    this.createTime,
    this.updateTime,
    this.description,
    this.address,
    this.panoramaCount,
  });

  /// 从JSON创建房源对象
  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      houseId: json['houseId'] as int?,
      userId: json['userId'] as int?,
      communityName: json['communityName'] as String?,
      houseType: json['houseType'] as String?,
      area: (json['area'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      status: json['status'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      panoramaCount: json['panoramaCount'] as int?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'houseId': houseId,
      'userId': userId,
      'communityName': communityName,
      'houseType': houseType,
      'area': area,
      'price': price,
      'status': status,
      'createTime': createTime,
      'updateTime': updateTime,
      'description': description,
      'address': address,
      'panoramaCount': panoramaCount,
    };
  }

  /// 复制并修改部分字段
  House copyWith({
    int? houseId,
    int? userId,
    String? communityName,
    String? houseType,
    double? area,
    double? price,
    int? status,
    String? createTime,
    String? updateTime,
    String? description,
    String? address,
    int? panoramaCount,
  }) {
    return House(
      houseId: houseId ?? this.houseId,
      userId: userId ?? this.userId,
      communityName: communityName ?? this.communityName,
      houseType: houseType ?? this.houseType,
      area: area ?? this.area,
      price: price ?? this.price,
      status: status ?? this.status,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      description: description ?? this.description,
      address: address ?? this.address,
      panoramaCount: panoramaCount ?? this.panoramaCount,
    );
  }

  /// 房源状态显示名称
  String get statusLabel {
    switch (status) {
      case 0:
        return '草稿';
      case 1:
        return '已发布';
      case 2:
        return '已下架';
      default:
        return '未知';
    }
  }

  /// 格式化价格显示
  String get priceLabel {
    if (price == null) return '价格面议';
    if (price! >= 10000) {
      return '${(price! / 10000).toStringAsFixed(1)}万';
    }
    return '${price!.toStringAsFixed(0)}元/月';
  }

  /// 格式化面积显示
  String get areaLabel {
    if (area == null) return '未知';
    return '${area!.toStringAsFixed(1)}㎡';
  }
}
