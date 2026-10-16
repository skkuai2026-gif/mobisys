
#import "IFingerprint.h"

@interface FingerprintFactoryBase : NSObject<IFingerprintFactory> {
    NSMutableDictionary* mFingerprintInstances;
    id<IFingerprintSingleton> mFingerprintSingleton;
}

-(id)init;

-(id<IFingerprintSingleton>) getFingerprintSingleton;
-(id<IFingerprint>) getFingerprintByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IFingerprint>)createFingerprintByID:(NSString*)ID;

-(NSArray*) enumerateFingerprintInstances;

-(void)dealloc;

@end