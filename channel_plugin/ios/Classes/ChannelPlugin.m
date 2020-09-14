#import "ChannelPlugin.h"

@implementation ChannelPlugin {
    FlutterEngine *_headlessRunner;
    FlutterMethodChannel *_mainChannel;
    FlutterMethodChannel *_callbackChannel;
    NSObject<FlutterPluginRegistrar> *_registrar;
    int64_t _callbackHandle;
}

static FlutterPluginRegistrantCallback registerPlugins = nil;


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [registrar addApplicationDelegate: [[ChannelPlugin alloc] init:registrar]];
}

+ (void)setPluginRegistrantCallback:(FlutterPluginRegistrantCallback)callback {
  registerPlugins = callback;
}

- (instancetype)init:(NSObject<FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        _headlessRunner = [[FlutterEngine alloc] initWithName:@"FlutterDownloaderIsolate"
                                                      project:nil
                                       allowHeadlessExecution:YES];
        _registrar = registrar;

        _mainChannel = [FlutterMethodChannel
                           methodChannelWithName:@"main_channel"
                           binaryMessenger:[registrar messenger]];
        [registrar addMethodCallDelegate:self channel:_mainChannel];

        _callbackChannel =
        [FlutterMethodChannel methodChannelWithName:@"callback_channel"
                                    binaryMessenger:[_headlessRunner binaryMessenger]];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"objcFunction" isEqualToString:call.method]) {
      NSArray *args = @[@(_callbackHandle), @"100001", @(1), @(11)];
      
      [_callbackChannel invokeMethod:@"" arguments:args];
      
      result(@"调用了objc的函数: objcFunction");
  } else if ([@"didInitializeDispatcher" isEqualToString:call.method]) {
      result(@"调用了objc的函数: didInitializeDispatcher");
  } else if ([@"initialize" isEqualToString:call.method]) {
      NSArray *arguments = call.arguments;
      [self startBackgroundIsolate:[arguments[0] longLongValue]];
      
      result(@"调用了objc的函数: initialize");
  } else if ([@"registerCallback" isEqualToString:call.method]) {
      NSArray *arguments = call.arguments;
      _callbackHandle = [arguments[0] longLongValue];
      result([NSNull null]);
  } else {
      result(FlutterMethodNotImplemented);
  }
}

- (void)startBackgroundIsolate:(int64_t)handle {
    NSLog(@"startBackgroundIsolate:%lld", handle);

    FlutterCallbackInformation *info = [FlutterCallbackCache lookupCallbackInformation:handle];
    NSAssert(info != nil, @"failed to find callback");
    NSString *entrypoint = info.callbackName;
    NSString *uri = info.callbackLibraryPath;
    [_headlessRunner runWithEntrypoint:entrypoint libraryURI:uri];
    NSAssert(registerPlugins != nil, @"failed to set registerPlugins");

    // Once our headless runner has been started, we need to register the application's plugins
    // with the runner in order for them to work on the background isolate. `registerPlugins` is
    // a callback set from AppDelegate.m in the main application. This callback should register
    // all relevant plugins (excluding those which require UI).
    registerPlugins(_headlessRunner);
    [_registrar addMethodCallDelegate:self channel:_callbackChannel];
}


@end
