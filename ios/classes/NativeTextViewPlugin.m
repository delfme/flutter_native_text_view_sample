#import "NativeTextViewPlugin.h"
#import "NativeTextViewFactory.h"

@implementation NativeTextViewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  NativeTextViewFactory* textFieldFactory =
        [[NativeTextViewFactory alloc] initWithMessenger:registrar.messenger];
    
    [registrar registerViewFactory:textFieldFactory
                            withId:@"flutter_native_text_view"];
}

@end
