#import "Fingerprint.h"

@implementation Fingerprint

-(void) enableFingerprintScan:(id<IMethodResult>)methodResult {
	LAContext *myContext = [[LAContext alloc] init];
	NSError *authError = nil;
	NSString *myLocalizedReasonString = @"Authenticate using your finger";

	if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
		[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
			localizedReason:myLocalizedReasonString
			reply:^(BOOL success, NSError *error) {
				if (success) {
					self.statusMessage = @"User is authenticated successfully";
					self.authStatus = @"true";
					[self updateResult:methodResult];
				} else {
					switch (error.code) {
						case LAErrorAuthenticationFailed:
						self.statusMessage = @"Authentication Failed";
						self.authStatus = @"false";
						[self updateResult:methodResult];
						break;

						case LAErrorUserCancel:
						self.statusMessage = @"User pressed Cancel button";
						self.authStatus = @"false";
						[self updateResult:methodResult];
						break;

						case LAErrorUserFallback:
						self.statusMessage = @"User pressed \"Enter Password\"";
						self.authStatus = @"false";
						[self updateResult:methodResult];
						break;

						default:
						self.statusMessage = @"Touch ID is not configured";
						self.authStatus = @"false";
						[self updateResult:methodResult];
						break;
					}
				}
			}];
	} else {
		self.statusMessage = @"Can not evaluate Touch ID";
		self.authStatus = @"false";
		[self updateResult:methodResult];
	}	
}

- (void)updateResult:(id<IMethodResult>)methodResult {
	NSLog(@"%@", self.statusMessage);
	NSLog(@"%@", self.authStatus);
	NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: self.authStatus, @"authStatus", self.statusMessage, @"statusMessage", nil];
	[methodResult setResult:dict];
}

@end