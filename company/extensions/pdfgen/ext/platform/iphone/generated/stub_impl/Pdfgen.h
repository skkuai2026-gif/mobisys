
#import "IPdfgen.h"
#import "PdfgenBase.h"

@interface Pdfgen : PdfgenBase<IPdfgen> {
}

-(void) generateAndroidPDF:(NSString*)inputHTMLFileName orientation:(NSString*)orientation isSinglePDFRequired:(NSString*)isSinglePDFRequired password:(NSString*)password methodResult:(id<IMethodResult>)methodResult;
-(void) generateAndroidPDFCharts:(NSString*)chartJSON chartOutputFileName:(NSString*)chartOutputFileName chartType:(NSString*)chartType methodResult:(id<IMethodResult>)methodResult;
-(void) generateIOSPDF:(NSString*)htmlContent targetFilePath:(NSString*)targetFilePath methodResult:(id<IMethodResult>)methodResult;
-(void) mergeIOSPDF:(NSString*)listOfPaths targetFilePath:(NSString*)targetFilePath masterPassword:(NSString*)masterPassword password:(NSString*)password methodResult:(id<IMethodResult>)methodResult;



@end