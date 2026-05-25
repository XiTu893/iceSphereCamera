import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/house.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'house_detail_page.dart';
import 'house_form_page.dart';

/// 房源列表页面
/// 展示房源卡片列表，支持下拉刷新和添加房源
class HouseListPage extends StatefulWidget {
  const HouseListPage({super.key});

  @override
  State<HouseListPage> createState() => _HouseListPageState();
}

class _HouseListPageState extends State<HouseListPage> {
  List<House> _houses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  /// 加载房源列表
  Future<void> _loadHouses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final houses = await ApiService.getHouseList(
        page: _currentPage,
        size: 20,
      );
      if (mounted) {
        setState(() {
          if (refresh) {
            _houses = houses;
          } else {
            _houses.addAll(houses);
          }
          _isLoading = false;
          _hasMore = houses.length >= 20;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _loadHouses(refresh: true);
  }

  /// 跳转到房源详情
  void _navigateToDetail(House house) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseDetailPage(houseId: house.houseId!),
      ),
    );
  }

  /// 跳转到添加房源
  void _navigateToAddHouse() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HouseFormPage(),
      ),
    );
    if (result == true) {
      _loadHouses(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的房源'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 搜索功能
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHouse,
        tooltip: '添加房源',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建页面主体
  Widget _buildBody() {
    if (_isLoading && _houses.isEmpty) {
      return const LoadingIndicator(message: '加载房源列表...');
    }

    if (_hasError && _houses.isEmpty) {
      return ErrorState(
        message: _errorMessage ?? '加载房源列表失败',
        onRetry: () => _loadHouses(refresh: true),
      );
    }

    if (_houses.isEmpty) {
      return EmptyState(
        icon: Icons.home_work_outlined,
        message: '暂无房源，点击右下角按钮添加',
      );
    }

    return RefreshIndicator(
      color: ThemeConfig.primaryColor,
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _houses.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _houses.length) {
            // 加载更多指示器
            _loadHouses();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _HouseCard(
            house: _houses[index],
            onTap: () => _navigateToDetail(_houses[index]),
          );
        },
      ),
    );
  }
}

/// 房源卡片组件
class _HouseCard extends StatelessWidget {
  final House house;
  final VoidCallback onTap;

  const _HouseCard({
    required this.house,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 小区名称和状态
              Row(
                children: [
                  Expanded(
                    child: Text(
                      house.communityName ?? '未命名房源',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.textPrimaryColor,
                      ),
                    ),
                  ),
                  TagWidget(
                    text: house.statusLabel,
                    color: house.status == 1
                        ? ThemeConfig.successColor
                        : ThemeConfig.textSecondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 房源信息行
              Row(
                children: [
                  _InfoChip(icon: Icons.apartment, text: house.houseType ?? '未知'),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.square_foot, text: house.areaLabel),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.panorama, text: '${house.panoramaCount ?? 0}个全景'),
                ],
              ),
              const SizedBox(height: 10),
              // 价格
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    house.priceLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 信息标签组件
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ThemeConfig.textSecondaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: ThemeConfig.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
