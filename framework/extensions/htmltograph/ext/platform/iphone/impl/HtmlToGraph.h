#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "IHtmlToGraph.h"
#import "HtmlToGraphBase.h"

@interface HtmlToGraph : HtmlToGraphBase<IHtmlToGraph> {
	id<IMethodResult> callback;
	id<IMethodResult> * methodResultLocal;
}
@property (readwrite, retain) id<IMethodResult> callback;

-(void) getPlatformName:(id<IMethodResult>)methodResult;
-(void) getGraphIOS:(NSString*)htmlString methodResult:(id<IMethodResult>)methodResult;
-(void) getGraphAndroid:(NSString*)htmlString methodResult:(id<IMethodResult>)methodResult;
-(void) calcSumm:(int)a b:(int)b methodResult:(id<IMethodResult>)methodResult;
-(void) joinStrings:(NSString*)a b:(NSString*)b methodResult:(id<IMethodResult>)methodResult;

@property (nonatomic, assign) BOOL webViewLoading;
@property (nonatomic, strong) NSString* graphImageBytes;
@property (nonatomic, strong) NSString* graphId;
@property (nonatomic, strong) NSString* resultString;
@property (nonatomic,retain) WKWebView *webview;

@end