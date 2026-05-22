#import "SafePluginRegistrant.h"
#import <SingSound/SingSound.h>

#if __has_include(<audio_session/AudioSessionPlugin.h>)
#import <audio_session/AudioSessionPlugin.h>
#else
@import audio_session;
#endif

#if __has_include(<flutter_local_notifications/FlutterLocalNotificationsPlugin.h>)
#import <flutter_local_notifications/FlutterLocalNotificationsPlugin.h>
#else
@import flutter_local_notifications;
#endif

#if __has_include(<fluwx/FluwxPlugin.h>)
#import <fluwx/FluwxPlugin.h>
#else
@import fluwx;
#endif

#if __has_include(<just_audio/JustAudioPlugin.h>)
#import <just_audio/JustAudioPlugin.h>
#else
@import just_audio;
#endif

#if __has_include(<package_info_plus/FPPPackageInfoPlusPlugin.h>)
#import <package_info_plus/FPPPackageInfoPlusPlugin.h>
#else
@import package_info_plus;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

@implementation SafePluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AudioSessionPlugin registerWithRegistrar:[registry registrarForPlugin:@"AudioSessionPlugin"]];
  [FlutterLocalNotificationsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"]];
  [FluwxPlugin registerWithRegistrar:[registry registrarForPlugin:@"FluwxPlugin"]];
  // in_app_purchase_storekit crashes during plugin registration on the current
  // physical iOS test device. Keep app startup stable until payments are verified.
  [JustAudioPlugin registerWithRegistrar:[registry registrarForPlugin:@"JustAudioPlugin"]];
  [FPPPackageInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPPackageInfoPlusPlugin"]];
  // path_provider_foundation crashes while registering on the current physical
  // iOS 26 test device. Audio temp files use Dart's sandbox temp directory
  // directly, so startup should not depend on this plugin.
  // record_ios crashes during plugin registration on the current physical iOS
  // test device. File recording is handled by AppDelegate's native fallback.
  // sentry_flutter also crashes during cold launch registration on this device.
  // shared_preferences_foundation, sign_in_with_apple, and speech_to_text are
  // Swift-backed plugins that currently crash during cold launch registration.
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
}

@end

@interface AliOralAssessmentDelegateProxy () <SSOralEvaluatingManagerDelegate>
@end

@implementation AliOralAssessmentDelegateProxy

- (void)oralEvaluatingInitSuccess {
  NSLog(@"[AliOralAssessmentProxy] init success");
}

- (void)oralEvaluatingDidStart {
  NSLog(@"[AliOralAssessmentProxy] did start");
}

- (void)oralEvaluatingDidStop {
  NSLog(@"[AliOralAssessmentProxy] did stop");
}

- (void)oralEvaluatingDidEndWithResult:(NSDictionary *)result isLast:(BOOL)isLast {
  NSLog(@"[AliOralAssessmentProxy] result isLast=%@ keys=%@", isLast ? @"true" : @"false", result.allKeys);
  if (self.resultHandler) {
    self.resultHandler(result);
  }
}

- (void)oralEvaluatingDidEndWithResult:(NSDictionary *)result RequestId:(NSString *)request_id {
  NSLog(@"[AliOralAssessmentProxy] result requestId=%@ keys=%@", request_id ?: @"", result.allKeys);
  if (self.resultHandler) {
    self.resultHandler(result);
  }
}

- (void)oralEvaluatingDidEndError:(NSError *)error {
  NSLog(@"[AliOralAssessmentProxy] error %@", error);
  if (self.errorHandler) {
    self.errorHandler(error);
  }
}

- (void)oralEvaluatingDidEndError:(NSError *)error RequestId:(NSString *)request_id {
  NSLog(@"[AliOralAssessmentProxy] error requestId=%@ %@", request_id ?: @"", error);
  if (self.errorHandler) {
    self.errorHandler(error);
  }
}

@end
