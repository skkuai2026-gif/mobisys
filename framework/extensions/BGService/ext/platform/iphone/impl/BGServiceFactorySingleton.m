
#import "IBGService.h"
#import "BGServiceFactoryBase.h"

static BGServiceFactoryBase* ourBGServiceFactory = nil;

@implementation BGServiceFactorySingleton

+(id<IBGServiceFactory>) getBGServiceFactoryInstance {
    if (ourBGServiceFactory == nil) {
        ourBGServiceFactory = [[BGServiceFactoryBase alloc] init];
    }
    return ourBGServiceFactory;
}

@end