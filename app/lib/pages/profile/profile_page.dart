import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../services/auth_service.dart';
import '../../services/ftp_service.dart';
import '../../widgets/common_widgets.dart';
import '../camera/ftp_settings_page.dart';

/// 个人中心页面
/// 显示用户信息和设置选项
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final user = authService.currentUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 用户信息卡片
                _buildUserCard(user),
                const SizedBox(height: 16),
                // 功能菜单
                _buildMenuSection(),
                const SizedBox(height: 16),
                // 退出登录按钮
                _buildLogoutButton(authService),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard(user) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 头像
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user.username ?? user.phone ?? '用')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username ?? '未设置昵称',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone ?? '未绑定手机号',
                    style: const TextStyle(
                      fontSize: 14,
                      color: ThemeConfig.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TagWidget(
                    text: user.userTypeLabel,
                    color: ThemeConfig.primaryColor,
                  ),
                ],
              ),
            ),
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: ThemeConfig.primaryColor),
              onPressed: () {
                // 编辑个人信息
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能菜单
  Widget _buildMenuSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.home_work_outlined,
            title: '我的房源',
            subtitle: '管理已发布的房源',
            onTap: () {
              // 跳转到我的房源
            },
          ),
          const Divider(height: 1, indent: 56),
          _MenuItem(
            icon: Icons.panorama_photosphere_outlined,
            title: '我的全景',
            subtitle: '查看已创建的全景场景',
            onTap: () {
              // 跳转到我的全景
            },
          ),
          const Divider(height: 1, indent: 56),
          _MenuItem(
            icon: Icons.camera_alt_outlined,
            title: '拍摄设置',
            subtitle: '自动拍摄、拍摄延迟等',
            onTap: () {
              // 跳转到拍摄设置
            },
          ),
          const Divider(height: 1, indent: 56),
          _MenuItem(
            icon: Icons.upload_file,
            title: 'FTP服务器设置',
            subtitle: _getFtpSubtitle(),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FtpSettingsPage()),
              );
              setState(() {}); // 刷新FTP状态显示
            },
          ),
          const Divider(height: 1, indent: 56),
          _MenuItem(
            icon: Icons.help_outline,
            title: '使用帮助',
            subtitle: '全景拍摄教程和常见问题',
            onTap: () {
              // 跳转到帮助页面
            },
          ),
          const Divider(height: 1, indent: 56),
          _MenuItem(
            icon: Icons.info_outline,
            title: '关于我们',
            subtitle: '版本 v1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  /// 获取FTP配置状态描述
  String _getFtpSubtitle() {
    final config = FtpService.getConfig();
    if (config.isConfigured) {
      return '已配置：${config.host}:${config.port}';
    }
    return '未配置，点击配置FTP上传';
  }

  /// 构建退出登录按钮
  Widget _buildLogoutButton(AuthService authService) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('退出登录'),
              content: const Text('确定要退出登录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确定', style: TextStyle(color: ThemeConfig.errorColor)),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) {
            await authService.logout();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeConfig.errorColor,
          side: const BorderSide(color: ThemeConfig.errorColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('退出登录', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.panorama_photosphere,
                color: ThemeConfig.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text('球形全景拍摄'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.0.0'),
            SizedBox(height: 8),
            Text('720度球面全景看房应用'),
            SizedBox(height: 4),
            Text('提供沉浸式全景看房体验，支持全景拍摄、拼接和浏览。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 菜单项组件
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ThemeConfig.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ThemeConfig.textPrimaryColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: ThemeConfig.textHintColor,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: ThemeConfig.textHintColor, size: 20),
      onTap: onTap,
    );
  }
}
