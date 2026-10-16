

#import "IFingerprint.h"

@interface FingerprintSingletonBase : NSObject {
    NSString* mDefaultID;
}

-(id)init;

-(NSString*) getDefaultID;
-(void) setDefaultID:(NSString*)defaultID;

-(void)dealloc;

@end