
#import "IHtmlToGraph.h"
#import "HtmlToGraphFactoryBase.h"

static HtmlToGraphFactoryBase* ourHtmlToGraphFactory = nil;

@implementation HtmlToGraphFactorySingleton

+(id<IHtmlToGraphFactory>) getHtmlToGraphFactoryInstance {
    if (ourHtmlToGraphFactory == nil) {
        ourHtmlToGraphFactory = [[HtmlToGraphFactoryBase alloc] init];
    }
    return ourHtmlToGraphFactory;
}

@end