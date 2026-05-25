/// API配置类
/// 管理所有API相关的配置信息
class ApiConfig {
  ApiConfig._();

  // API基础地址 - Android模拟器使用10.0.2.2映射宿主机localhost
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // 连接超时时间（毫秒）
  static const int connectTimeout = 15000;

  // 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;

  // 发送超时时间（毫秒）
  static const int sendTimeout = 15000;

  // ========== 认证相关接口 ==========
  /// 用户登录
  static const String login = '/auth/login';

  /// 用户注册
  static const String register = '/auth/register';

  /// 退出登录
  static const String logout = '/auth/logout';

  // ========== 房源相关接口 ==========
  /// 获取房源列表
  static const String houseList = '/houses';

  /// 获取房源详情
  static String houseDetail(int houseId) => '/houses/$houseId';

  /// 创建房源
  static const String houseCreate = '/houses';

  /// 更新房源
  static String houseUpdate(int houseId) => '/houses/$houseId';

  /// 删除房源
  static String houseDelete(int houseId) => '/houses/$houseId';

  // ========== 全景相关接口 ==========
  /// 获取全景场景列表
  static String panoramaList(int houseId) => '/houses/$houseId/panoramas';

  /// 获取全景详情
  static String panoramaDetail(int panId) => '/panoramas/$panId';

  /// 上传全景图片
  static const String panoramaUpload = '/panoramas/upload';

  /// 创建拼接任务
  static const String stitchingCreate = '/panoramas/stitch';

  /// 查询拼接进度
  static String stitchingProgress(String taskId) =>
      '/panoramas/stitch/$taskId/progress';

  // ========== 用户相关接口 ==========
  /// 获取用户信息
  static const String userProfile = '/user/profile';

  /// 更新用户信息
  static const String userUpdate = '/user/update';
}
