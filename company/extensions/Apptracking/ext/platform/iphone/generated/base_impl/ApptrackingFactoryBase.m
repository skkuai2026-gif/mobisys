
#import "ApptrackingFactoryBase.h"
#import "Apptracking.h"
#import "ApptrackingSingleton.h"



@implementation ApptrackingFactoryBase

-(id)init {
    self = [super init];
    mApptrackingInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mApptrackingSingleton = nil;
    return self;
}

-(id<IApptracking>) getApptrackingByID:(NSString*)ID {
    id<IApptracking> obj = (Apptracking*)[mApptrackingInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createApptrackingByID:ID];
        [mApptrackingInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    Apptracking* obj = [mApptrackingInstances objectForKey:ID];
    if (obj != nil) {
        [mApptrackingInstances removeObjectForKey:ID];
    }
}


-(id<IApptracking>)createApptrackingByID:(NSString*)ID {
    Apptracking* obj = [[Apptracking alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IApptrackingSingleton>) getApptrackingSingleton {
    if (mApptrackingSingleton == nil) {
        mApptrackingSingleton = [[ApptrackingSingleton alloc] init];
    }
    return mApptrackingSingleton;
}

-(NSArray*) enumerateApptrackingInstances {
    return [mApptrackingInstances allKeys];
}

-(void)dealloc {
    [mApptrackingInstances release];
    [super dealloc];
}


@end