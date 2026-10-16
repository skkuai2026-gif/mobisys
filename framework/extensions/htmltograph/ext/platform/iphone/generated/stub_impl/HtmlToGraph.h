
#import "IHtmlToGraph.h"
#import "HtmlToGraphBase.h"

@interface HtmlToGraph : HtmlToGraphBase<IHtmlToGraph> {
}

-(void) getPlatformName:(id<IMethodResult>)methodResult;
-(void) getGraphIOS:(NSString*)htmlString methodResult:(id<IMethodResult>)methodResult;
-(void) getGraphAndroid:(NSString*)htmlString methodResult:(id<IMethodResult>)methodResult;
-(void) calcSumm:(int)a b:(int)b methodResult:(id<IMethodResult>)methodResult;
-(void) joinStrings:(NSString*)a b:(NSString*)b methodResult:(id<IMethodResult>)methodResult;



@end