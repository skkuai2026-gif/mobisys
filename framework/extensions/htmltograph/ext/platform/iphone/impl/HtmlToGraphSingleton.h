
#import "IHtmlToGraph.h"
#import "HtmlToGraphSingletonBase.h"

@interface HtmlToGraphSingleton : HtmlToGraphSingletonBase<IHtmlToGraphSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end