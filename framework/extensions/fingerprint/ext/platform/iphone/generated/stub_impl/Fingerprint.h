
#import "IFingerprint.h"
#import "FingerprintBase.h"

@interface Fingerprint : FingerprintBase<IFingerprint> {
}

-(void) enableFingerprintScan:(id<IMethodResult>)methodResult;



@end