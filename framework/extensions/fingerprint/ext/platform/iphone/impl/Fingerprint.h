#import "IFingerprint.h"
#import "FingerprintBase.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface Fingerprint : FingerprintBase<IFingerprint> {
}

-(void) enableFingerprintScan:(id<IMethodResult>)methodResult;

@property (nonatomic, assign) NSString* statusMessage;
@property (nonatomic, assign) NSString* authStatus;

@end