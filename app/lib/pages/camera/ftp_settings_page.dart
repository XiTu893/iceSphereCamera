import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/ftp_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common_widgets.dart';

/// FTP配置页面
/// 用户可在此配置FTP服务器连接信息
class FtpSettingsPage extends StatefulWidget {
  const FtpSettingsPage({super.key});

  @override
  State<FtpSettingsPage> createState() => _FtpSettingsPageState();
}

class _FtpSettingsPageState extends State<FtpSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remoteDirController = TextEditingController(text: '/panorama');

  bool _isTesting = false;
  bool? _testResult;
  String _testMessage = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remoteDirController.dispose();
    super.dispose();
  }

  /// 加载已保存的FTP配置
  void _loadConfig() {
    final config = FtpService.getConfig();
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _remoteDirController.text = config.remoteDir;
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final config = FtpConfig(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 21,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remoteDir: _remoteDirController.text.trim(),
    );

    await FtpService.saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FTP配置已保存'),
          backgroundColor: ThemeConfig.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  /// 测试连接
  Future<void> _testConnection() async {
    if (_hostController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入FTP服务器地址'),
          backgroundColor: ThemeConfig.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testMessage = '';
    });

    final config = FtpConfig(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 21,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remoteDir: _remoteDirController.text.trim(),
    );

    final result = await FtpService.testConnection(config);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
        _testMessage = result ? '连接成功' : '连接失败，请检查配置';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTP服务器配置'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 说明信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConfig.infoColor.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: ThemeConfig.infoColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '配置FTP服务器后，可将拍摄的全景图片直接上传到指定服务器目录，方便在PC端进行后期处理。',
                        style: TextStyle(
                          color: ThemeConfig.infoColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 服务器地址
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  prefixIcon: Icon(Icons.dns, color: ThemeConfig.primaryColor),
                  hintText: '例如：192.168.1.100 或 ftp.example.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入服务器地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 端口
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口',
                  prefixIcon: Icon(Icons.numbers, color: ThemeConfig.primaryColor),
                  hintText: '默认21',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final port = int.tryParse(value);
                    if (port == null || port < 1 || port > 65535) {
                      return '请输入有效端口号(1-65535)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 用户名
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(Icons.person, color: ThemeConfig.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              // 密码
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock, color: ThemeConfig.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: ThemeConfig.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 远程目录
              TextFormField(
                controller: _remoteDirController,
                decoration: const InputDecoration(
                  labelText: '远程目录',
                  prefixIcon: Icon(Icons.folder, color: ThemeConfig.primaryColor),
                  hintText: '上传文件的远程目录路径',
                ),
              ),
              const SizedBox(height: 24),
              // 测试连接按钮
              RoundedButton(
                text: '测试连接',
                onPressed: _isTesting ? null : () => _testConnection(),
                icon: Icons.network_check,
                color: Colors.teal,
                isLoading: _isTesting,
              ),
              // 测试结果
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testResult!
                        ? ThemeConfig.successColor.withOpacity( 0.1)
                        : ThemeConfig.errorColor.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testResult! ? Icons.check_circle : Icons.error,
                        color: _testResult!
                            ? ThemeConfig.successColor
                            : ThemeConfig.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _testMessage,
                        style: TextStyle(
                          color: _testResult!
                              ? ThemeConfig.successColor
                              : ThemeConfig.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // 保存按钮
              RoundedButton(
                text: '保存配置',
                onPressed: _saveConfig,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
