#import "BGService.h"

@implementation BGService

-(void) startBackgroundService:(NSString*)bgServiceRubyFunc methodResult:(id<IMethodResult>)methodResult {
    [methodResult setResult:@"iOS"];
}

-(void) stopBackgroundService:(id<IMethodResult>)methodResult {
    [methodResult setResult:@"iOS"];
}

-(void) checkBackgroundServiceStatus:(id<IMethodResult>)methodResult {
    [methodResult setResult:@"iOS"];
}

@end