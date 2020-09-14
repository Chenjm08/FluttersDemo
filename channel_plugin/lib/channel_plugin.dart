
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';

class ChannelPlugin {
  static const MethodChannel _channel = const MethodChannel('main_channel');
  static bool _initialized = false;

  static Future<Null> initialize({bool debug = true}) async {
    assert(!_initialized, 'FlutterDownloader.initialize() must be called only once!');

    WidgetsFlutterBinding.ensureInitialized();

    final callback = PluginUtilities.getCallbackHandle(callbackDispatcher);
    await _channel.invokeMethod('initialize', <dynamic>[callback.toRawHandle(), debug ? 1 : 0]);
    _initialized = true;
    return null;
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get objcFunction async {
    final String objcStr = await _channel.invokeMethod('objcFunction');
    return objcStr;
  }

  static registerCallback(DownloadCallback callback) {
    print("registerCallback callback=${callback}");
    assert(_initialized, 'DownloadPlugin.initialize() must be called first');

    final callbackHandle = PluginUtilities.getCallbackHandle(callback);
    print("registerCallback callbackHandle=${callbackHandle}");


    assert(callbackHandle != null, 'callback must be a top-level or a static function');
    return _channel.invokeMethod('registerCallback', <dynamic>[callbackHandle.toRawHandle()]);
  }
}

typedef void DownloadCallback(String id, double status, double progress);

void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel callbackChannel = MethodChannel('callback_channel');
  callbackChannel.setMethodCallHandler((MethodCall call) async {
    final List<dynamic> args = call.arguments;

    print("call.arguments=${call.arguments}");

    final Function callback = PluginUtilities.getCallbackFromHandle(CallbackHandle.fromRawHandle(args[0]));

    final String id = args[1];
    final int status = args[2];
    final int progress = args[3];

    callback(id, status, progress);
  });

  callbackChannel.invokeMethod('didInitializeDispatcher');
}