
#import "IBmp.h"
#import "BmpSingletonBase.h"

@interface BmpSingleton : BmpSingletonBase<IBmpSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end