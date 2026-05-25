import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/house.dart';
import '../../models/panorama.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../panorama/panorama_viewer_page.dart';
import '../panorama/panorama_upload_page.dart';
import 'house_form_page.dart';

/// 房源详情页面
/// 展示房源信息和全景场景列表，点击场景可查看全景
class HouseDetailPage extends StatefulWidget {
  final int houseId;

  const HouseDetailPage({super.key, required this.houseId});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  House? _house;
  List<Panorama> _panoramas = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载房源详情和全景列表
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final house = await ApiService.getHouseDetail(widget.houseId);
      final panoramas = await ApiService.getPanoramaList(widget.houseId);
      if (mounted) {
        setState(() {
          _house = house;
          _panoramas = panoramas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// 跳转到全景查看页面
  void _navigateToViewer(Panorama panorama) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanoramaViewerPage(
          panoramaUrl: panorama.panUrl,
          sceneName: panorama.sceneName,
        ),
      ),
    );
  }

  /// 跳转到全景上传页面
  void _navigateToUpload() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanoramaUploadPage(houseId: widget.houseId),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  /// 跳转到编辑房源
  void _navigateToEdit() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseFormPage(house: _house),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('房源详情'),
        actions: [
          if (_house != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _navigateToEdit,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _house != null
          ? FloatingActionButton.extended(
              onPressed: _navigateToUpload,
              icon: const Icon(Icons.panorama),
              label: const Text('添加全景'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: '加载房源详情...');
    }

    if (_hasError || _house == null) {
      return ErrorState(
        message: '加载房源详情失败',
        onRetry: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 房源基本信息卡片
            _buildHouseInfoCard(),
            const SizedBox(height: 20),
            // 全景场景列表
            _buildPanoramaSection(),
          ],
        ),
      ),
    );
  }

  /// 构建房源信息卡片
  Widget _buildHouseInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 小区名称和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    _house!.communityName ?? '未命名房源',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textPrimaryColor,
                    ),
                  ),
                ),
                TagWidget(
                  text: _house!.statusLabel,
                  color: _house!.status == 1
                      ? ThemeConfig.successColor
                      : ThemeConfig.textSecondaryColor,
                ),
              ],
            ),
            const Divider(height: 24),
            // 详细信息
            InfoRow(label: '户型', value: _house!.houseType ?? '未知'),
            InfoRow(label: '面积', value: _house!.areaLabel),
            InfoRow(
              label: '价格',
              value: _house!.priceLabel,
              valueStyle: const TextStyle(
                color: ThemeConfig.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_house!.address != null)
              InfoRow(label: '地址', value: _house!.address!),
            if _house!.description != null) ...[
              const SizedBox(height: 8),
              const Text(
                '房源描述',
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeConfig.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _house!.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: ThemeConfig.textPrimaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建全景场景区域
  Widget _buildPanoramaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '全景场景',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_panoramas.length}',
                style: const TextStyle(
                  color: ThemeConfig.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_panoramas.isEmpty)
          const EmptyState(
            icon: Icons.panorama_photosphere_outlined,
            message: '暂无全景场景',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _panoramas.length,
            itemBuilder: (context, index) {
              return _PanoramaSceneCard(
                panorama: _panoramas[index],
                onTap: () => _navigateToViewer(_panoramas[index]),
              );
            },
          ),
      ],
    );
  }
}

/// 全景场景卡片
class _PanoramaSceneCard extends StatelessWidget {
  final Panorama panorama;
  final VoidCallback onTap;

  const _PanoramaSceneCard({
    required this.panorama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 缩略图区域
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.panorama_photosphere,
                    size: 40,
                    color: ThemeConfig.primaryColor,
                  ),
                ),
              ),
            ),
            // 场景名称
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                panorama.sceneName ?? '未命名场景',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ThemeConfig.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
