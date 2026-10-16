
#import "IApptracking.h"
#import "ApptrackingFactoryBase.h"

static ApptrackingFactoryBase* ourApptrackingFactory = nil;

@implementation ApptrackingFactorySingleton

+(id<IApptrackingFactory>) getApptrackingFactoryInstance {
    if (ourApptrackingFactory == nil) {
        ourApptrackingFactory = [[ApptrackingFactoryBase alloc] init];
    }
    return ourApptrackingFactory;
}

@end