
#import "IBGService.h"
#import "BGServiceSingletonBase.h"

@interface BGServiceSingleton : BGServiceSingletonBase<IBGServiceSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end