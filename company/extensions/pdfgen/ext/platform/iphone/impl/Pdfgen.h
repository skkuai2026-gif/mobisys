#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "IPdfgen.h"
#import "PdfgenBase.h"

#define kBorderInset            20.0
#define kBorderWidth            1.0
#define kMarginInset            10.0

//Line drawing
#define kLineWidth              1.0


#define kPaperSizeA4 CGSizeMake(595.2,841.8)
#define kPaperSizeLetter CGSizeMake(612,792)

@interface Pdfgen : PdfgenBase<IPdfgen> {
	CGSize pageSize;
}

-(void) generatePDF:(NSString*)htmlContent targetFilePath:(NSString*)targetFilePath methodResult:(id<IMethodResult>)methodResult;

-(void) mergePDF:(NSString*)listOfPaths targetFilePath:(NSString*)targetFilePath methodResult:(id<IMethodResult>)methodResult;

@property (nonatomic, strong) NSString* destFilePath;
@property (nonatomic, assign) CGSize outputPageSize;
@property (nonatomic, assign) UIEdgeInsets pageMargins;
@property (nonatomic, assign) BOOL webViewLoading;

@end