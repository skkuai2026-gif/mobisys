#import "IBGService.h"
#import "BGServiceBase.h"

@interface BGService : BGServiceBase<IBGService> {
}

-(void) startBackgroundService:(NSString*)bgServiceRubyFunc methodResult:(id<IMethodResult>)methodResult;
-(void) stopBackgroundService:(id<IMethodResult>)methodResult;
-(void) checkBackgroundServiceStatus:(id<IMethodResult>)methodResult;

@end