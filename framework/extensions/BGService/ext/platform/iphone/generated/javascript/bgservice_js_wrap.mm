
#import "IBGService.h"
//#import "api_generator/common/ruby_helpers.h"

#include "api_generator/js_helpers.h"

#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CJSConverter.h"

extern VALUE getRuby_BGService_Module();



id<IBGService> BGService_makeInstanceByJSObject(rho::String sid) {
    const char* szID = sid.c_str();
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    return [factory getBGServiceByID:[NSString stringWithUTF8String:szID]];
}









@interface BGService_getSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_getSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_getSimpleStringProperty_caller_params* par = [[[BGService_getSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_getSimpleStringProperty_caller : NSObject {

}
+(BGService_getSimpleStringProperty_caller*) getSharedInstance;
+(void) getSimpleStringProperty:(BGService_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_thread:(BGService_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_UI_thread:(BGService_getSimpleStringProperty_caller_params*)caller_params;

@end

static BGService_getSimpleStringProperty_caller* our_BGService_getSimpleStringProperty_caller = nil;

@implementation BGService_getSimpleStringProperty_caller

+(BGService_getSimpleStringProperty_caller*) getSharedInstance {
    if (our_BGService_getSimpleStringProperty_caller == nil) {
        our_BGService_getSimpleStringProperty_caller = [[BGService_getSimpleStringProperty_caller alloc] init];
    }
    return our_BGService_getSimpleStringProperty_caller;
}

-(void) command_getSimpleStringProperty:(BGService_getSimpleStringProperty_caller_params*)caller_params {

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getSimpleStringProperty:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getSimpleStringProperty:(BGService_getSimpleStringProperty_caller_params*)caller_params {
    [[BGService_getSimpleStringProperty_caller getSharedInstance] command_getSimpleStringProperty:caller_params];
}

+(void) getSimpleStringProperty_in_thread:(BGService_getSimpleStringProperty_caller_params*)caller_params {
    [[BGService_getSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getSimpleStringProperty:) withObject:caller_params];
}

+(void) getSimpleStringProperty_in_UI_thread:(BGService_getSimpleStringProperty_caller_params*)caller_params {
    [[BGService_getSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_getSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::simpleStringProperty"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::getSimpleStringProperty parameter %d is nil!", i);
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
        
        [BGService_getSimpleStringProperty_caller getSimpleStringProperty_in_thread:[BGService_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_getSimpleStringProperty_caller getSimpleStringProperty:[BGService_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_setSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_setSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_setSimpleStringProperty_caller_params* par = [[[BGService_setSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_setSimpleStringProperty_caller : NSObject {

}
+(BGService_setSimpleStringProperty_caller*) getSharedInstance;
+(void) setSimpleStringProperty:(BGService_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_thread:(BGService_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_UI_thread:(BGService_setSimpleStringProperty_caller_params*)caller_params;

@end

static BGService_setSimpleStringProperty_caller* our_BGService_setSimpleStringProperty_caller = nil;

@implementation BGService_setSimpleStringProperty_caller

+(BGService_setSimpleStringProperty_caller*) getSharedInstance {
    if (our_BGService_setSimpleStringProperty_caller == nil) {
        our_BGService_setSimpleStringProperty_caller = [[BGService_setSimpleStringProperty_caller alloc] init];
    }
    return our_BGService_setSimpleStringProperty_caller;
}

-(void) command_setSimpleStringProperty:(BGService_setSimpleStringProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setSimpleStringProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setSimpleStringProperty:(BGService_setSimpleStringProperty_caller_params*)caller_params {
    [[BGService_setSimpleStringProperty_caller getSharedInstance] command_setSimpleStringProperty:caller_params];
}

+(void) setSimpleStringProperty_in_thread:(BGService_setSimpleStringProperty_caller_params*)caller_params {
    [[BGService_setSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setSimpleStringProperty:) withObject:caller_params];
}

+(void) setSimpleStringProperty_in_UI_thread:(BGService_setSimpleStringProperty_caller_params*)caller_params {
    [[BGService_setSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_setSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::simpleStringProperty="];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::setSimpleStringProperty parameter %d is nil!", i);
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
        
        [BGService_setSimpleStringProperty_caller setSimpleStringProperty_in_thread:[BGService_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_setSimpleStringProperty_caller setSimpleStringProperty:[BGService_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_enumerate_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGServiceSingleton> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGServiceSingleton>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_enumerate_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGServiceSingleton>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_enumerate_caller_params* par = [[[BGService_enumerate_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_enumerate_caller : NSObject {

}
+(BGService_enumerate_caller*) getSharedInstance;
+(void) enumerate:(BGService_enumerate_caller_params*)caller_params;
+(void) enumerate_in_thread:(BGService_enumerate_caller_params*)caller_params;
+(void) enumerate_in_UI_thread:(BGService_enumerate_caller_params*)caller_params;

@end

static BGService_enumerate_caller* our_BGService_enumerate_caller = nil;

@implementation BGService_enumerate_caller

+(BGService_enumerate_caller*) getSharedInstance {
    if (our_BGService_enumerate_caller == nil) {
        our_BGService_enumerate_caller = [[BGService_enumerate_caller alloc] init];
    }
    return our_BGService_enumerate_caller;
}

-(void) command_enumerate:(BGService_enumerate_caller_params*)caller_params {

    id<IBGServiceSingleton> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enumerate:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enumerate:(BGService_enumerate_caller_params*)caller_params {
    [[BGService_enumerate_caller getSharedInstance] command_enumerate:caller_params];
}

+(void) enumerate_in_thread:(BGService_enumerate_caller_params*)caller_params {
    [[BGService_enumerate_caller getSharedInstance] performSelectorInBackground:@selector(command_enumerate:) withObject:caller_params];
}

+(void) enumerate_in_UI_thread:(BGService_enumerate_caller_params*)caller_params {
    [[BGService_enumerate_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enumerate:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_enumerate_Obj(rho::json::CJSONArray& argv, id<IBGServiceSingleton>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::enumerate"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::enumerate parameter %d is nil!", i);
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
    

    [methodResult enableObjectCreationModeWithJSClassPath:@"Rho.BGService"];

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [BGService_enumerate_caller enumerate_in_thread:[BGService_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_enumerate_caller enumerate:[BGService_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_s_BGService_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];
    return js_BGService_enumerate_Obj(argv, singleton, strCallbackID, strJsVmID, strCallbackParam);

}







@interface BGService_startBackgroundService_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_startBackgroundService_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_startBackgroundService_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_startBackgroundService_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_startBackgroundService_caller_params* par = [[[BGService_startBackgroundService_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_startBackgroundService_caller : NSObject {

}
+(BGService_startBackgroundService_caller*) getSharedInstance;
+(void) startBackgroundService:(BGService_startBackgroundService_caller_params*)caller_params;
+(void) startBackgroundService_in_thread:(BGService_startBackgroundService_caller_params*)caller_params;
+(void) startBackgroundService_in_UI_thread:(BGService_startBackgroundService_caller_params*)caller_params;

@end

static BGService_startBackgroundService_caller* our_BGService_startBackgroundService_caller = nil;

@implementation BGService_startBackgroundService_caller

+(BGService_startBackgroundService_caller*) getSharedInstance {
    if (our_BGService_startBackgroundService_caller == nil) {
        our_BGService_startBackgroundService_caller = [[BGService_startBackgroundService_caller alloc] init];
    }
    return our_BGService_startBackgroundService_caller;
}

-(void) command_startBackgroundService:(BGService_startBackgroundService_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem startBackgroundService:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) startBackgroundService:(BGService_startBackgroundService_caller_params*)caller_params {
    [[BGService_startBackgroundService_caller getSharedInstance] command_startBackgroundService:caller_params];
}

+(void) startBackgroundService_in_thread:(BGService_startBackgroundService_caller_params*)caller_params {
    [[BGService_startBackgroundService_caller getSharedInstance] performSelectorInBackground:@selector(command_startBackgroundService:) withObject:caller_params];
}

+(void) startBackgroundService_in_UI_thread:(BGService_startBackgroundService_caller_params*)caller_params {
    [[BGService_startBackgroundService_caller getSharedInstance] performSelectorOnMainThread:@selector(command_startBackgroundService:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_startBackgroundService_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::startBackgroundService"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "bgServiceRubyFunc", 0, 0 } };

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::startBackgroundService parameter %d is nil!", i);
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
        
        [BGService_startBackgroundService_caller startBackgroundService_in_thread:[BGService_startBackgroundService_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_startBackgroundService_caller startBackgroundService:[BGService_startBackgroundService_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_startBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_startBackgroundService_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_startBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_startBackgroundService_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_stopBackgroundService_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_stopBackgroundService_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_stopBackgroundService_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_stopBackgroundService_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_stopBackgroundService_caller_params* par = [[[BGService_stopBackgroundService_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_stopBackgroundService_caller : NSObject {

}
+(BGService_stopBackgroundService_caller*) getSharedInstance;
+(void) stopBackgroundService:(BGService_stopBackgroundService_caller_params*)caller_params;
+(void) stopBackgroundService_in_thread:(BGService_stopBackgroundService_caller_params*)caller_params;
+(void) stopBackgroundService_in_UI_thread:(BGService_stopBackgroundService_caller_params*)caller_params;

@end

static BGService_stopBackgroundService_caller* our_BGService_stopBackgroundService_caller = nil;

@implementation BGService_stopBackgroundService_caller

+(BGService_stopBackgroundService_caller*) getSharedInstance {
    if (our_BGService_stopBackgroundService_caller == nil) {
        our_BGService_stopBackgroundService_caller = [[BGService_stopBackgroundService_caller alloc] init];
    }
    return our_BGService_stopBackgroundService_caller;
}

-(void) command_stopBackgroundService:(BGService_stopBackgroundService_caller_params*)caller_params {

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem stopBackgroundService:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) stopBackgroundService:(BGService_stopBackgroundService_caller_params*)caller_params {
    [[BGService_stopBackgroundService_caller getSharedInstance] command_stopBackgroundService:caller_params];
}

+(void) stopBackgroundService_in_thread:(BGService_stopBackgroundService_caller_params*)caller_params {
    [[BGService_stopBackgroundService_caller getSharedInstance] performSelectorInBackground:@selector(command_stopBackgroundService:) withObject:caller_params];
}

+(void) stopBackgroundService_in_UI_thread:(BGService_stopBackgroundService_caller_params*)caller_params {
    [[BGService_stopBackgroundService_caller getSharedInstance] performSelectorOnMainThread:@selector(command_stopBackgroundService:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_stopBackgroundService_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::stopBackgroundService"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::stopBackgroundService parameter %d is nil!", i);
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
        
        [BGService_stopBackgroundService_caller stopBackgroundService_in_thread:[BGService_stopBackgroundService_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_stopBackgroundService_caller stopBackgroundService:[BGService_stopBackgroundService_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_stopBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_stopBackgroundService_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_stopBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_stopBackgroundService_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_checkBackgroundServiceStatus_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_checkBackgroundServiceStatus_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_checkBackgroundServiceStatus_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_checkBackgroundServiceStatus_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_checkBackgroundServiceStatus_caller_params* par = [[[BGService_checkBackgroundServiceStatus_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_checkBackgroundServiceStatus_caller : NSObject {

}
+(BGService_checkBackgroundServiceStatus_caller*) getSharedInstance;
+(void) checkBackgroundServiceStatus:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params;
+(void) checkBackgroundServiceStatus_in_thread:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params;
+(void) checkBackgroundServiceStatus_in_UI_thread:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params;

@end

static BGService_checkBackgroundServiceStatus_caller* our_BGService_checkBackgroundServiceStatus_caller = nil;

@implementation BGService_checkBackgroundServiceStatus_caller

+(BGService_checkBackgroundServiceStatus_caller*) getSharedInstance {
    if (our_BGService_checkBackgroundServiceStatus_caller == nil) {
        our_BGService_checkBackgroundServiceStatus_caller = [[BGService_checkBackgroundServiceStatus_caller alloc] init];
    }
    return our_BGService_checkBackgroundServiceStatus_caller;
}

-(void) command_checkBackgroundServiceStatus:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params {

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem checkBackgroundServiceStatus:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) checkBackgroundServiceStatus:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params {
    [[BGService_checkBackgroundServiceStatus_caller getSharedInstance] command_checkBackgroundServiceStatus:caller_params];
}

+(void) checkBackgroundServiceStatus_in_thread:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params {
    [[BGService_checkBackgroundServiceStatus_caller getSharedInstance] performSelectorInBackground:@selector(command_checkBackgroundServiceStatus:) withObject:caller_params];
}

+(void) checkBackgroundServiceStatus_in_UI_thread:(BGService_checkBackgroundServiceStatus_caller_params*)caller_params {
    [[BGService_checkBackgroundServiceStatus_caller getSharedInstance] performSelectorOnMainThread:@selector(command_checkBackgroundServiceStatus:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_checkBackgroundServiceStatus_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::checkBackgroundServiceStatus"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::checkBackgroundServiceStatus parameter %d is nil!", i);
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
        
        [BGService_checkBackgroundServiceStatus_caller checkBackgroundServiceStatus_in_thread:[BGService_checkBackgroundServiceStatus_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_checkBackgroundServiceStatus_caller checkBackgroundServiceStatus:[BGService_checkBackgroundServiceStatus_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_checkBackgroundServiceStatus(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_checkBackgroundServiceStatus_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_checkBackgroundServiceStatus(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_checkBackgroundServiceStatus_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_getProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_getProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_getProperty_caller_params* par = [[[BGService_getProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_getProperty_caller : NSObject {

}
+(BGService_getProperty_caller*) getSharedInstance;
+(void) getProperty:(BGService_getProperty_caller_params*)caller_params;
+(void) getProperty_in_thread:(BGService_getProperty_caller_params*)caller_params;
+(void) getProperty_in_UI_thread:(BGService_getProperty_caller_params*)caller_params;

@end

static BGService_getProperty_caller* our_BGService_getProperty_caller = nil;

@implementation BGService_getProperty_caller

+(BGService_getProperty_caller*) getSharedInstance {
    if (our_BGService_getProperty_caller == nil) {
        our_BGService_getProperty_caller = [[BGService_getProperty_caller alloc] init];
    }
    return our_BGService_getProperty_caller;
}

-(void) command_getProperty:(BGService_getProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperty:(BGService_getProperty_caller_params*)caller_params {
    [[BGService_getProperty_caller getSharedInstance] command_getProperty:caller_params];
}

+(void) getProperty_in_thread:(BGService_getProperty_caller_params*)caller_params {
    [[BGService_getProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperty:) withObject:caller_params];
}

+(void) getProperty_in_UI_thread:(BGService_getProperty_caller_params*)caller_params {
    [[BGService_getProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_getProperty_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::getProperty"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::getProperty parameter %d is nil!", i);
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
        
        [BGService_getProperty_caller getProperty_in_thread:[BGService_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_getProperty_caller getProperty:[BGService_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_getProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_getProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_getProperties_caller_params* par = [[[BGService_getProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_getProperties_caller : NSObject {

}
+(BGService_getProperties_caller*) getSharedInstance;
+(void) getProperties:(BGService_getProperties_caller_params*)caller_params;
+(void) getProperties_in_thread:(BGService_getProperties_caller_params*)caller_params;
+(void) getProperties_in_UI_thread:(BGService_getProperties_caller_params*)caller_params;

@end

static BGService_getProperties_caller* our_BGService_getProperties_caller = nil;

@implementation BGService_getProperties_caller

+(BGService_getProperties_caller*) getSharedInstance {
    if (our_BGService_getProperties_caller == nil) {
        our_BGService_getProperties_caller = [[BGService_getProperties_caller alloc] init];
    }
    return our_BGService_getProperties_caller;
}

-(void) command_getProperties:(BGService_getProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperties:(NSArray*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperties:(BGService_getProperties_caller_params*)caller_params {
    [[BGService_getProperties_caller getSharedInstance] command_getProperties:caller_params];
}

+(void) getProperties_in_thread:(BGService_getProperties_caller_params*)caller_params {
    [[BGService_getProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperties:) withObject:caller_params];
}

+(void) getProperties_in_UI_thread:(BGService_getProperties_caller_params*)caller_params {
    [[BGService_getProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_getProperties_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::getProperties"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::getProperties parameter %d is nil!", i);
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
        
        [BGService_getProperties_caller getProperties_in_thread:[BGService_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_getProperties_caller getProperties:[BGService_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_getAllProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_getAllProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_getAllProperties_caller_params* par = [[[BGService_getAllProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_getAllProperties_caller : NSObject {

}
+(BGService_getAllProperties_caller*) getSharedInstance;
+(void) getAllProperties:(BGService_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_thread:(BGService_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_UI_thread:(BGService_getAllProperties_caller_params*)caller_params;

@end

static BGService_getAllProperties_caller* our_BGService_getAllProperties_caller = nil;

@implementation BGService_getAllProperties_caller

+(BGService_getAllProperties_caller*) getSharedInstance {
    if (our_BGService_getAllProperties_caller == nil) {
        our_BGService_getAllProperties_caller = [[BGService_getAllProperties_caller alloc] init];
    }
    return our_BGService_getAllProperties_caller;
}

-(void) command_getAllProperties:(BGService_getAllProperties_caller_params*)caller_params {

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getAllProperties:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getAllProperties:(BGService_getAllProperties_caller_params*)caller_params {
    [[BGService_getAllProperties_caller getSharedInstance] command_getAllProperties:caller_params];
}

+(void) getAllProperties_in_thread:(BGService_getAllProperties_caller_params*)caller_params {
    [[BGService_getAllProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getAllProperties:) withObject:caller_params];
}

+(void) getAllProperties_in_UI_thread:(BGService_getAllProperties_caller_params*)caller_params {
    [[BGService_getAllProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getAllProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_getAllProperties_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::getAllProperties"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::getAllProperties parameter %d is nil!", i);
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
        
        [BGService_getAllProperties_caller getAllProperties_in_thread:[BGService_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_getAllProperties_caller getAllProperties:[BGService_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_setProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_setProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_setProperty_caller_params* par = [[[BGService_setProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_setProperty_caller : NSObject {

}
+(BGService_setProperty_caller*) getSharedInstance;
+(void) setProperty:(BGService_setProperty_caller_params*)caller_params;
+(void) setProperty_in_thread:(BGService_setProperty_caller_params*)caller_params;
+(void) setProperty_in_UI_thread:(BGService_setProperty_caller_params*)caller_params;

@end

static BGService_setProperty_caller* our_BGService_setProperty_caller = nil;

@implementation BGService_setProperty_caller

+(BGService_setProperty_caller*) getSharedInstance {
    if (our_BGService_setProperty_caller == nil) {
        our_BGService_setProperty_caller = [[BGService_setProperty_caller alloc] init];
    }
    return our_BGService_setProperty_caller;
}

-(void) command_setProperty:(BGService_setProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperty:(NSString*)[params objectAtIndex:0] propertyValue:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperty:(BGService_setProperty_caller_params*)caller_params {
    [[BGService_setProperty_caller getSharedInstance] command_setProperty:caller_params];
}

+(void) setProperty_in_thread:(BGService_setProperty_caller_params*)caller_params {
    [[BGService_setProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperty:) withObject:caller_params];
}

+(void) setProperty_in_UI_thread:(BGService_setProperty_caller_params*)caller_params {
    [[BGService_setProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_setProperty_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::setProperty"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::setProperty parameter %d is nil!", i);
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
        
        [BGService_setProperty_caller setProperty_in_thread:[BGService_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_setProperty_caller setProperty:[BGService_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface BGService_setProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IBGService> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(BGService_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation BGService_setProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(BGService_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IBGService>)_item _methodResult:(CMethodResult*)_methodResult {
    BGService_setProperties_caller_params* par = [[[BGService_setProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface BGService_setProperties_caller : NSObject {

}
+(BGService_setProperties_caller*) getSharedInstance;
+(void) setProperties:(BGService_setProperties_caller_params*)caller_params;
+(void) setProperties_in_thread:(BGService_setProperties_caller_params*)caller_params;
+(void) setProperties_in_UI_thread:(BGService_setProperties_caller_params*)caller_params;

@end

static BGService_setProperties_caller* our_BGService_setProperties_caller = nil;

@implementation BGService_setProperties_caller

+(BGService_setProperties_caller*) getSharedInstance {
    if (our_BGService_setProperties_caller == nil) {
        our_BGService_setProperties_caller = [[BGService_setProperties_caller alloc] init];
    }
    return our_BGService_setProperties_caller;
}

-(void) command_setProperties:(BGService_setProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IBGService> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperties:(NSDictionary*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperties:(BGService_setProperties_caller_params*)caller_params {
    [[BGService_setProperties_caller getSharedInstance] command_setProperties:caller_params];
}

+(void) setProperties_in_thread:(BGService_setProperties_caller_params*)caller_params {
    [[BGService_setProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperties:) withObject:caller_params];
}

+(void) setProperties_in_UI_thread:(BGService_setProperties_caller_params*)caller_params {
    [[BGService_setProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_BGService_setProperties_Obj(rho::json::CJSONArray& argv, id<IBGService>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"BGService::setProperties"];

    
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
                params[i] = BGService_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"BGService::setProperties parameter %d is nil!", i);
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
        
        [BGService_setProperties_caller setProperties_in_thread:[BGService_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [BGService_setProperties_caller setProperties:[BGService_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_BGService_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IBGService> item = BGService_makeInstanceByJSObject(strObjID);
    return js_BGService_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_BGService_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IBGService> item = [factory getBGServiceByID:defID];
    return js_BGService_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







rho::String js_s_BGService_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:defID level:0] UTF8String];

    return res;
}

rho::String js_s_BGService_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:[CRhoAPIClassInstance rubyClassByName:@"Rho.BGService" instanceID:defID] level:0] UTF8String];

    return res;
}

rho::String js_s_BGService_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IBGServiceFactory> factory = [BGServiceFactorySingleton getBGServiceFactoryInstance];
    id<IBGServiceSingleton> singleton = [factory getBGServiceSingleton];

    rho::json::CJSONEntry el = argv[0];

    if (el.isString()) {
        NSString* defID = [NSString stringWithUTF8String:(el.getString())];

        [singleton setDefaultID:defID];

        return [[CJSConverter convertToJS:nil level:0] UTF8String];
    }

    return "\"result\":null,\"error\":\"Method parameter should be defined as string!\"";
}

