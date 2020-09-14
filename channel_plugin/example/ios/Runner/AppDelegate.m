#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <channel_plugin/ChannelPlugin.h>

@implementation AppDelegate

void registerPlugins(NSObject<FlutterPluginRegistry>* registry) {
    if (![registry hasPlugin:@"ChannelPlugin"]) {
        [ChannelPlugin registerWithRegistrar:[registry registrarForPlugin:@"ChannelPlugin"]];
    }
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    [ChannelPlugin setPluginRegistrantCallback:registerPlugins];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
