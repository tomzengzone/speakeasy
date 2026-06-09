#ifndef SafePluginRegistrant_h
#define SafePluginRegistrant_h

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface SafePluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END

#endif /* SafePluginRegistrant_h */
