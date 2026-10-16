
#import "Bmp.h"

#import <AkamaiBMP/CYFMonitor.h>

@implementation Bmp



// -(void) getPlatformName:(id<IMethodResult>)methodResult {
//     [methodResult setResult:@"iOS"];
// }

// -(void) calcSumm:(int)a b:(int)b methodResult:(id<IMethodResult>)methodResult {
//     [methodResult setResult:[NSNumber numberWithInt:(a+b)]];
// }

// -(void) joinStrings:(NSString*)a b:(NSString*)b methodResult:(id<IMethodResult>)methodResult {
//     [methodResult setResult:[a stringByAppendingString:b]];
// }

-(void)sensorDataFetch:(id<IMethodResult>)methodResult {

	NSString *sensorData = [CYFMonitor getSensorData];

	// NSMutableURLRequest *request = [NSMutableURLRequest
	// 	requestWithURL:[NSURL URLWithString:@"http://192.168.200.82:18090/systemcommon"]];

	// [request addValue:sensorData forHTTPHeaderField:@"X-acf-sensor-data"];
	[methodResult setResult:sensorData];
}




@end
