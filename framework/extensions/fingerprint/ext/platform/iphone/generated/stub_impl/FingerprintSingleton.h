
#import "IFingerprint.h"
#import "FingerprintSingletonBase.h"

@interface FingerprintSingleton : FingerprintSingletonBase<IFingerprintSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end