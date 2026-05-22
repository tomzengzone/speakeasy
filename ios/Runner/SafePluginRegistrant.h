#ifndef SafePluginRegistrant_h
#define SafePluginRegistrant_h

#import <Flutter/Flutter.h>
#import <SingSound/SingSound.h>

NS_ASSUME_NONNULL_BEGIN

@interface SafePluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

typedef void (^AliOralAssessmentResultHandler)(NSDictionary * _Nullable result);
typedef void (^AliOralAssessmentErrorHandler)(NSError * _Nullable error);

@interface AliOralAssessmentDelegateProxy : NSObject <SSOralEvaluatingManagerDelegate>
@property (nonatomic, copy, nullable) AliOralAssessmentResultHandler resultHandler;
@property (nonatomic, copy, nullable) AliOralAssessmentErrorHandler errorHandler;
@end

NS_ASSUME_NONNULL_END

#endif /* SafePluginRegistrant_h */
