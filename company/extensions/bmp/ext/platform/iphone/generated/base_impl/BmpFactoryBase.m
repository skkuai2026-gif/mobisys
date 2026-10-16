
#import "BmpFactoryBase.h"
#import "Bmp.h"
#import "BmpSingleton.h"



@implementation BmpFactoryBase

-(id)init {
    self = [super init];
    mBmpInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mBmpSingleton = nil;
    return self;
}

-(id<IBmp>) getBmpByID:(NSString*)ID {
    id<IBmp> obj = (Bmp*)[mBmpInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createBmpByID:ID];
        [mBmpInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    Bmp* obj = [mBmpInstances objectForKey:ID];
    if (obj != nil) {
        [mBmpInstances removeObjectForKey:ID];
    }
}


-(id<IBmp>)createBmpByID:(NSString*)ID {
    Bmp* obj = [[Bmp alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IBmpSingleton>) getBmpSingleton {
    if (mBmpSingleton == nil) {
        mBmpSingleton = [[BmpSingleton alloc] init];
    }
    return mBmpSingleton;
}

-(NSArray*) enumerateBmpInstances {
    return [mBmpInstances allKeys];
}

-(void)dealloc {
    [mBmpInstances release];
    [super dealloc];
}


@end