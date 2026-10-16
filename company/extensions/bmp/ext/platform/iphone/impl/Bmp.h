#import "IBmp.h"
#import "BmpBase.h"


@interface Bmp : BmpBase<IBmp> {
}

// -(void) getPlatformName:(id<IMethodResult>)methodResult;
// -(void) calcSumm:(int)a b:(int)b methodResult:(id<IMethodResult>)methodResult;
// -(void) joinStrings:(NSString*)a b:(NSString*)b methodResult:(id<IMethodResult>)methodResult;
-(void) sensorDataFetch:(id<IMethodResult>)methodResult;



@end
