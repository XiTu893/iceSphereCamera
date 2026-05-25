/// 用户模型
class User {
  final int? userId;
  final String? username;
  final String? phone;
  final String? userType;
  final String? token;
  final int? status;
  final String? avatar;

  const User({
    this.userId,
    this.username,
    this.phone,
    this.userType,
    this.token,
    this.status,
    this.avatar,
  });

  /// 从JSON创建用户对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      userType: json['userType'] as String?,
      token: json['token'] as String?,
      status: json['status'] as int?,
      avatar: json['avatar'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'phone': phone,
      'userType': userType,
      'token': token,
      'status': status,
      'avatar': avatar,
    };
  }

  /// 复制并修改部分字段
  User copyWith({
    int? userId,
    String? username,
    String? phone,
    String? userType,
    String? token,
    int? status,
    String? avatar,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      token: token ?? this.token,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
    );
  }

  /// 用户类型显示名称
  String get userTypeLabel {
    switch (userType) {
      case 'OWNER':
        return '房东';
      case 'AGENT':
        return '经纪人';
      case 'ADMIN':
        return '管理员';
      default:
        return '普通用户';
    }
  }

  /// 是否已登录
  bool get isLoggedIn => token != null && token!.isNotEmpty;
}
