
#import "IPdfgen.h"
#import "PdfgenFactoryBase.h"

static PdfgenFactoryBase* ourPdfgenFactory = nil;

@implementation PdfgenFactorySingleton

+(id<IPdfgenFactory>) getPdfgenFactoryInstance {
    if (ourPdfgenFactory == nil) {
        ourPdfgenFactory = [[PdfgenFactoryBase alloc] init];
    }
    return ourPdfgenFactory;
}

@end