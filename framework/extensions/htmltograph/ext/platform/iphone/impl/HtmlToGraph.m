
#import "HtmlToGraph.h"


@implementation HtmlToGraph

@synthesize graphImageBytes, graphId, resultString, webview,webViewLoading;

-(void) getPlatformName:(id<IMethodResult>)methodResult {

}

-(void) getGraphIOS:(NSString*)htmlString methodResult:(id<IMethodResult>)methodResult {
		// NSLog(@"~~~~in HtmlToGraph getGraphIOS");
        // self.callback = methodResult;
        methodResultLocal = methodResult;

      dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       dispatch_sync(dispatch_get_main_queue(), ^{
         NSLog(@"Creating graph from html has been started.");
         self.webViewLoading = NO;
         // NSLog(@"~~htmlString: %@",htmlString);
         
          // NSString* html = htmlString;
          // self.destFilePath  = targetFilePath;
          NSURL*    htmlFileURL     = [NSURL fileURLWithPath:htmlString];
          // Set the base URL to be the www directory.
          NSString* wwwFilePath = [htmlString stringByDeletingLastPathComponent];
          NSURL*    baseURL     = [NSURL fileURLWithPath:wwwFilePath];
         // NSLog(@"~~baseURL: %@",baseURL);
         // NSLog(@"~~wwwFilePath: %@",wwwFilePath);


            WKWebView *webPage = [[WKWebView alloc] init];
            webPage.navigationDelegate = self;
            webPage.UIDelegate = self;
            webPage.frame       = CGRectMake(0, 0, 1, 1); // Make web view small ...
            webPage.alpha       = 0.0;                    // ... and invisible.
            self.webview = webPage;
            [webPage.configuration.preferences setValue:@"TRUE" forKey:@"allowFileAccessFromFileURLs"];

          NSString* htmlString1 = [NSString stringWithContentsOfFile:htmlString encoding:NSUTF8StringEncoding error:nil];
            // [webPage setScalesPageToFit:YES];
          [webPage loadFileURL:htmlFileURL allowingReadAccessToURL:baseURL];
          [webPage loadHTMLString:htmlString1 baseURL:baseURL];
       });
   });


      // wait(2000);
    while (!self.webViewLoading) { wait(1000); } 
    // methodResultLocal = methodResult;
    // NSLog(@"~~~creating dict");

   // NSLog(@"~~self.graphImageBytes 11111: %@", self.graphImageBytes);
   // NSLog(@"~~self.graphId 11111: %@", self.graphId);

   // NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: @"ok", @"status", graphImageBytes, @"html", graphId, @"graphPlaceHolder", nil];

    NSDictionary *dict = @{@"status":@"ok",@"html": self.graphImageBytes,@"graphPlaceHolder":self.graphId};
    // NSDictionary *dict = @{@"status":@"ok",@"html": @"self.graphImageBytes",@"graphPlaceHolder":@"self.graphId"};

    // NSLog(@"~~~updateResult in getGraphIOS");
    [methodResult setResult:dict];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
     // NSLog(@"~~~~in stringByEvaluatingJavaScriptFromString");

        // __block NSString *resultString = nil;
        __block BOOL finished = NO;
        self.resultString = @"";

        [webview evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
            if (error == nil) {
                if (result != nil) {
                    self.resultString = [NSString stringWithFormat:@"%@", result];
                }
            } else {
                  NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);

            }
            finished = YES;
        }];

        while (!finished)
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        return self.resultString;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
   // NSLog(@"~~~~in didFinishNavigation");


   NSString *yourHTMLSourceCodeString = [self stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('graph_png')[0].src"];

   self.graphImageBytes = yourHTMLSourceCodeString;
   // NSLog(@"~~yourHTMLSourceCodeString 11111: %@", yourHTMLSourceCodeString);

   NSString *graphIdString = [self stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('mainWrapper')[0].id"];
   self.graphId = graphIdString;

   // NSLog(@"~~~~in HtmlToGraph 2222 getGraphIOS graphId %@", graphId);

   [webView stopLoading];
   webView.navigationDelegate = nil;
   webView.UIDelegate = nil;
   [webView removeFromSuperview];
   webView = nil;
    self.webViewLoading = YES;

}

-(void) getGraphAndroid:(NSString*)htmlString methodResult:(id<IMethodResult>)methodResult {

}

-(void) calcSumm:(int)a b:(int)b methodResult:(id<IMethodResult>)methodResult {

}

-(void) joinStrings:(NSString*)a b:(NSString*)b methodResult:(id<IMethodResult>)methodResult {

}




@end
