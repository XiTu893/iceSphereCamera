import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/house.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

/// 房源表单页面
/// 用于新增或编辑房源信息
class HouseFormPage extends StatefulWidget {
  final House? house;

  const HouseFormPage({super.key, this.house});

  @override
  State<HouseFormPage> createState() => _HouseFormPageState();
}

class _HouseFormPageState extends State<HouseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _communityNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedHouseType = '两室一厅';
  bool _isSubmitting = false;
  bool get _isEditing => widget.house != null;

  /// 户型选项
  final List<String> _houseTypes = [
    '一室一厅',
    '两室一厅',
    '两室两厅',
    '三室一厅',
    '三室两厅',
    '四室两厅',
    '复式',
    '别墅',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    // 编辑模式时填充已有数据
    if (widget.house != null) {
      _communityNameController.text = widget.house!.communityName ?? '';
      _areaController.text = widget.house!.area?.toString() ?? '';
      _priceController.text = widget.house!.price?.toString() ?? '';
      _addressController.text = widget.house!.address ?? '';
      _descriptionController.text = widget.house!.description ?? '';
      _selectedHouseType = widget.house!.houseType ?? '两室一厅';
    }
  }

  @override
  void dispose() {
    _communityNameController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 提交表单
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final houseData = {
        'communityName': _communityNameController.text.trim(),
        'houseType': _selectedHouseType,
        'area': double.tryParse(_areaController.text.trim()) ?? 0,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      if (_isEditing) {
        await ApiService.updateHouse(widget.house!.houseId!, houseData);
      } else {
        await ApiService.createHouse(houseData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '房源更新成功' : '房源创建成功'),
            backgroundColor: ThemeConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：$e'),
            backgroundColor: ThemeConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑房源' : '添加房源'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 小区名称
              TextFormField(
                controller: _communityNameController,
                decoration: const InputDecoration(
                  labelText: '小区名称',
                  prefixIcon: Icon(Icons.apartment, color: ThemeConfig.primaryColor),
                  hintText: '请输入小区名称',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入小区名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 户型选择
              DropdownButtonFormField<String>(
                value: _selectedHouseType,
                decoration: const InputDecoration(
                  labelText: '户型',
                  prefixIcon: Icon(Icons.meeting_room, color: ThemeConfig.primaryColor),
                ),
                items: _houseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHouseType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // 面积
              TextFormField(
                controller: _areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '面积（㎡）',
                  prefixIcon: Icon(Icons.square_foot, color: ThemeConfig.primaryColor),
                  hintText: '请输入面积',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入面积';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return '请输入有效的数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 价格
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '价格（元/月）',
                  prefixIcon: Icon(Icons.attach_money, color: ThemeConfig.primaryColor),
                  hintText: '请输入价格',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入价格';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return '请输入有效的数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 地址
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '地址',
                  prefixIcon: Icon(Icons.location_on_outlined, color: ThemeConfig.primaryColor),
                  hintText: '请输入详细地址',
                ),
              ),
              const SizedBox(height: 16),
              // 描述
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '房源描述',
                  prefixIcon: Icon(Icons.description_outlined, color: ThemeConfig.primaryColor),
                  hintText: '请输入房源描述',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              // 提交按钮
              RoundedButton(
                text: _isEditing ? '保存修改' : '创建房源',
                onPressed: _handleSubmit,
                isLoading: _isSubmitting,
                icon: _isEditing ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
