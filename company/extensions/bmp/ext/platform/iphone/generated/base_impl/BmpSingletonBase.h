

#import "IBmp.h"

@interface BmpSingletonBase : NSObject {
    NSString* mDefaultID;
}

-(id)init;

-(NSString*) getDefaultID;
-(void) setDefaultID:(NSString*)defaultID;

-(void)dealloc;

@end