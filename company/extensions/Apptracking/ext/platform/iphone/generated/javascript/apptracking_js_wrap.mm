
#import "IApptracking.h"
//#import "api_generator/common/ruby_helpers.h"

#include "api_generator/js_helpers.h"

#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CJSConverter.h"

extern VALUE getRuby_Apptracking_Module();



id<IApptracking> Apptracking_makeInstanceByJSObject(rho::String sid) {
    const char* szID = sid.c_str();
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    return [factory getApptrackingByID:[NSString stringWithUTF8String:szID]];
}









@interface Apptracking_getSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_getSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_getSimpleStringProperty_caller_params* par = [[[Apptracking_getSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_getSimpleStringProperty_caller : NSObject {

}
+(Apptracking_getSimpleStringProperty_caller*) getSharedInstance;
+(void) getSimpleStringProperty:(Apptracking_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_thread:(Apptracking_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_UI_thread:(Apptracking_getSimpleStringProperty_caller_params*)caller_params;

@end

static Apptracking_getSimpleStringProperty_caller* our_Apptracking_getSimpleStringProperty_caller = nil;

@implementation Apptracking_getSimpleStringProperty_caller

+(Apptracking_getSimpleStringProperty_caller*) getSharedInstance {
    if (our_Apptracking_getSimpleStringProperty_caller == nil) {
        our_Apptracking_getSimpleStringProperty_caller = [[Apptracking_getSimpleStringProperty_caller alloc] init];
    }
    return our_Apptracking_getSimpleStringProperty_caller;
}

-(void) command_getSimpleStringProperty:(Apptracking_getSimpleStringProperty_caller_params*)caller_params {

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getSimpleStringProperty:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getSimpleStringProperty:(Apptracking_getSimpleStringProperty_caller_params*)caller_params {
    [[Apptracking_getSimpleStringProperty_caller getSharedInstance] command_getSimpleStringProperty:caller_params];
}

+(void) getSimpleStringProperty_in_thread:(Apptracking_getSimpleStringProperty_caller_params*)caller_params {
    [[Apptracking_getSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getSimpleStringProperty:) withObject:caller_params];
}

+(void) getSimpleStringProperty_in_UI_thread:(Apptracking_getSimpleStringProperty_caller_params*)caller_params {
    [[Apptracking_getSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_getSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::simpleStringProperty"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::getSimpleStringProperty parameter %d is nil!", i);
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
        
        [Apptracking_getSimpleStringProperty_caller getSimpleStringProperty_in_thread:[Apptracking_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_getSimpleStringProperty_caller getSimpleStringProperty:[Apptracking_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_setSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_setSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_setSimpleStringProperty_caller_params* par = [[[Apptracking_setSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_setSimpleStringProperty_caller : NSObject {

}
+(Apptracking_setSimpleStringProperty_caller*) getSharedInstance;
+(void) setSimpleStringProperty:(Apptracking_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_thread:(Apptracking_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_UI_thread:(Apptracking_setSimpleStringProperty_caller_params*)caller_params;

@end

static Apptracking_setSimpleStringProperty_caller* our_Apptracking_setSimpleStringProperty_caller = nil;

@implementation Apptracking_setSimpleStringProperty_caller

+(Apptracking_setSimpleStringProperty_caller*) getSharedInstance {
    if (our_Apptracking_setSimpleStringProperty_caller == nil) {
        our_Apptracking_setSimpleStringProperty_caller = [[Apptracking_setSimpleStringProperty_caller alloc] init];
    }
    return our_Apptracking_setSimpleStringProperty_caller;
}

-(void) command_setSimpleStringProperty:(Apptracking_setSimpleStringProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setSimpleStringProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setSimpleStringProperty:(Apptracking_setSimpleStringProperty_caller_params*)caller_params {
    [[Apptracking_setSimpleStringProperty_caller getSharedInstance] command_setSimpleStringProperty:caller_params];
}

+(void) setSimpleStringProperty_in_thread:(Apptracking_setSimpleStringProperty_caller_params*)caller_params {
    [[Apptracking_setSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setSimpleStringProperty:) withObject:caller_params];
}

+(void) setSimpleStringProperty_in_UI_thread:(Apptracking_setSimpleStringProperty_caller_params*)caller_params {
    [[Apptracking_setSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_setSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::simpleStringProperty="];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::setSimpleStringProperty parameter %d is nil!", i);
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
        
        [Apptracking_setSimpleStringProperty_caller setSimpleStringProperty_in_thread:[Apptracking_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_setSimpleStringProperty_caller setSimpleStringProperty:[Apptracking_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_enumerate_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptrackingSingleton> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptrackingSingleton>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_enumerate_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptrackingSingleton>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_enumerate_caller_params* par = [[[Apptracking_enumerate_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_enumerate_caller : NSObject {

}
+(Apptracking_enumerate_caller*) getSharedInstance;
+(void) enumerate:(Apptracking_enumerate_caller_params*)caller_params;
+(void) enumerate_in_thread:(Apptracking_enumerate_caller_params*)caller_params;
+(void) enumerate_in_UI_thread:(Apptracking_enumerate_caller_params*)caller_params;

@end

static Apptracking_enumerate_caller* our_Apptracking_enumerate_caller = nil;

@implementation Apptracking_enumerate_caller

+(Apptracking_enumerate_caller*) getSharedInstance {
    if (our_Apptracking_enumerate_caller == nil) {
        our_Apptracking_enumerate_caller = [[Apptracking_enumerate_caller alloc] init];
    }
    return our_Apptracking_enumerate_caller;
}

-(void) command_enumerate:(Apptracking_enumerate_caller_params*)caller_params {

    id<IApptrackingSingleton> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enumerate:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enumerate:(Apptracking_enumerate_caller_params*)caller_params {
    [[Apptracking_enumerate_caller getSharedInstance] command_enumerate:caller_params];
}

+(void) enumerate_in_thread:(Apptracking_enumerate_caller_params*)caller_params {
    [[Apptracking_enumerate_caller getSharedInstance] performSelectorInBackground:@selector(command_enumerate:) withObject:caller_params];
}

+(void) enumerate_in_UI_thread:(Apptracking_enumerate_caller_params*)caller_params {
    [[Apptracking_enumerate_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enumerate:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_enumerate_Obj(rho::json::CJSONArray& argv, id<IApptrackingSingleton>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::enumerate"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::enumerate parameter %d is nil!", i);
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
    

    [methodResult enableObjectCreationModeWithJSClassPath:@"Rho.Apptracking"];

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [Apptracking_enumerate_caller enumerate_in_thread:[Apptracking_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_enumerate_caller enumerate:[Apptracking_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_s_Apptracking_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];
    return js_Apptracking_enumerate_Obj(argv, singleton, strCallbackID, strJsVmID, strCallbackParam);

}







@interface Apptracking_requestAppTrackingPermission_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_requestAppTrackingPermission_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_requestAppTrackingPermission_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_requestAppTrackingPermission_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_requestAppTrackingPermission_caller_params* par = [[[Apptracking_requestAppTrackingPermission_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_requestAppTrackingPermission_caller : NSObject {

}
+(Apptracking_requestAppTrackingPermission_caller*) getSharedInstance;
+(void) requestAppTrackingPermission:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params;
+(void) requestAppTrackingPermission_in_thread:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params;
+(void) requestAppTrackingPermission_in_UI_thread:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params;

@end

static Apptracking_requestAppTrackingPermission_caller* our_Apptracking_requestAppTrackingPermission_caller = nil;

@implementation Apptracking_requestAppTrackingPermission_caller

+(Apptracking_requestAppTrackingPermission_caller*) getSharedInstance {
    if (our_Apptracking_requestAppTrackingPermission_caller == nil) {
        our_Apptracking_requestAppTrackingPermission_caller = [[Apptracking_requestAppTrackingPermission_caller alloc] init];
    }
    return our_Apptracking_requestAppTrackingPermission_caller;
}

-(void) command_requestAppTrackingPermission:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params {

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem requestAppTrackingPermission:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) requestAppTrackingPermission:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params {
    [[Apptracking_requestAppTrackingPermission_caller getSharedInstance] command_requestAppTrackingPermission:caller_params];
}

+(void) requestAppTrackingPermission_in_thread:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params {
    [[Apptracking_requestAppTrackingPermission_caller getSharedInstance] performSelectorInBackground:@selector(command_requestAppTrackingPermission:) withObject:caller_params];
}

+(void) requestAppTrackingPermission_in_UI_thread:(Apptracking_requestAppTrackingPermission_caller_params*)caller_params {
    [[Apptracking_requestAppTrackingPermission_caller getSharedInstance] performSelectorOnMainThread:@selector(command_requestAppTrackingPermission:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_requestAppTrackingPermission_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::requestAppTrackingPermission"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::requestAppTrackingPermission parameter %d is nil!", i);
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
        
        [Apptracking_requestAppTrackingPermission_caller requestAppTrackingPermission_in_thread:[Apptracking_requestAppTrackingPermission_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_requestAppTrackingPermission_caller requestAppTrackingPermission:[Apptracking_requestAppTrackingPermission_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_requestAppTrackingPermission(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_requestAppTrackingPermission_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_requestAppTrackingPermission(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_requestAppTrackingPermission_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_getProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_getProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_getProperty_caller_params* par = [[[Apptracking_getProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_getProperty_caller : NSObject {

}
+(Apptracking_getProperty_caller*) getSharedInstance;
+(void) getProperty:(Apptracking_getProperty_caller_params*)caller_params;
+(void) getProperty_in_thread:(Apptracking_getProperty_caller_params*)caller_params;
+(void) getProperty_in_UI_thread:(Apptracking_getProperty_caller_params*)caller_params;

@end

static Apptracking_getProperty_caller* our_Apptracking_getProperty_caller = nil;

@implementation Apptracking_getProperty_caller

+(Apptracking_getProperty_caller*) getSharedInstance {
    if (our_Apptracking_getProperty_caller == nil) {
        our_Apptracking_getProperty_caller = [[Apptracking_getProperty_caller alloc] init];
    }
    return our_Apptracking_getProperty_caller;
}

-(void) command_getProperty:(Apptracking_getProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperty:(Apptracking_getProperty_caller_params*)caller_params {
    [[Apptracking_getProperty_caller getSharedInstance] command_getProperty:caller_params];
}

+(void) getProperty_in_thread:(Apptracking_getProperty_caller_params*)caller_params {
    [[Apptracking_getProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperty:) withObject:caller_params];
}

+(void) getProperty_in_UI_thread:(Apptracking_getProperty_caller_params*)caller_params {
    [[Apptracking_getProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_getProperty_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::getProperty"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::getProperty parameter %d is nil!", i);
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
        
        [Apptracking_getProperty_caller getProperty_in_thread:[Apptracking_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_getProperty_caller getProperty:[Apptracking_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_getProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_getProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_getProperties_caller_params* par = [[[Apptracking_getProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_getProperties_caller : NSObject {

}
+(Apptracking_getProperties_caller*) getSharedInstance;
+(void) getProperties:(Apptracking_getProperties_caller_params*)caller_params;
+(void) getProperties_in_thread:(Apptracking_getProperties_caller_params*)caller_params;
+(void) getProperties_in_UI_thread:(Apptracking_getProperties_caller_params*)caller_params;

@end

static Apptracking_getProperties_caller* our_Apptracking_getProperties_caller = nil;

@implementation Apptracking_getProperties_caller

+(Apptracking_getProperties_caller*) getSharedInstance {
    if (our_Apptracking_getProperties_caller == nil) {
        our_Apptracking_getProperties_caller = [[Apptracking_getProperties_caller alloc] init];
    }
    return our_Apptracking_getProperties_caller;
}

-(void) command_getProperties:(Apptracking_getProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperties:(NSArray*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperties:(Apptracking_getProperties_caller_params*)caller_params {
    [[Apptracking_getProperties_caller getSharedInstance] command_getProperties:caller_params];
}

+(void) getProperties_in_thread:(Apptracking_getProperties_caller_params*)caller_params {
    [[Apptracking_getProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperties:) withObject:caller_params];
}

+(void) getProperties_in_UI_thread:(Apptracking_getProperties_caller_params*)caller_params {
    [[Apptracking_getProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_getProperties_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::getProperties"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::getProperties parameter %d is nil!", i);
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
        
        [Apptracking_getProperties_caller getProperties_in_thread:[Apptracking_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_getProperties_caller getProperties:[Apptracking_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_getAllProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_getAllProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_getAllProperties_caller_params* par = [[[Apptracking_getAllProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_getAllProperties_caller : NSObject {

}
+(Apptracking_getAllProperties_caller*) getSharedInstance;
+(void) getAllProperties:(Apptracking_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_thread:(Apptracking_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_UI_thread:(Apptracking_getAllProperties_caller_params*)caller_params;

@end

static Apptracking_getAllProperties_caller* our_Apptracking_getAllProperties_caller = nil;

@implementation Apptracking_getAllProperties_caller

+(Apptracking_getAllProperties_caller*) getSharedInstance {
    if (our_Apptracking_getAllProperties_caller == nil) {
        our_Apptracking_getAllProperties_caller = [[Apptracking_getAllProperties_caller alloc] init];
    }
    return our_Apptracking_getAllProperties_caller;
}

-(void) command_getAllProperties:(Apptracking_getAllProperties_caller_params*)caller_params {

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getAllProperties:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getAllProperties:(Apptracking_getAllProperties_caller_params*)caller_params {
    [[Apptracking_getAllProperties_caller getSharedInstance] command_getAllProperties:caller_params];
}

+(void) getAllProperties_in_thread:(Apptracking_getAllProperties_caller_params*)caller_params {
    [[Apptracking_getAllProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getAllProperties:) withObject:caller_params];
}

+(void) getAllProperties_in_UI_thread:(Apptracking_getAllProperties_caller_params*)caller_params {
    [[Apptracking_getAllProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getAllProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_getAllProperties_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::getAllProperties"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::getAllProperties parameter %d is nil!", i);
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
        
        [Apptracking_getAllProperties_caller getAllProperties_in_thread:[Apptracking_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_getAllProperties_caller getAllProperties:[Apptracking_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_setProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_setProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_setProperty_caller_params* par = [[[Apptracking_setProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_setProperty_caller : NSObject {

}
+(Apptracking_setProperty_caller*) getSharedInstance;
+(void) setProperty:(Apptracking_setProperty_caller_params*)caller_params;
+(void) setProperty_in_thread:(Apptracking_setProperty_caller_params*)caller_params;
+(void) setProperty_in_UI_thread:(Apptracking_setProperty_caller_params*)caller_params;

@end

static Apptracking_setProperty_caller* our_Apptracking_setProperty_caller = nil;

@implementation Apptracking_setProperty_caller

+(Apptracking_setProperty_caller*) getSharedInstance {
    if (our_Apptracking_setProperty_caller == nil) {
        our_Apptracking_setProperty_caller = [[Apptracking_setProperty_caller alloc] init];
    }
    return our_Apptracking_setProperty_caller;
}

-(void) command_setProperty:(Apptracking_setProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperty:(NSString*)[params objectAtIndex:0] propertyValue:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperty:(Apptracking_setProperty_caller_params*)caller_params {
    [[Apptracking_setProperty_caller getSharedInstance] command_setProperty:caller_params];
}

+(void) setProperty_in_thread:(Apptracking_setProperty_caller_params*)caller_params {
    [[Apptracking_setProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperty:) withObject:caller_params];
}

+(void) setProperty_in_UI_thread:(Apptracking_setProperty_caller_params*)caller_params {
    [[Apptracking_setProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_setProperty_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::setProperty"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::setProperty parameter %d is nil!", i);
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
        
        [Apptracking_setProperty_caller setProperty_in_thread:[Apptracking_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_setProperty_caller setProperty:[Apptracking_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Apptracking_setProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IApptracking> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Apptracking_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Apptracking_setProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Apptracking_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IApptracking>)_item _methodResult:(CMethodResult*)_methodResult {
    Apptracking_setProperties_caller_params* par = [[[Apptracking_setProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Apptracking_setProperties_caller : NSObject {

}
+(Apptracking_setProperties_caller*) getSharedInstance;
+(void) setProperties:(Apptracking_setProperties_caller_params*)caller_params;
+(void) setProperties_in_thread:(Apptracking_setProperties_caller_params*)caller_params;
+(void) setProperties_in_UI_thread:(Apptracking_setProperties_caller_params*)caller_params;

@end

static Apptracking_setProperties_caller* our_Apptracking_setProperties_caller = nil;

@implementation Apptracking_setProperties_caller

+(Apptracking_setProperties_caller*) getSharedInstance {
    if (our_Apptracking_setProperties_caller == nil) {
        our_Apptracking_setProperties_caller = [[Apptracking_setProperties_caller alloc] init];
    }
    return our_Apptracking_setProperties_caller;
}

-(void) command_setProperties:(Apptracking_setProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IApptracking> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperties:(NSDictionary*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperties:(Apptracking_setProperties_caller_params*)caller_params {
    [[Apptracking_setProperties_caller getSharedInstance] command_setProperties:caller_params];
}

+(void) setProperties_in_thread:(Apptracking_setProperties_caller_params*)caller_params {
    [[Apptracking_setProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperties:) withObject:caller_params];
}

+(void) setProperties_in_UI_thread:(Apptracking_setProperties_caller_params*)caller_params {
    [[Apptracking_setProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Apptracking_setProperties_Obj(rho::json::CJSONArray& argv, id<IApptracking>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Apptracking::setProperties"];

    
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
                params[i] = Apptracking_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Apptracking::setProperties parameter %d is nil!", i);
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
        
        [Apptracking_setProperties_caller setProperties_in_thread:[Apptracking_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Apptracking_setProperties_caller setProperties:[Apptracking_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Apptracking_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IApptracking> item = Apptracking_makeInstanceByJSObject(strObjID);
    return js_Apptracking_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Apptracking_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IApptracking> item = [factory getApptrackingByID:defID];
    return js_Apptracking_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







rho::String js_s_Apptracking_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:defID level:0] UTF8String];

    return res;
}

rho::String js_s_Apptracking_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:[CRhoAPIClassInstance rubyClassByName:@"Rho.Apptracking" instanceID:defID] level:0] UTF8String];

    return res;
}

rho::String js_s_Apptracking_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IApptrackingFactory> factory = [ApptrackingFactorySingleton getApptrackingFactoryInstance];
    id<IApptrackingSingleton> singleton = [factory getApptrackingSingleton];

    rho::json::CJSONEntry el = argv[0];

    if (el.isString()) {
        NSString* defID = [NSString stringWithUTF8String:(el.getString())];

        [singleton setDefaultID:defID];

        return [[CJSConverter convertToJS:nil level:0] UTF8String];
    }

    return "\"result\":null,\"error\":\"Method parameter should be defined as string!\"";
}

