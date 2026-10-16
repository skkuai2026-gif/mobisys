
#import "Apptracking.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>


@implementation Apptracking

-(void) requestAppTrackingPermission:(id<IMethodResult>)methodResult {
    if (@available(iOS 14, *)) {
        // Display permission to track
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            switch(status) {
                case ATTrackingManagerAuthorizationStatusNotDetermined :
                    NSLog(@"~~~~Unknown consent");
                    self.status = @"Unknown consent";
                    [self updateResult:methodResult];
                    break;

                case ATTrackingManagerAuthorizationStatusRestricted :
                    NSLog(@"~~~~Device has an MDM solution applied");
                    self.status = @"Device has an MDM solution applied";
                    [self updateResult:methodResult];
                    break;

                case ATTrackingManagerAuthorizationStatusDenied :
                    NSLog(@"~~~~Denied consent");
                    self.status = @"Denied consent";
                    [self updateResult:methodResult];
                    break;

                case ATTrackingManagerAuthorizationStatusAuthorized :
                    NSLog(@"~~~Granted consent");
                    self.status = @"Granted consent";
                    [self updateResult:methodResult];
                    break;

                default :
                    NSLog(@"Unknown");
                    self.status = @"Unknown";
                    [self updateResult:methodResult];
                    break;
            }
        }];
    }

}

- (void)updateResult:(id<IMethodResult>)methodResult {
    NSLog(@"%@", self.status);
    [methodResult setResult:self.status];
}




@end
