import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:channel_plugin/channel_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('channel_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ChannelPlugin.platformVersion, '42');
  });
}
