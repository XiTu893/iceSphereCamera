# 球形全景拍摄 (iceSphereCamera)

720度球形全景拍摄应用，对标贝壳看房全景功能，支持手机引导式拍摄、全景拼接、沉浸式浏览。

## 功能特性

### V1.0 基础版
- **3D引导拍摄** - 球形3D引导动画，陀螺仪辅助定位，自动/手动快门
- **全景拼接** - 云端OpenCV拼接，生成标准2:1等矩形全景图
- **全景浏览** - 手势滑动、缩放，球形全景渲染
- **房源管理** - 房源信息录入、绑定全景场景
- **多种导出方式** - 本地保存、分享到PC、FTP上传、云端拼接
- **用户权限** - 普通用户/经纪人/管理员三级权限

## 项目结构

```
iceSphereCamera/
├── app/                    # Flutter 前端 (iOS/Android)
│   ├── lib/                # Dart 源码
│   │   ├── pages/          # 页面
│   │   ├── widgets/        # 组件（3D球形引导等）
│   │   ├── services/       # 服务（API、FTP、存储）
│   │   ├── models/         # 数据模型
│   │   └── config/         # 配置
│   ├── android/            # Android 原生配置
│   └── ios/                # iOS 原生配置
├── server/                 # SpringBoot 后端
│   └── src/main/java/      # Java 源码
│       └── com/icesphere/camera/
│           ├── controller/  # REST API
│           ├── service/     # 业务逻辑
│           ├── stitching/   # 全景拼接算法
│           └── config/      # 配置
├── doc/                    # 设计文档
└── .github/workflows/      # CI/CD
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 移动端 | Flutter 3.22 |
| 相机采集 | CameraX (Android) / AVFoundation (iOS) |
| 传感器 | sensors_plus (陀螺仪/加速度) |
| 全景浏览 | panorama 插件 |
| 后端 | SpringBoot 2.7.x + MyBatis-Plus |
| 数据库 | MySQL 8.0 + Redis 6.x |
| 鉴权 | Sa-Token |
| 文件存储 | 阿里云OSS / 本地存储 |
| 全景拼接 | JavaCV (OpenCV) ORB特征匹配 |
| FTP上传 | ftpconnect |

## 快速开始

### 前端 (Flutter)

```bash
cd app
flutter pub get
flutter run
```

### 后端 (SpringBoot)

```bash
cd server
mvn clean package -DskipTests
java -jar target/ice-sphere-camera-1.0.0.jar --spring.profiles.active=dev
```

### 环境要求

- Flutter 3.22.0+
- JDK 1.8
- MySQL 8.0
- Redis 6.x

## 拍摄导出模式

拍摄完成后支持4种导出方式：

1. **本地保存** - 图片自动保存在手机本地，可通过USB连接PC获取
2. **分享/导出到PC** - 打包为ZIP，通过系统分享功能传到PC
3. **FTP上传** - 配置FTP服务器后直接批量上传
4. **云端拼接** - 提交到后端进行全景拼接

## 数据库

3张核心表：

- `sys_user` - 用户表（普通用户/经纪人/管理员）
- `house_info` - 房源表（待审核/已上线/已下架）
- `panorama_resource` - 全景资源表（场景名/CDN地址/热点数据）

初始化脚本：[schema.sql](server/src/main/resources/db/schema.sql)

## API接口

| 模块 | 接口 |
|------|------|
| 认证 | 登录 / 注册 / 登出 |
| 房源 | CRUD + 状态管理 + 分页查询 |
| 全景 | 拼接任务 / 进度查询 / 热点管理 |
| 上传 | 单图/多图上传至OSS |

## 开发计划

| 版本 | 内容 |
|------|------|
| V1.0 基础版 | 用户登录、房源管理、3D引导拍摄、本地/云端拼接、全景浏览 |
| V1.1 进阶版 | 云端高清拼接、AI天地补全、热点标注、多场景漫游、VR分屏 |
| V1.2 商业化版 | 防盗链、AI户型图、全景视频、性能优化 |

## 捐赠支持

如果这个项目对您有帮助，欢迎捐赠支持开发：

<div align="center">
  <img src="doc/QrReward.jpg" width="200" alt="捐赠二维码">
</div>

## License

MIT License
