
#import "IApptracking.h"

@interface ApptrackingFactoryBase : NSObject<IApptrackingFactory> {
    NSMutableDictionary* mApptrackingInstances;
    id<IApptrackingSingleton> mApptrackingSingleton;
}

-(id)init;

-(id<IApptrackingSingleton>) getApptrackingSingleton;
-(id<IApptracking>) getApptrackingByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IApptracking>)createApptrackingByID:(NSString*)ID;

-(NSArray*) enumerateApptrackingInstances;

-(void)dealloc;

@end