
#import "IBmp.h"

@interface BmpFactoryBase : NSObject<IBmpFactory> {
    NSMutableDictionary* mBmpInstances;
    id<IBmpSingleton> mBmpSingleton;
}

-(id)init;

-(id<IBmpSingleton>) getBmpSingleton;
-(id<IBmp>) getBmpByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IBmp>)createBmpByID:(NSString*)ID;

-(NSArray*) enumerateBmpInstances;

-(void)dealloc;

@end