
#import "IHtmlToGraph.h"
//#import "api_generator/common/ruby_helpers.h"

#include "api_generator/js_helpers.h"

#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CJSConverter.h"

extern VALUE getRuby_HtmlToGraph_Module();



id<IHtmlToGraph> HtmlToGraph_makeInstanceByJSObject(rho::String sid) {
    const char* szID = sid.c_str();
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    return [factory getHtmlToGraphByID:[NSString stringWithUTF8String:szID]];
}









@interface HtmlToGraph_getSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getSimpleStringProperty_caller_params* par = [[[HtmlToGraph_getSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getSimpleStringProperty_caller : NSObject {

}
+(HtmlToGraph_getSimpleStringProperty_caller*) getSharedInstance;
+(void) getSimpleStringProperty:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_thread:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_UI_thread:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params;

@end

static HtmlToGraph_getSimpleStringProperty_caller* our_HtmlToGraph_getSimpleStringProperty_caller = nil;

@implementation HtmlToGraph_getSimpleStringProperty_caller

+(HtmlToGraph_getSimpleStringProperty_caller*) getSharedInstance {
    if (our_HtmlToGraph_getSimpleStringProperty_caller == nil) {
        our_HtmlToGraph_getSimpleStringProperty_caller = [[HtmlToGraph_getSimpleStringProperty_caller alloc] init];
    }
    return our_HtmlToGraph_getSimpleStringProperty_caller;
}

-(void) command_getSimpleStringProperty:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params {

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getSimpleStringProperty:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getSimpleStringProperty:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params {
    [[HtmlToGraph_getSimpleStringProperty_caller getSharedInstance] command_getSimpleStringProperty:caller_params];
}

+(void) getSimpleStringProperty_in_thread:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params {
    [[HtmlToGraph_getSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getSimpleStringProperty:) withObject:caller_params];
}

+(void) getSimpleStringProperty_in_UI_thread:(HtmlToGraph_getSimpleStringProperty_caller_params*)caller_params {
    [[HtmlToGraph_getSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::simpleStringProperty"];

    
    static RHO_API_PARAM rho_api_params[] = {  };

    
    BOOL is_factory_param[] = { NO };

    int i;

    // init
    for (i = 0; i < (0); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (0); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getSimpleStringProperty parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(0)];
    for (i = 0 ; i < (0); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getSimpleStringProperty_caller getSimpleStringProperty_in_thread:[HtmlToGraph_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getSimpleStringProperty_caller getSimpleStringProperty:[HtmlToGraph_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_setSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_setSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_setSimpleStringProperty_caller_params* par = [[[HtmlToGraph_setSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_setSimpleStringProperty_caller : NSObject {

}
+(HtmlToGraph_setSimpleStringProperty_caller*) getSharedInstance;
+(void) setSimpleStringProperty:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_thread:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_UI_thread:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params;

@end

static HtmlToGraph_setSimpleStringProperty_caller* our_HtmlToGraph_setSimpleStringProperty_caller = nil;

@implementation HtmlToGraph_setSimpleStringProperty_caller

+(HtmlToGraph_setSimpleStringProperty_caller*) getSharedInstance {
    if (our_HtmlToGraph_setSimpleStringProperty_caller == nil) {
        our_HtmlToGraph_setSimpleStringProperty_caller = [[HtmlToGraph_setSimpleStringProperty_caller alloc] init];
    }
    return our_HtmlToGraph_setSimpleStringProperty_caller;
}

-(void) command_setSimpleStringProperty:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setSimpleStringProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setSimpleStringProperty:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params {
    [[HtmlToGraph_setSimpleStringProperty_caller getSharedInstance] command_setSimpleStringProperty:caller_params];
}

+(void) setSimpleStringProperty_in_thread:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params {
    [[HtmlToGraph_setSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setSimpleStringProperty:) withObject:caller_params];
}

+(void) setSimpleStringProperty_in_UI_thread:(HtmlToGraph_setSimpleStringProperty_caller_params*)caller_params {
    [[HtmlToGraph_setSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_setSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::simpleStringProperty="];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "simpleStringProperty", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO };

    int i;

    // init
    for (i = 0; i < (1); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (1); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::setSimpleStringProperty parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(1)];
    for (i = 0 ; i < (1); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_setSimpleStringProperty_caller setSimpleStringProperty_in_thread:[HtmlToGraph_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_setSimpleStringProperty_caller setSimpleStringProperty:[HtmlToGraph_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_enumerate_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraphSingleton> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraphSingleton>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_enumerate_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraphSingleton>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_enumerate_caller_params* par = [[[HtmlToGraph_enumerate_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_enumerate_caller : NSObject {

}
+(HtmlToGraph_enumerate_caller*) getSharedInstance;
+(void) enumerate:(HtmlToGraph_enumerate_caller_params*)caller_params;
+(void) enumerate_in_thread:(HtmlToGraph_enumerate_caller_params*)caller_params;
+(void) enumerate_in_UI_thread:(HtmlToGraph_enumerate_caller_params*)caller_params;

@end

static HtmlToGraph_enumerate_caller* our_HtmlToGraph_enumerate_caller = nil;

@implementation HtmlToGraph_enumerate_caller

+(HtmlToGraph_enumerate_caller*) getSharedInstance {
    if (our_HtmlToGraph_enumerate_caller == nil) {
        our_HtmlToGraph_enumerate_caller = [[HtmlToGraph_enumerate_caller alloc] init];
    }
    return our_HtmlToGraph_enumerate_caller;
}

-(void) command_enumerate:(HtmlToGraph_enumerate_caller_params*)caller_params {

    id<IHtmlToGraphSingleton> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enumerate:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enumerate:(HtmlToGraph_enumerate_caller_params*)caller_params {
    [[HtmlToGraph_enumerate_caller getSharedInstance] command_enumerate:caller_params];
}

+(void) enumerate_in_thread:(HtmlToGraph_enumerate_caller_params*)caller_params {
    [[HtmlToGraph_enumerate_caller getSharedInstance] performSelectorInBackground:@selector(command_enumerate:) withObject:caller_params];
}

+(void) enumerate_in_UI_thread:(HtmlToGraph_enumerate_caller_params*)caller_params {
    [[HtmlToGraph_enumerate_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enumerate:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_enumerate_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraphSingleton>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::enumerate"];

    
    static RHO_API_PARAM rho_api_params[] = {  };

    
    BOOL is_factory_param[] = { NO };

    int i;

    // init
    for (i = 0; i < (0); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (0); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::enumerate parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(0)];
    for (i = 0 ; i < (0); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    [methodResult enableObjectCreationModeWithJSClassPath:@"Rho.HtmlToGraph"];

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_enumerate_caller enumerate_in_thread:[HtmlToGraph_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_enumerate_caller enumerate:[HtmlToGraph_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_s_HtmlToGraph_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];
    return js_HtmlToGraph_enumerate_Obj(argv, singleton, strCallbackID, strJsVmID, strCallbackParam);

}







@interface HtmlToGraph_getPlatformName_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getPlatformName_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getPlatformName_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getPlatformName_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getPlatformName_caller_params* par = [[[HtmlToGraph_getPlatformName_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getPlatformName_caller : NSObject {

}
+(HtmlToGraph_getPlatformName_caller*) getSharedInstance;
+(void) getPlatformName:(HtmlToGraph_getPlatformName_caller_params*)caller_params;
+(void) getPlatformName_in_thread:(HtmlToGraph_getPlatformName_caller_params*)caller_params;
+(void) getPlatformName_in_UI_thread:(HtmlToGraph_getPlatformName_caller_params*)caller_params;

@end

static HtmlToGraph_getPlatformName_caller* our_HtmlToGraph_getPlatformName_caller = nil;

@implementation HtmlToGraph_getPlatformName_caller

+(HtmlToGraph_getPlatformName_caller*) getSharedInstance {
    if (our_HtmlToGraph_getPlatformName_caller == nil) {
        our_HtmlToGraph_getPlatformName_caller = [[HtmlToGraph_getPlatformName_caller alloc] init];
    }
    return our_HtmlToGraph_getPlatformName_caller;
}

-(void) command_getPlatformName:(HtmlToGraph_getPlatformName_caller_params*)caller_params {

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getPlatformName:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getPlatformName:(HtmlToGraph_getPlatformName_caller_params*)caller_params {
    [[HtmlToGraph_getPlatformName_caller getSharedInstance] command_getPlatformName:caller_params];
}

+(void) getPlatformName_in_thread:(HtmlToGraph_getPlatformName_caller_params*)caller_params {
    [[HtmlToGraph_getPlatformName_caller getSharedInstance] performSelectorInBackground:@selector(command_getPlatformName:) withObject:caller_params];
}

+(void) getPlatformName_in_UI_thread:(HtmlToGraph_getPlatformName_caller_params*)caller_params {
    [[HtmlToGraph_getPlatformName_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getPlatformName:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getPlatformName_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::getPlatformName"];

    
    static RHO_API_PARAM rho_api_params[] = {  };

    
    BOOL is_factory_param[] = { NO };

    int i;

    // init
    for (i = 0; i < (0); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (0); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getPlatformName parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(0)];
    for (i = 0 ; i < (0); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getPlatformName_caller getPlatformName_in_thread:[HtmlToGraph_getPlatformName_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getPlatformName_caller getPlatformName:[HtmlToGraph_getPlatformName_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getPlatformName(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getPlatformName_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getPlatformName(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getPlatformName_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_getGraphIOS_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getGraphIOS_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getGraphIOS_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getGraphIOS_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getGraphIOS_caller_params* par = [[[HtmlToGraph_getGraphIOS_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getGraphIOS_caller : NSObject {

}
+(HtmlToGraph_getGraphIOS_caller*) getSharedInstance;
+(void) getGraphIOS:(HtmlToGraph_getGraphIOS_caller_params*)caller_params;
+(void) getGraphIOS_in_thread:(HtmlToGraph_getGraphIOS_caller_params*)caller_params;
+(void) getGraphIOS_in_UI_thread:(HtmlToGraph_getGraphIOS_caller_params*)caller_params;

@end

static HtmlToGraph_getGraphIOS_caller* our_HtmlToGraph_getGraphIOS_caller = nil;

@implementation HtmlToGraph_getGraphIOS_caller

+(HtmlToGraph_getGraphIOS_caller*) getSharedInstance {
    if (our_HtmlToGraph_getGraphIOS_caller == nil) {
        our_HtmlToGraph_getGraphIOS_caller = [[HtmlToGraph_getGraphIOS_caller alloc] init];
    }
    return our_HtmlToGraph_getGraphIOS_caller;
}

-(void) command_getGraphIOS:(HtmlToGraph_getGraphIOS_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getGraphIOS:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getGraphIOS:(HtmlToGraph_getGraphIOS_caller_params*)caller_params {
    [[HtmlToGraph_getGraphIOS_caller getSharedInstance] command_getGraphIOS:caller_params];
}

+(void) getGraphIOS_in_thread:(HtmlToGraph_getGraphIOS_caller_params*)caller_params {
    [[HtmlToGraph_getGraphIOS_caller getSharedInstance] performSelectorInBackground:@selector(command_getGraphIOS:) withObject:caller_params];
}

+(void) getGraphIOS_in_UI_thread:(HtmlToGraph_getGraphIOS_caller_params*)caller_params {
    [[HtmlToGraph_getGraphIOS_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getGraphIOS:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getGraphIOS_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::getGraphIOS"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "htmlString", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO };

    int i;

    // init
    for (i = 0; i < (1); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (1); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getGraphIOS parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(1)];
    for (i = 0 ; i < (1); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getGraphIOS_caller getGraphIOS_in_thread:[HtmlToGraph_getGraphIOS_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getGraphIOS_caller getGraphIOS:[HtmlToGraph_getGraphIOS_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getGraphIOS(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getGraphIOS_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getGraphIOS(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getGraphIOS_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_getGraphAndroid_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getGraphAndroid_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getGraphAndroid_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getGraphAndroid_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getGraphAndroid_caller_params* par = [[[HtmlToGraph_getGraphAndroid_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getGraphAndroid_caller : NSObject {

}
+(HtmlToGraph_getGraphAndroid_caller*) getSharedInstance;
+(void) getGraphAndroid:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params;
+(void) getGraphAndroid_in_thread:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params;
+(void) getGraphAndroid_in_UI_thread:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params;

@end

static HtmlToGraph_getGraphAndroid_caller* our_HtmlToGraph_getGraphAndroid_caller = nil;

@implementation HtmlToGraph_getGraphAndroid_caller

+(HtmlToGraph_getGraphAndroid_caller*) getSharedInstance {
    if (our_HtmlToGraph_getGraphAndroid_caller == nil) {
        our_HtmlToGraph_getGraphAndroid_caller = [[HtmlToGraph_getGraphAndroid_caller alloc] init];
    }
    return our_HtmlToGraph_getGraphAndroid_caller;
}

-(void) command_getGraphAndroid:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getGraphAndroid:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getGraphAndroid:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params {
    [[HtmlToGraph_getGraphAndroid_caller getSharedInstance] command_getGraphAndroid:caller_params];
}

+(void) getGraphAndroid_in_thread:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params {
    [[HtmlToGraph_getGraphAndroid_caller getSharedInstance] performSelectorInBackground:@selector(command_getGraphAndroid:) withObject:caller_params];
}

+(void) getGraphAndroid_in_UI_thread:(HtmlToGraph_getGraphAndroid_caller_params*)caller_params {
    [[HtmlToGraph_getGraphAndroid_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getGraphAndroid:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getGraphAndroid_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::getGraphAndroid"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "htmlString", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO };

    int i;

    // init
    for (i = 0; i < (1); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (1); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getGraphAndroid parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(1)];
    for (i = 0 ; i < (1); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getGraphAndroid_caller getGraphAndroid_in_thread:[HtmlToGraph_getGraphAndroid_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getGraphAndroid_caller getGraphAndroid:[HtmlToGraph_getGraphAndroid_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getGraphAndroid(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getGraphAndroid_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getGraphAndroid(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getGraphAndroid_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_calcSumm_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_calcSumm_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_calcSumm_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_calcSumm_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_calcSumm_caller_params* par = [[[HtmlToGraph_calcSumm_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_calcSumm_caller : NSObject {

}
+(HtmlToGraph_calcSumm_caller*) getSharedInstance;
+(void) calcSumm:(HtmlToGraph_calcSumm_caller_params*)caller_params;
+(void) calcSumm_in_thread:(HtmlToGraph_calcSumm_caller_params*)caller_params;
+(void) calcSumm_in_UI_thread:(HtmlToGraph_calcSumm_caller_params*)caller_params;

@end

static HtmlToGraph_calcSumm_caller* our_HtmlToGraph_calcSumm_caller = nil;

@implementation HtmlToGraph_calcSumm_caller

+(HtmlToGraph_calcSumm_caller*) getSharedInstance {
    if (our_HtmlToGraph_calcSumm_caller == nil) {
        our_HtmlToGraph_calcSumm_caller = [[HtmlToGraph_calcSumm_caller alloc] init];
    }
    return our_HtmlToGraph_calcSumm_caller;
}

-(void) command_calcSumm:(HtmlToGraph_calcSumm_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem calcSumm:(int)[((NSNumber*)[params objectAtIndex:0]) intValue] b:(int)[((NSNumber*)[params objectAtIndex:1]) intValue] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) calcSumm:(HtmlToGraph_calcSumm_caller_params*)caller_params {
    [[HtmlToGraph_calcSumm_caller getSharedInstance] command_calcSumm:caller_params];
}

+(void) calcSumm_in_thread:(HtmlToGraph_calcSumm_caller_params*)caller_params {
    [[HtmlToGraph_calcSumm_caller getSharedInstance] performSelectorInBackground:@selector(command_calcSumm:) withObject:caller_params];
}

+(void) calcSumm_in_UI_thread:(HtmlToGraph_calcSumm_caller_params*)caller_params {
    [[HtmlToGraph_calcSumm_caller getSharedInstance] performSelectorOnMainThread:@selector(command_calcSumm:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_calcSumm_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::calcSumm"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_INTEGER, 0, "a", 0, 0 }, {RHO_API_INTEGER, 0, "b", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO, NO };

    int i;

    // init
    for (i = 0; i < (2); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (2); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::calcSumm parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(2)];
    for (i = 0 ; i < (2); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_calcSumm_caller calcSumm_in_thread:[HtmlToGraph_calcSumm_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_calcSumm_caller calcSumm:[HtmlToGraph_calcSumm_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_calcSumm(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_calcSumm_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_calcSumm(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_calcSumm_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_joinStrings_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_joinStrings_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_joinStrings_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_joinStrings_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_joinStrings_caller_params* par = [[[HtmlToGraph_joinStrings_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_joinStrings_caller : NSObject {

}
+(HtmlToGraph_joinStrings_caller*) getSharedInstance;
+(void) joinStrings:(HtmlToGraph_joinStrings_caller_params*)caller_params;
+(void) joinStrings_in_thread:(HtmlToGraph_joinStrings_caller_params*)caller_params;
+(void) joinStrings_in_UI_thread:(HtmlToGraph_joinStrings_caller_params*)caller_params;

@end

static HtmlToGraph_joinStrings_caller* our_HtmlToGraph_joinStrings_caller = nil;

@implementation HtmlToGraph_joinStrings_caller

+(HtmlToGraph_joinStrings_caller*) getSharedInstance {
    if (our_HtmlToGraph_joinStrings_caller == nil) {
        our_HtmlToGraph_joinStrings_caller = [[HtmlToGraph_joinStrings_caller alloc] init];
    }
    return our_HtmlToGraph_joinStrings_caller;
}

-(void) command_joinStrings:(HtmlToGraph_joinStrings_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem joinStrings:(NSString*)[params objectAtIndex:0] b:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) joinStrings:(HtmlToGraph_joinStrings_caller_params*)caller_params {
    [[HtmlToGraph_joinStrings_caller getSharedInstance] command_joinStrings:caller_params];
}

+(void) joinStrings_in_thread:(HtmlToGraph_joinStrings_caller_params*)caller_params {
    [[HtmlToGraph_joinStrings_caller getSharedInstance] performSelectorInBackground:@selector(command_joinStrings:) withObject:caller_params];
}

+(void) joinStrings_in_UI_thread:(HtmlToGraph_joinStrings_caller_params*)caller_params {
    [[HtmlToGraph_joinStrings_caller getSharedInstance] performSelectorOnMainThread:@selector(command_joinStrings:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_joinStrings_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::joinStrings"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "a", 0, 0 }, {RHO_API_STRING, 0, "b", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO, NO };

    int i;

    // init
    for (i = 0; i < (2); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (2); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::joinStrings parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(2)];
    for (i = 0 ; i < (2); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_joinStrings_caller joinStrings_in_thread:[HtmlToGraph_joinStrings_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_joinStrings_caller joinStrings:[HtmlToGraph_joinStrings_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_joinStrings(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_joinStrings_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_joinStrings(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_joinStrings_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_getProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getProperty_caller_params* par = [[[HtmlToGraph_getProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getProperty_caller : NSObject {

}
+(HtmlToGraph_getProperty_caller*) getSharedInstance;
+(void) getProperty:(HtmlToGraph_getProperty_caller_params*)caller_params;
+(void) getProperty_in_thread:(HtmlToGraph_getProperty_caller_params*)caller_params;
+(void) getProperty_in_UI_thread:(HtmlToGraph_getProperty_caller_params*)caller_params;

@end

static HtmlToGraph_getProperty_caller* our_HtmlToGraph_getProperty_caller = nil;

@implementation HtmlToGraph_getProperty_caller

+(HtmlToGraph_getProperty_caller*) getSharedInstance {
    if (our_HtmlToGraph_getProperty_caller == nil) {
        our_HtmlToGraph_getProperty_caller = [[HtmlToGraph_getProperty_caller alloc] init];
    }
    return our_HtmlToGraph_getProperty_caller;
}

-(void) command_getProperty:(HtmlToGraph_getProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperty:(HtmlToGraph_getProperty_caller_params*)caller_params {
    [[HtmlToGraph_getProperty_caller getSharedInstance] command_getProperty:caller_params];
}

+(void) getProperty_in_thread:(HtmlToGraph_getProperty_caller_params*)caller_params {
    [[HtmlToGraph_getProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperty:) withObject:caller_params];
}

+(void) getProperty_in_UI_thread:(HtmlToGraph_getProperty_caller_params*)caller_params {
    [[HtmlToGraph_getProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getProperty_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::getProperty"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "propertyName", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO };

    int i;

    // init
    for (i = 0; i < (1); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (1); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getProperty parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(1)];
    for (i = 0 ; i < (1); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getProperty_caller getProperty_in_thread:[HtmlToGraph_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getProperty_caller getProperty:[HtmlToGraph_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_getProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getProperties_caller_params* par = [[[HtmlToGraph_getProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getProperties_caller : NSObject {

}
+(HtmlToGraph_getProperties_caller*) getSharedInstance;
+(void) getProperties:(HtmlToGraph_getProperties_caller_params*)caller_params;
+(void) getProperties_in_thread:(HtmlToGraph_getProperties_caller_params*)caller_params;
+(void) getProperties_in_UI_thread:(HtmlToGraph_getProperties_caller_params*)caller_params;

@end

static HtmlToGraph_getProperties_caller* our_HtmlToGraph_getProperties_caller = nil;

@implementation HtmlToGraph_getProperties_caller

+(HtmlToGraph_getProperties_caller*) getSharedInstance {
    if (our_HtmlToGraph_getProperties_caller == nil) {
        our_HtmlToGraph_getProperties_caller = [[HtmlToGraph_getProperties_caller alloc] init];
    }
    return our_HtmlToGraph_getProperties_caller;
}

-(void) command_getProperties:(HtmlToGraph_getProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperties:(NSArray*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperties:(HtmlToGraph_getProperties_caller_params*)caller_params {
    [[HtmlToGraph_getProperties_caller getSharedInstance] command_getProperties:caller_params];
}

+(void) getProperties_in_thread:(HtmlToGraph_getProperties_caller_params*)caller_params {
    [[HtmlToGraph_getProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperties:) withObject:caller_params];
}

+(void) getProperties_in_UI_thread:(HtmlToGraph_getProperties_caller_params*)caller_params {
    [[HtmlToGraph_getProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getProperties_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::getProperties"];

    
    static RHO_API_PARAM rho_api_params_param0[] = { {RHO_API_STRING, 0, "array_param", 0, 0 } };
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_ARRAY, 0, "arrayofNames", 1, rho_api_params_param0 } };

    
    BOOL is_factory_param[] = { NO, NO };

    int i;

    // init
    for (i = 0; i < (1); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (1); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getProperties parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(1)];
    for (i = 0 ; i < (1); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getProperties_caller getProperties_in_thread:[HtmlToGraph_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getProperties_caller getProperties:[HtmlToGraph_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_getAllProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_getAllProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_getAllProperties_caller_params* par = [[[HtmlToGraph_getAllProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_getAllProperties_caller : NSObject {

}
+(HtmlToGraph_getAllProperties_caller*) getSharedInstance;
+(void) getAllProperties:(HtmlToGraph_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_thread:(HtmlToGraph_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_UI_thread:(HtmlToGraph_getAllProperties_caller_params*)caller_params;

@end

static HtmlToGraph_getAllProperties_caller* our_HtmlToGraph_getAllProperties_caller = nil;

@implementation HtmlToGraph_getAllProperties_caller

+(HtmlToGraph_getAllProperties_caller*) getSharedInstance {
    if (our_HtmlToGraph_getAllProperties_caller == nil) {
        our_HtmlToGraph_getAllProperties_caller = [[HtmlToGraph_getAllProperties_caller alloc] init];
    }
    return our_HtmlToGraph_getAllProperties_caller;
}

-(void) command_getAllProperties:(HtmlToGraph_getAllProperties_caller_params*)caller_params {

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getAllProperties:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getAllProperties:(HtmlToGraph_getAllProperties_caller_params*)caller_params {
    [[HtmlToGraph_getAllProperties_caller getSharedInstance] command_getAllProperties:caller_params];
}

+(void) getAllProperties_in_thread:(HtmlToGraph_getAllProperties_caller_params*)caller_params {
    [[HtmlToGraph_getAllProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getAllProperties:) withObject:caller_params];
}

+(void) getAllProperties_in_UI_thread:(HtmlToGraph_getAllProperties_caller_params*)caller_params {
    [[HtmlToGraph_getAllProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getAllProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_getAllProperties_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::getAllProperties"];

    
    static RHO_API_PARAM rho_api_params[] = {  };

    
    BOOL is_factory_param[] = { NO };

    int i;

    // init
    for (i = 0; i < (0); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (0); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::getAllProperties parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(0)];
    for (i = 0 ; i < (0); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_getAllProperties_caller getAllProperties_in_thread:[HtmlToGraph_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_getAllProperties_caller getAllProperties:[HtmlToGraph_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_setProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_setProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_setProperty_caller_params* par = [[[HtmlToGraph_setProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_setProperty_caller : NSObject {

}
+(HtmlToGraph_setProperty_caller*) getSharedInstance;
+(void) setProperty:(HtmlToGraph_setProperty_caller_params*)caller_params;
+(void) setProperty_in_thread:(HtmlToGraph_setProperty_caller_params*)caller_params;
+(void) setProperty_in_UI_thread:(HtmlToGraph_setProperty_caller_params*)caller_params;

@end

static HtmlToGraph_setProperty_caller* our_HtmlToGraph_setProperty_caller = nil;

@implementation HtmlToGraph_setProperty_caller

+(HtmlToGraph_setProperty_caller*) getSharedInstance {
    if (our_HtmlToGraph_setProperty_caller == nil) {
        our_HtmlToGraph_setProperty_caller = [[HtmlToGraph_setProperty_caller alloc] init];
    }
    return our_HtmlToGraph_setProperty_caller;
}

-(void) command_setProperty:(HtmlToGraph_setProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperty:(NSString*)[params objectAtIndex:0] propertyValue:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperty:(HtmlToGraph_setProperty_caller_params*)caller_params {
    [[HtmlToGraph_setProperty_caller getSharedInstance] command_setProperty:caller_params];
}

+(void) setProperty_in_thread:(HtmlToGraph_setProperty_caller_params*)caller_params {
    [[HtmlToGraph_setProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperty:) withObject:caller_params];
}

+(void) setProperty_in_UI_thread:(HtmlToGraph_setProperty_caller_params*)caller_params {
    [[HtmlToGraph_setProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_setProperty_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::setProperty"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "propertyName", 0, 0 }, {RHO_API_STRING, 0, "propertyValue", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO, NO };

    int i;

    // init
    for (i = 0; i < (2); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (2); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::setProperty parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(2)];
    for (i = 0 ; i < (2); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_setProperty_caller setProperty_in_thread:[HtmlToGraph_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_setProperty_caller setProperty:[HtmlToGraph_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface HtmlToGraph_setProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IHtmlToGraph> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(HtmlToGraph_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation HtmlToGraph_setProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(HtmlToGraph_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IHtmlToGraph>)_item _methodResult:(CMethodResult*)_methodResult {
    HtmlToGraph_setProperties_caller_params* par = [[[HtmlToGraph_setProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface HtmlToGraph_setProperties_caller : NSObject {

}
+(HtmlToGraph_setProperties_caller*) getSharedInstance;
+(void) setProperties:(HtmlToGraph_setProperties_caller_params*)caller_params;
+(void) setProperties_in_thread:(HtmlToGraph_setProperties_caller_params*)caller_params;
+(void) setProperties_in_UI_thread:(HtmlToGraph_setProperties_caller_params*)caller_params;

@end

static HtmlToGraph_setProperties_caller* our_HtmlToGraph_setProperties_caller = nil;

@implementation HtmlToGraph_setProperties_caller

+(HtmlToGraph_setProperties_caller*) getSharedInstance {
    if (our_HtmlToGraph_setProperties_caller == nil) {
        our_HtmlToGraph_setProperties_caller = [[HtmlToGraph_setProperties_caller alloc] init];
    }
    return our_HtmlToGraph_setProperties_caller;
}

-(void) command_setProperties:(HtmlToGraph_setProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IHtmlToGraph> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperties:(NSDictionary*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperties:(HtmlToGraph_setProperties_caller_params*)caller_params {
    [[HtmlToGraph_setProperties_caller getSharedInstance] command_setProperties:caller_params];
}

+(void) setProperties_in_thread:(HtmlToGraph_setProperties_caller_params*)caller_params {
    [[HtmlToGraph_setProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperties:) withObject:caller_params];
}

+(void) setProperties_in_UI_thread:(HtmlToGraph_setProperties_caller_params*)caller_params {
    [[HtmlToGraph_setProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_HtmlToGraph_setProperties_Obj(rho::json::CJSONArray& argv, id<IHtmlToGraph>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"HtmlToGraph::setProperties"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_HASH, 0, "propertyMap", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO };

    int i;

    // init
    for (i = 0; i < (1); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (1); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = HtmlToGraph_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"HtmlToGraph::setProperties parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(1)];
    for (i = 0 ; i < (1); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [HtmlToGraph_setProperties_caller setProperties_in_thread:[HtmlToGraph_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [HtmlToGraph_setProperties_caller setProperties:[HtmlToGraph_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_HtmlToGraph_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IHtmlToGraph> item = HtmlToGraph_makeInstanceByJSObject(strObjID);
    return js_HtmlToGraph_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_HtmlToGraph_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IHtmlToGraph> item = [factory getHtmlToGraphByID:defID];
    return js_HtmlToGraph_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







rho::String js_s_HtmlToGraph_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:defID level:0] UTF8String];

    return res;
}

rho::String js_s_HtmlToGraph_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:[CRhoAPIClassInstance rubyClassByName:@"Rho.HtmlToGraph" instanceID:defID] level:0] UTF8String];

    return res;
}

rho::String js_s_HtmlToGraph_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IHtmlToGraphFactory> factory = [HtmlToGraphFactorySingleton getHtmlToGraphFactoryInstance];
    id<IHtmlToGraphSingleton> singleton = [factory getHtmlToGraphSingleton];

    rho::json::CJSONEntry el = argv[0];

    if (el.isString()) {
        NSString* defID = [NSString stringWithUTF8String:(el.getString())];

        [singleton setDefaultID:defID];

        return [[CJSConverter convertToJS:nil level:0] UTF8String];
    }

    return "\"result\":null,\"error\":\"Method parameter should be defined as string!\"";
}

