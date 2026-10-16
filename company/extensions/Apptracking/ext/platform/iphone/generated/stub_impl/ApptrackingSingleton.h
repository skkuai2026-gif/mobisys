
#import "IApptracking.h"
#import "ApptrackingSingletonBase.h"

@interface ApptrackingSingleton : ApptrackingSingletonBase<IApptrackingSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end