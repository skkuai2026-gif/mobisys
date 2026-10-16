
#import "IPdfgen.h"
#import "PdfgenSingletonBase.h"

@interface PdfgenSingleton : PdfgenSingletonBase<IPdfgenSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end