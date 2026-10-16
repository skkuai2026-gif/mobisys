
#import "IBmp.h"
#import "BmpFactoryBase.h"

static BmpFactoryBase* ourBmpFactory = nil;

@implementation BmpFactorySingleton

+(id<IBmpFactory>) getBmpFactoryInstance {
    if (ourBmpFactory == nil) {
        ourBmpFactory = [[BmpFactoryBase alloc] init];
    }
    return ourBmpFactory;
}

@end