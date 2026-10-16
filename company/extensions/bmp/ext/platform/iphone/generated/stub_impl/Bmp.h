
#import "IBmp.h"
#import "BmpBase.h"

@interface Bmp : BmpBase<IBmp> {
}

-(void) sensorDataFetch:(id<IMethodResult>)methodResult;



@end