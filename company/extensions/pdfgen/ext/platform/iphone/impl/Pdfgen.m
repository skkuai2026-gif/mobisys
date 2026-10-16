#import "Pdfgen.h"
#import "../../iphone/Classes/AppManager/AppManager.h"

@interface UIPrintPageRenderer (PDF)

- (NSData*) printToPDF;

@end



@implementation Pdfgen

@synthesize destFilePath, outputPageSize, pageMargins, webViewLoading;


//Method to generate pdf file from HTML file
-(void) generateIOSPDF:(NSString*)htmlContent targetFilePath:(NSString*)targetFilePath methodResult:(id<IMethodResult>)methodResult {
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"Creating pdf from html has been started.");
            self.webViewLoading = NO;
            
            NSString* html = htmlContent;
            self.destFilePath  = targetFilePath;
            NSURL*    htmlFileURL     = [NSURL fileURLWithPath:htmlContent];
           
            // Set the base URL to be the www directory.
            NSString* wwwFilePath = [htmlContent stringByDeletingLastPathComponent];
            NSURL*    baseURL     = [NSURL fileURLWithPath:wwwFilePath];
           
            // define page size and margins
            self.outputPageSize = kPaperSizeLetter;
            self.pageMargins = UIEdgeInsetsMake(10, 10, 10, 10);

            // Load page into a webview and use its formatter to print the page
            WKWebView* webPage  = [[WKWebView alloc] init];
            webPage.navigationDelegate  = self;
            webPage.UIDelegate = self;
           
            webPage.frame       = CGRectMake(0, 0, 1, 1); // Make web view small ...
            webPage.alpha       = 0.0;                    // ... and invisible.
            
            [webPage.configuration.preferences setValue:@"TRUE" forKey:@"allowFileAccessFromFileURLs"];

            NSString* htmlString = [NSString stringWithContentsOfFile:htmlContent encoding:NSUTF8StringEncoding error:nil];
           
            [webPage loadFileURL:htmlFileURL allowingReadAccessToURL:baseURL];
           
            // [webPage setScalesPageToFit:YES];
            [webPage loadHTMLString:htmlString baseURL:baseURL];
        });
    });
    
    while (!self.webViewLoading) { wait(1000); } 
    [methodResult setResult:@"generateIOSPDF completed"];
    // [self generateSamplePDF:self.destFilePath];
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"Pdfgen didFinishNavigation");
    NSString *currentURL = webView.URL.absoluteString;
    NSLog(@"%@", currentURL);
    
    UIPrintPageRenderer *render = [[UIPrintPageRenderer alloc] init];
    render.headerHeight = render.footerHeight = 0;
    [render addPrintFormatter:webView.viewPrintFormatter startingAtPageAtIndex:0];

    /*CGRect printableRect = CGRectMake(self.pageMargins.left,
                                      self.pageMargins.top,
                                      self.outputPageSize.width - self.pageMargins.left - self.pageMargins.right,
                                      self.outputPageSize.height - self.pageMargins.top - self.pageMargins.bottom);*/
    CGRect printableRect = CGRectMake(0,
                                      0,
                                      self.outputPageSize.width,
                                      self.outputPageSize.height);
    CGRect paperRect = CGRectMake(0, 0, self.outputPageSize.width, self.outputPageSize.height);
    
    [render setValue:[NSValue valueWithCGRect:paperRect] forKey:@"paperRect"];
    [render setValue:[NSValue valueWithCGRect:printableRect] forKey:@"printableRect"];
    
    if (self.destFilePath) {
        [[render printToPDF] writeToFile: self.destFilePath atomically: YES];
    }
    
    // remove webPage
    [webView stopLoading];
    webView.navigationDelegate = nil;
    [webView removeFromSuperview];
    webView = nil;

    // trigger success response
    NSString* resultMsg = [NSString stringWithFormat:@"HTMLtoPDF did succeed (%@)", self.destFilePath];
    NSLog(@"%@",resultMsg);

    self.webViewLoading = YES;
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailNavigation");
}


//Method to merge multiple pdf files
-(void) mergeIOSPDF:(NSString*)listOfPaths targetFilePath:(NSString*)targetFilePath masterPassword:(NSString*)masterPassword password:(NSString*)password methodResult:(id<IMethodResult>)methodResult {

    // File paths
    NSString *pdfPathOutput = targetFilePath;
    CFURLRef pdfURLOutput = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:pdfPathOutput]);

    NSArray *listOfFiles = [listOfPaths componentsSeparatedByString:@"|"];
    NSInteger numberOfPages = 0;

    CGContextRef writeContext;
    // Set Password
    if(![password isEqualToString:@""]) {
        // NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:nil, nil, kCFBooleanFalse, kCGPDFContextAllowsCopying, kCFBooleanTrue, kCGPDFContextAllowsPrinting, nil];

        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"c2lbiz", kCGPDFContextOwnerPassword, password, kCGPDFContextUserPassword, kCFBooleanFalse, kCGPDFContextAllowsCopying, kCFBooleanTrue, kCGPDFContextAllowsPrinting, nil];
        
        // Create the output context
        writeContext = CGPDFContextCreateWithURL(pdfURLOutput, NULL, dictionary);
    }
    else {
        writeContext = CGPDFContextCreateWithURL(pdfURLOutput, NULL, NULL);   
    }

    for (NSString *source in listOfFiles) {
        CFURLRef pdfURL = (CFURLRef)CFBridgingRetain([[NSURL alloc] initFileURLWithPath:source]);

        //file ref
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((CFURLRef) pdfURL);
        numberOfPages = CGPDFDocumentGetNumberOfPages(pdfRef);

        // Loop variables
        CGPDFPageRef page;
        CGRect mediaBox;

        // Read the first PDF and generate the output pages
        NSLog(@"GENERATING PAGES FROM PDF 1 (%@)...", source);
        for (int i=1; i<=numberOfPages; i++) {
            page = CGPDFDocumentGetPage(pdfRef, i);
            mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
            CGContextBeginPage(writeContext, &mediaBox);
            CGContextDrawPDFPage(writeContext, page);
            CGContextEndPage(writeContext);
        }

        CGPDFDocumentRelease(pdfRef);
        CFRelease(pdfURL);
    }
    CFRelease(pdfURLOutput);

    // Finalize the output file
    CGPDFContextClose(writeContext);
    CGContextRelease(writeContext);

    [methodResult setResult:@"mergeIOSPDF completed"];
}

- (CGFloat)pixelToPoints:(CGFloat)px {
    CGFloat pointsPerInch = 72.0; // see: http://en.wikipedia.org/wiki/Point%5Fsize#Current%5FDTP%5Fpoint%5Fsystem
    CGFloat scale = 1;
    float pixelPerInch; // DPI
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        pixelPerInch = 132 * scale;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        pixelPerInch = 163 * scale;
    } else {
        pixelPerInch = 160 * scale;
    }
    CGFloat points = px * pointsPerInch / pixelPerInch;
    return points;
}

- (CGFloat)pointsToPixels:(CGFloat)points {
    CGFloat pointsPerInch = 72.0; // see: http://en.wikipedia.org/wiki/Point%5Fsize#Current%5FDTP%5Fpoint%5Fsystem
    CGFloat scale = 1;
    float pixelPerInch; // DPI
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        pixelPerInch = 132 * scale;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        pixelPerInch = 163 * scale;
    } else {
        pixelPerInch = 160 * scale;
    }
    CGFloat px = points / (pointsPerInch * pixelPerInch);
    return px;
}


/*----------------Methods to create a PDF file in iOS----------------*/
- (void) generateSamplePDF:(NSString*)filePath {
    UIGraphicsBeginPDFContextToFile(filePath, CGRectZero, nil);

    pageSize = CGSizeMake(612, 792);

    NSInteger currentPage = 0;
    BOOL done = NO;
    do {
        //Start a new page.
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pageSize.width, pageSize.height), nil);

        //Draw a page number at the bottom of each page.
        // currentPage++;
        // [self drawPageNumber:currentPage];

        //Draw a border for each page.
        // [self drawBorder];

        //Draw text fo our header.
        // [self drawHeader];

        //Draw a line below the header.
        // [self drawLine];

        //Draw some text for the page.
        // [self drawText];

        //Draw an image
        // [self drawImage];
        done = YES;
    } 
    while (!done);

    // Close the PDF context and write the contents out.
    UIGraphicsEndPDFContext();
}

- (void) drawBorder {
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();
    UIColor *borderColor = [UIColor brownColor];

    CGRect rectFrame = CGRectMake(kBorderInset, kBorderInset, pageSize.width-kBorderInset*2, pageSize.height-kBorderInset*2);

    CGContextSetStrokeColorWithColor(currentContext, borderColor.CGColor);
    CGContextSetLineWidth(currentContext, kBorderWidth);
    CGContextStrokeRect(currentContext, rectFrame);
}

- (void) drawPageNumber:(NSInteger)pageNumber {
    NSString* pageNumberString = [NSString stringWithFormat:@"Page %d", pageNumber];
    UIFont* theFont = [UIFont systemFontOfSize:12];

    CGSize pageNumberStringSize = [pageNumberString sizeWithFont:theFont
                                   constrainedToSize:pageSize
                                       lineBreakMode:UILineBreakModeWordWrap];

    CGRect stringRenderingRect = CGRectMake(kBorderInset,
                                   pageSize.height - 40.0,
                                   pageSize.width - 2*kBorderInset,
                                   pageNumberStringSize.height);

    [pageNumberString drawInRect:stringRenderingRect withFont:theFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
}

- (void) drawHeader {
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(currentContext, 0.3, 0.7, 0.2, 1.0);

    NSString *textToDraw = @"Pdf Demo - iOSLearner.com";

    UIFont *font = [UIFont systemFontOfSize:24.0];

    CGSize stringSize = [textToDraw sizeWithFont:font constrainedToSize:CGSizeMake(pageSize.width - 2*kBorderInset-2*kMarginInset, pageSize.height - 2*kBorderInset - 2*kMarginInset) lineBreakMode:UILineBreakModeWordWrap];

    CGRect renderingRect = CGRectMake(kBorderInset + kMarginInset, kBorderInset + kMarginInset, pageSize.width - 2*kBorderInset - 2*kMarginInset, stringSize.height);

    [textToDraw drawInRect:renderingRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
}

- (void) drawText {
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(currentContext, 0.0, 0.0, 0.0, 1.0);

    NSString *textToDraw = @"Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Typi non habent claritatem insitam; est usus legentis in iis qui facit eorum claritatem. Investigationes demonstraverunt lectores legere me lius quod ii legunt saepius. Claritas est etiam processus dynamicus, qui sequitur mutationem consuetudium lectorum. Mirum est notare quam littera gothica, quam nunc putamus parum claram, anteposuerit litterarum formas humanitatis per seacula quarta decima et quinta decima. Eodem modo typi, qui nunc nobis videntur parum clari, fiant sollemnes in futurum.";

    UIFont *font = [UIFont systemFontOfSize:14.0];

    CGSize stringSize = [textToDraw sizeWithFont:font
                               constrainedToSize:CGSizeMake(pageSize.width - 2*kBorderInset-2*kMarginInset, pageSize.height - 2*kBorderInset - 2*kMarginInset) 
                                   lineBreakMode:UILineBreakModeWordWrap];

    CGRect renderingRect = CGRectMake(kBorderInset + kMarginInset, kBorderInset + kMarginInset + 50.0, pageSize.width - 2*kBorderInset - 2*kMarginInset, stringSize.height);

    [textToDraw drawInRect:renderingRect 
                  withFont:font
             lineBreakMode:UILineBreakModeWordWrap
                 alignment:UITextAlignmentLeft];
}

- (void) drawLine {
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(currentContext, kLineWidth);

    CGContextSetStrokeColorWithColor(currentContext, [UIColor blueColor].CGColor);

    CGPoint startPoint = CGPointMake(kMarginInset + kBorderInset, kMarginInset + kBorderInset + 40.0);
    CGPoint endPoint = CGPointMake(pageSize.width - 2*kMarginInset -2*kBorderInset, kMarginInset + kBorderInset + 40.0);

    CGContextBeginPath(currentContext);
    CGContextMoveToPoint(currentContext, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(currentContext, endPoint.x, endPoint.y);

    CGContextClosePath(currentContext);    
    CGContextDrawPath(currentContext, kCGPathFillStroke);
}

- (void) drawImage {
    UIImage * demoImage = [UIImage imageNamed:@"demo.png"];
    [demoImage drawInRect:CGRectMake( (pageSize.width - demoImage.size.width/2)/2, 350, demoImage.size.width/2, demoImage.size.height/2)];
}
/*----------------Methods to create a PDF file in iOS----------------*/

@end



@implementation UIPrintPageRenderer (PDF)

- (NSData*) printToPDF {
    NSMutableData *pdfData = [NSMutableData data];
    
    UIGraphicsBeginPDFContextToData(pdfData, self.printableRect, nil);

    [self prepareForDrawingPages: NSMakeRange(0, self.numberOfPages)];
    
    CGRect bounds = UIGraphicsGetPDFContextBounds();
    
    for (int i = 0; i < self.numberOfPages; i++){
        UIGraphicsBeginPDFPage();
        
        [self drawPageAtIndex: i inRect: bounds];

        /*NSString* pageNumberString = [NSString stringWithFormat:@"Page %d", i+1];
        UIFont* theFont = [UIFont systemFontOfSize:12];

        CGSize pageNumberStringSize = [pageNumberString sizeWithFont:theFont
                                       constrainedToSize:kPaperSizeA4
                                           lineBreakMode:UILineBreakModeWordWrap];

        CGRect stringRenderingRect = CGRectMake(kBorderInset,
                                       kPaperSizeA4.height - 40.0,
                                       kPaperSizeA4.width - 2*kBorderInset,
                                       pageNumberStringSize.height);

        [pageNumberString drawInRect:stringRenderingRect withFont:theFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];*/
    }
    
    UIGraphicsEndPDFContext();
    
    return pdfData;
}

@end
