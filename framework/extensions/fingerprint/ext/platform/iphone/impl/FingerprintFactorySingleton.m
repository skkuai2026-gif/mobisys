
#import "IFingerprint.h"
#import "FingerprintFactoryBase.h"

static FingerprintFactoryBase* ourFingerprintFactory = nil;

@implementation FingerprintFactorySingleton

+(id<IFingerprintFactory>) getFingerprintFactoryInstance {
    if (ourFingerprintFactory == nil) {
        ourFingerprintFactory = [[FingerprintFactoryBase alloc] init];
    }
    return ourFingerprintFactory;
}

@end