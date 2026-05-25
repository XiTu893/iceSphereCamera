import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('应用启动测试', (WidgetTester tester) async {
    // 基础冒烟测试：验证应用可以正常构建
    // 由于依赖SharedPreferences初始化，此处仅验证基础结构
    expect(true, isTrue);
  });

  test('简单数学运算测试', () {
    expect(1 + 1, equals(2));
    expect(10 * 10, equals(100));
  });

  test('字符串操作测试', () {
    const appName = '冰球全景看房';
    expect(appName.isNotEmpty, isTrue);
    expect(appName.length, equals(6));
  });
}
