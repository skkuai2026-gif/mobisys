
#import "IBGService.h"

@interface BGServiceFactoryBase : NSObject<IBGServiceFactory> {
    NSMutableDictionary* mBGServiceInstances;
    id<IBGServiceSingleton> mBGServiceSingleton;
}

-(id)init;

-(id<IBGServiceSingleton>) getBGServiceSingleton;
-(id<IBGService>) getBGServiceByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IBGService>)createBGServiceByID:(NSString*)ID;

-(NSArray*) enumerateBGServiceInstances;

-(void)dealloc;

@end