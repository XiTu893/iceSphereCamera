import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme_config.dart';
import 'services/auth_service.dart';
import 'pages/splash/splash_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/home/home_page.dart';
import 'pages/house/house_detail_page.dart';
import 'pages/house/house_form_page.dart';
import 'pages/camera/camera_guide_page.dart';
import 'pages/panorama/panorama_viewer_page.dart';
import 'pages/panorama/panorama_upload_page.dart';
import 'pages/panorama/stitching_progress_page.dart';
import 'pages/profile/profile_page.dart';

class IceSphereApp extends StatelessWidget {
  const IceSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '冰球全景看房',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.light,
      // 初始路由为启动页
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/house_detail': (context) => const HouseDetailPage(),
        '/house_form': (context) => const HouseFormPage(),
        '/camera_guide': (context) => const CameraGuidePage(),
        '/panorama_viewer': (context) => const PanoramaViewerPage(),
        '/panorama_upload': (context) => const PanoramaUploadPage(),
        '/stitching_progress': (context) => const StitchingProgressPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
