
#import "PdfgenFactoryBase.h"
#import "Pdfgen.h"
#import "PdfgenSingleton.h"



@implementation PdfgenFactoryBase

-(id)init {
    self = [super init];
    mPdfgenInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mPdfgenSingleton = nil;
    return self;
}

-(id<IPdfgen>) getPdfgenByID:(NSString*)ID {
    id<IPdfgen> obj = (Pdfgen*)[mPdfgenInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createPdfgenByID:ID];
        [mPdfgenInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    Pdfgen* obj = [mPdfgenInstances objectForKey:ID];
    if (obj != nil) {
        [mPdfgenInstances removeObjectForKey:ID];
    }
}


-(id<IPdfgen>)createPdfgenByID:(NSString*)ID {
    Pdfgen* obj = [[Pdfgen alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IPdfgenSingleton>) getPdfgenSingleton {
    if (mPdfgenSingleton == nil) {
        mPdfgenSingleton = [[PdfgenSingleton alloc] init];
    }
    return mPdfgenSingleton;
}

-(NSArray*) enumeratePdfgenInstances {
    return [mPdfgenInstances allKeys];
}

-(void)dealloc {
    [mPdfgenInstances release];
    [super dealloc];
}


@end