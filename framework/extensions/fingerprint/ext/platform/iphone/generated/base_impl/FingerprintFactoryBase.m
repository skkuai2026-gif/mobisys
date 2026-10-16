
#import "FingerprintFactoryBase.h"
#import "Fingerprint.h"
#import "FingerprintSingleton.h"



@implementation FingerprintFactoryBase

-(id)init {
    self = [super init];
    mFingerprintInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mFingerprintSingleton = nil;
    return self;
}

-(id<IFingerprint>) getFingerprintByID:(NSString*)ID {
    id<IFingerprint> obj = (Fingerprint*)[mFingerprintInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createFingerprintByID:ID];
        [mFingerprintInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    Fingerprint* obj = [mFingerprintInstances objectForKey:ID];
    if (obj != nil) {
        [mFingerprintInstances removeObjectForKey:ID];
    }
}


-(id<IFingerprint>)createFingerprintByID:(NSString*)ID {
    Fingerprint* obj = [[Fingerprint alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IFingerprintSingleton>) getFingerprintSingleton {
    if (mFingerprintSingleton == nil) {
        mFingerprintSingleton = [[FingerprintSingleton alloc] init];
    }
    return mFingerprintSingleton;
}

-(NSArray*) enumerateFingerprintInstances {
    return [mFingerprintInstances allKeys];
}

-(void)dealloc {
    [mFingerprintInstances release];
    [super dealloc];
}


@end