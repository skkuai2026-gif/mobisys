
#import "IApptracking.h"
#import "ApptrackingBase.h"

@interface Apptracking : ApptrackingBase<IApptracking> {
}

-(void) requestAppTrackingPermission:(id<IMethodResult>)methodResult;

@property (nonatomic, assign) NSString* status;



@end
