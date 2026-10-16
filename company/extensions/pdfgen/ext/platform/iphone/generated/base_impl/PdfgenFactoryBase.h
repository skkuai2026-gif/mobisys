
#import "IPdfgen.h"

@interface PdfgenFactoryBase : NSObject<IPdfgenFactory> {
    NSMutableDictionary* mPdfgenInstances;
    id<IPdfgenSingleton> mPdfgenSingleton;
}

-(id)init;

-(id<IPdfgenSingleton>) getPdfgenSingleton;
-(id<IPdfgen>) getPdfgenByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IPdfgen>)createPdfgenByID:(NSString*)ID;

-(NSArray*) enumeratePdfgenInstances;

-(void)dealloc;

@end