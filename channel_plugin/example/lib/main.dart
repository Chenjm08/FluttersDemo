import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:channel_plugin/channel_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChannelPlugin.initialize(debug: true);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  ReceivePort _port = ReceivePort();
  //static NumberFormat _format = NumberFormat('#.##');

  @override
  void initState() {
    super.initState();
    ChannelPlugin.registerCallback(downloadCallback);
    initPlatformState();
  }

  static void downloadCallback(String id, double status, double progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    print( 'downloadCallback: task ($id) is in status ($status) and process ($progress)');
    send.send([id, status, progress]);
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      print('UI Isolate Callback: $data');

      String id = data[0];
      double status = data[1];
      int progress = data[2];

      print("_port.listen=${id}, ${status}, ${progress}");
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

    // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ChannelPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Center(
            child: Column(
              children: [
                Text('Running on: $_platformVersion\n'),
                FlatButton(onPressed: () async {
                  String text = await ChannelPlugin.objcFunction;
                  print("text=${text}");
                }, child: Text("调原生方法")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
