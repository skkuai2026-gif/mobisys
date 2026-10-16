
#import "IHtmlToGraph.h"

@interface HtmlToGraphFactoryBase : NSObject<IHtmlToGraphFactory> {
    NSMutableDictionary* mHtmlToGraphInstances;
    id<IHtmlToGraphSingleton> mHtmlToGraphSingleton;
}

-(id)init;

-(id<IHtmlToGraphSingleton>) getHtmlToGraphSingleton;
-(id<IHtmlToGraph>) getHtmlToGraphByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IHtmlToGraph>)createHtmlToGraphByID:(NSString*)ID;

-(NSArray*) enumerateHtmlToGraphInstances;

-(void)dealloc;

@end