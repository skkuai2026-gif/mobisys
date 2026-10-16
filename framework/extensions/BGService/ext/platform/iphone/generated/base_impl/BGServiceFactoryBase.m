
#import "BGServiceFactoryBase.h"
#import "BGService.h"
#import "BGServiceSingleton.h"



@implementation BGServiceFactoryBase

-(id)init {
    self = [super init];
    mBGServiceInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mBGServiceSingleton = nil;
    return self;
}

-(id<IBGService>) getBGServiceByID:(NSString*)ID {
    id<IBGService> obj = (BGService*)[mBGServiceInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createBGServiceByID:ID];
        [mBGServiceInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    BGService* obj = [mBGServiceInstances objectForKey:ID];
    if (obj != nil) {
        [mBGServiceInstances removeObjectForKey:ID];
    }
}


-(id<IBGService>)createBGServiceByID:(NSString*)ID {
    BGService* obj = [[BGService alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IBGServiceSingleton>) getBGServiceSingleton {
    if (mBGServiceSingleton == nil) {
        mBGServiceSingleton = [[BGServiceSingleton alloc] init];
    }
    return mBGServiceSingleton;
}

-(NSArray*) enumerateBGServiceInstances {
    return [mBGServiceInstances allKeys];
}

-(void)dealloc {
    [mBGServiceInstances release];
    [super dealloc];
}


@end