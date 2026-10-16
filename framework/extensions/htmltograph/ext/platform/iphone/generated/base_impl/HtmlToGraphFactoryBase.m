
#import "HtmlToGraphFactoryBase.h"
#import "HtmlToGraph.h"
#import "HtmlToGraphSingleton.h"



@implementation HtmlToGraphFactoryBase

-(id)init {
    self = [super init];
    mHtmlToGraphInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mHtmlToGraphSingleton = nil;
    return self;
}

-(id<IHtmlToGraph>) getHtmlToGraphByID:(NSString*)ID {
    id<IHtmlToGraph> obj = (HtmlToGraph*)[mHtmlToGraphInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createHtmlToGraphByID:ID];
        [mHtmlToGraphInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    HtmlToGraph* obj = [mHtmlToGraphInstances objectForKey:ID];
    if (obj != nil) {
        [mHtmlToGraphInstances removeObjectForKey:ID];
    }
}


-(id<IHtmlToGraph>)createHtmlToGraphByID:(NSString*)ID {
    HtmlToGraph* obj = [[HtmlToGraph alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IHtmlToGraphSingleton>) getHtmlToGraphSingleton {
    if (mHtmlToGraphSingleton == nil) {
        mHtmlToGraphSingleton = [[HtmlToGraphSingleton alloc] init];
    }
    return mHtmlToGraphSingleton;
}

-(NSArray*) enumerateHtmlToGraphInstances {
    return [mHtmlToGraphInstances allKeys];
}

-(void)dealloc {
    [mHtmlToGraphInstances release];
    [super dealloc];
}


@end