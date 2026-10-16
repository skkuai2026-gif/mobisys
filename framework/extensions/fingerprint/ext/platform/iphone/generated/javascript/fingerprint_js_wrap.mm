
#import "IFingerprint.h"
//#import "api_generator/common/ruby_helpers.h"

#include "api_generator/js_helpers.h"

#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CJSConverter.h"

extern VALUE getRuby_Fingerprint_Module();



id<IFingerprint> Fingerprint_makeInstanceByJSObject(rho::String sid) {
    const char* szID = sid.c_str();
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    return [factory getFingerprintByID:[NSString stringWithUTF8String:szID]];
}









@interface Fingerprint_getSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_getSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_getSimpleStringProperty_caller_params* par = [[[Fingerprint_getSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_getSimpleStringProperty_caller : NSObject {

}
+(Fingerprint_getSimpleStringProperty_caller*) getSharedInstance;
+(void) getSimpleStringProperty:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_thread:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_UI_thread:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params;

@end

static Fingerprint_getSimpleStringProperty_caller* our_Fingerprint_getSimpleStringProperty_caller = nil;

@implementation Fingerprint_getSimpleStringProperty_caller

+(Fingerprint_getSimpleStringProperty_caller*) getSharedInstance {
    if (our_Fingerprint_getSimpleStringProperty_caller == nil) {
        our_Fingerprint_getSimpleStringProperty_caller = [[Fingerprint_getSimpleStringProperty_caller alloc] init];
    }
    return our_Fingerprint_getSimpleStringProperty_caller;
}

-(void) command_getSimpleStringProperty:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params {

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getSimpleStringProperty:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getSimpleStringProperty:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params {
    [[Fingerprint_getSimpleStringProperty_caller getSharedInstance] command_getSimpleStringProperty:caller_params];
}

+(void) getSimpleStringProperty_in_thread:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params {
    [[Fingerprint_getSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getSimpleStringProperty:) withObject:caller_params];
}

+(void) getSimpleStringProperty_in_UI_thread:(Fingerprint_getSimpleStringProperty_caller_params*)caller_params {
    [[Fingerprint_getSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_getSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::simpleStringProperty"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::getSimpleStringProperty parameter %d is nil!", i);
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
        
        [Fingerprint_getSimpleStringProperty_caller getSimpleStringProperty_in_thread:[Fingerprint_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_getSimpleStringProperty_caller getSimpleStringProperty:[Fingerprint_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_setSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_setSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_setSimpleStringProperty_caller_params* par = [[[Fingerprint_setSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_setSimpleStringProperty_caller : NSObject {

}
+(Fingerprint_setSimpleStringProperty_caller*) getSharedInstance;
+(void) setSimpleStringProperty:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_thread:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_UI_thread:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params;

@end

static Fingerprint_setSimpleStringProperty_caller* our_Fingerprint_setSimpleStringProperty_caller = nil;

@implementation Fingerprint_setSimpleStringProperty_caller

+(Fingerprint_setSimpleStringProperty_caller*) getSharedInstance {
    if (our_Fingerprint_setSimpleStringProperty_caller == nil) {
        our_Fingerprint_setSimpleStringProperty_caller = [[Fingerprint_setSimpleStringProperty_caller alloc] init];
    }
    return our_Fingerprint_setSimpleStringProperty_caller;
}

-(void) command_setSimpleStringProperty:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setSimpleStringProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setSimpleStringProperty:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params {
    [[Fingerprint_setSimpleStringProperty_caller getSharedInstance] command_setSimpleStringProperty:caller_params];
}

+(void) setSimpleStringProperty_in_thread:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params {
    [[Fingerprint_setSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setSimpleStringProperty:) withObject:caller_params];
}

+(void) setSimpleStringProperty_in_UI_thread:(Fingerprint_setSimpleStringProperty_caller_params*)caller_params {
    [[Fingerprint_setSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_setSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::simpleStringProperty="];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::setSimpleStringProperty parameter %d is nil!", i);
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
        
        [Fingerprint_setSimpleStringProperty_caller setSimpleStringProperty_in_thread:[Fingerprint_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_setSimpleStringProperty_caller setSimpleStringProperty:[Fingerprint_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_enumerate_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprintSingleton> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprintSingleton>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_enumerate_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprintSingleton>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_enumerate_caller_params* par = [[[Fingerprint_enumerate_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_enumerate_caller : NSObject {

}
+(Fingerprint_enumerate_caller*) getSharedInstance;
+(void) enumerate:(Fingerprint_enumerate_caller_params*)caller_params;
+(void) enumerate_in_thread:(Fingerprint_enumerate_caller_params*)caller_params;
+(void) enumerate_in_UI_thread:(Fingerprint_enumerate_caller_params*)caller_params;

@end

static Fingerprint_enumerate_caller* our_Fingerprint_enumerate_caller = nil;

@implementation Fingerprint_enumerate_caller

+(Fingerprint_enumerate_caller*) getSharedInstance {
    if (our_Fingerprint_enumerate_caller == nil) {
        our_Fingerprint_enumerate_caller = [[Fingerprint_enumerate_caller alloc] init];
    }
    return our_Fingerprint_enumerate_caller;
}

-(void) command_enumerate:(Fingerprint_enumerate_caller_params*)caller_params {

    id<IFingerprintSingleton> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enumerate:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enumerate:(Fingerprint_enumerate_caller_params*)caller_params {
    [[Fingerprint_enumerate_caller getSharedInstance] command_enumerate:caller_params];
}

+(void) enumerate_in_thread:(Fingerprint_enumerate_caller_params*)caller_params {
    [[Fingerprint_enumerate_caller getSharedInstance] performSelectorInBackground:@selector(command_enumerate:) withObject:caller_params];
}

+(void) enumerate_in_UI_thread:(Fingerprint_enumerate_caller_params*)caller_params {
    [[Fingerprint_enumerate_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enumerate:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_enumerate_Obj(rho::json::CJSONArray& argv, id<IFingerprintSingleton>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::enumerate"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::enumerate parameter %d is nil!", i);
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
    

    [methodResult enableObjectCreationModeWithJSClassPath:@"Rho.Fingerprint"];

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [Fingerprint_enumerate_caller enumerate_in_thread:[Fingerprint_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_enumerate_caller enumerate:[Fingerprint_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_s_Fingerprint_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];
    return js_Fingerprint_enumerate_Obj(argv, singleton, strCallbackID, strJsVmID, strCallbackParam);

}







@interface Fingerprint_enableFingerprintScan_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_enableFingerprintScan_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_enableFingerprintScan_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_enableFingerprintScan_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_enableFingerprintScan_caller_params* par = [[[Fingerprint_enableFingerprintScan_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_enableFingerprintScan_caller : NSObject {

}
+(Fingerprint_enableFingerprintScan_caller*) getSharedInstance;
+(void) enableFingerprintScan:(Fingerprint_enableFingerprintScan_caller_params*)caller_params;
+(void) enableFingerprintScan_in_thread:(Fingerprint_enableFingerprintScan_caller_params*)caller_params;
+(void) enableFingerprintScan_in_UI_thread:(Fingerprint_enableFingerprintScan_caller_params*)caller_params;

@end

static Fingerprint_enableFingerprintScan_caller* our_Fingerprint_enableFingerprintScan_caller = nil;

@implementation Fingerprint_enableFingerprintScan_caller

+(Fingerprint_enableFingerprintScan_caller*) getSharedInstance {
    if (our_Fingerprint_enableFingerprintScan_caller == nil) {
        our_Fingerprint_enableFingerprintScan_caller = [[Fingerprint_enableFingerprintScan_caller alloc] init];
    }
    return our_Fingerprint_enableFingerprintScan_caller;
}

-(void) command_enableFingerprintScan:(Fingerprint_enableFingerprintScan_caller_params*)caller_params {

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enableFingerprintScan:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enableFingerprintScan:(Fingerprint_enableFingerprintScan_caller_params*)caller_params {
    [[Fingerprint_enableFingerprintScan_caller getSharedInstance] command_enableFingerprintScan:caller_params];
}

+(void) enableFingerprintScan_in_thread:(Fingerprint_enableFingerprintScan_caller_params*)caller_params {
    [[Fingerprint_enableFingerprintScan_caller getSharedInstance] performSelectorInBackground:@selector(command_enableFingerprintScan:) withObject:caller_params];
}

+(void) enableFingerprintScan_in_UI_thread:(Fingerprint_enableFingerprintScan_caller_params*)caller_params {
    [[Fingerprint_enableFingerprintScan_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enableFingerprintScan:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_enableFingerprintScan_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::enableFingerprintScan"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::enableFingerprintScan parameter %d is nil!", i);
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
        
        [Fingerprint_enableFingerprintScan_caller enableFingerprintScan_in_thread:[Fingerprint_enableFingerprintScan_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_enableFingerprintScan_caller enableFingerprintScan:[Fingerprint_enableFingerprintScan_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_enableFingerprintScan(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_enableFingerprintScan_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_enableFingerprintScan(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_enableFingerprintScan_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_getProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_getProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_getProperty_caller_params* par = [[[Fingerprint_getProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_getProperty_caller : NSObject {

}
+(Fingerprint_getProperty_caller*) getSharedInstance;
+(void) getProperty:(Fingerprint_getProperty_caller_params*)caller_params;
+(void) getProperty_in_thread:(Fingerprint_getProperty_caller_params*)caller_params;
+(void) getProperty_in_UI_thread:(Fingerprint_getProperty_caller_params*)caller_params;

@end

static Fingerprint_getProperty_caller* our_Fingerprint_getProperty_caller = nil;

@implementation Fingerprint_getProperty_caller

+(Fingerprint_getProperty_caller*) getSharedInstance {
    if (our_Fingerprint_getProperty_caller == nil) {
        our_Fingerprint_getProperty_caller = [[Fingerprint_getProperty_caller alloc] init];
    }
    return our_Fingerprint_getProperty_caller;
}

-(void) command_getProperty:(Fingerprint_getProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperty:(Fingerprint_getProperty_caller_params*)caller_params {
    [[Fingerprint_getProperty_caller getSharedInstance] command_getProperty:caller_params];
}

+(void) getProperty_in_thread:(Fingerprint_getProperty_caller_params*)caller_params {
    [[Fingerprint_getProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperty:) withObject:caller_params];
}

+(void) getProperty_in_UI_thread:(Fingerprint_getProperty_caller_params*)caller_params {
    [[Fingerprint_getProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_getProperty_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::getProperty"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::getProperty parameter %d is nil!", i);
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
        
        [Fingerprint_getProperty_caller getProperty_in_thread:[Fingerprint_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_getProperty_caller getProperty:[Fingerprint_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_getProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_getProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_getProperties_caller_params* par = [[[Fingerprint_getProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_getProperties_caller : NSObject {

}
+(Fingerprint_getProperties_caller*) getSharedInstance;
+(void) getProperties:(Fingerprint_getProperties_caller_params*)caller_params;
+(void) getProperties_in_thread:(Fingerprint_getProperties_caller_params*)caller_params;
+(void) getProperties_in_UI_thread:(Fingerprint_getProperties_caller_params*)caller_params;

@end

static Fingerprint_getProperties_caller* our_Fingerprint_getProperties_caller = nil;

@implementation Fingerprint_getProperties_caller

+(Fingerprint_getProperties_caller*) getSharedInstance {
    if (our_Fingerprint_getProperties_caller == nil) {
        our_Fingerprint_getProperties_caller = [[Fingerprint_getProperties_caller alloc] init];
    }
    return our_Fingerprint_getProperties_caller;
}

-(void) command_getProperties:(Fingerprint_getProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperties:(NSArray*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperties:(Fingerprint_getProperties_caller_params*)caller_params {
    [[Fingerprint_getProperties_caller getSharedInstance] command_getProperties:caller_params];
}

+(void) getProperties_in_thread:(Fingerprint_getProperties_caller_params*)caller_params {
    [[Fingerprint_getProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperties:) withObject:caller_params];
}

+(void) getProperties_in_UI_thread:(Fingerprint_getProperties_caller_params*)caller_params {
    [[Fingerprint_getProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_getProperties_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::getProperties"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::getProperties parameter %d is nil!", i);
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
        
        [Fingerprint_getProperties_caller getProperties_in_thread:[Fingerprint_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_getProperties_caller getProperties:[Fingerprint_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_getAllProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_getAllProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_getAllProperties_caller_params* par = [[[Fingerprint_getAllProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_getAllProperties_caller : NSObject {

}
+(Fingerprint_getAllProperties_caller*) getSharedInstance;
+(void) getAllProperties:(Fingerprint_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_thread:(Fingerprint_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_UI_thread:(Fingerprint_getAllProperties_caller_params*)caller_params;

@end

static Fingerprint_getAllProperties_caller* our_Fingerprint_getAllProperties_caller = nil;

@implementation Fingerprint_getAllProperties_caller

+(Fingerprint_getAllProperties_caller*) getSharedInstance {
    if (our_Fingerprint_getAllProperties_caller == nil) {
        our_Fingerprint_getAllProperties_caller = [[Fingerprint_getAllProperties_caller alloc] init];
    }
    return our_Fingerprint_getAllProperties_caller;
}

-(void) command_getAllProperties:(Fingerprint_getAllProperties_caller_params*)caller_params {

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getAllProperties:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getAllProperties:(Fingerprint_getAllProperties_caller_params*)caller_params {
    [[Fingerprint_getAllProperties_caller getSharedInstance] command_getAllProperties:caller_params];
}

+(void) getAllProperties_in_thread:(Fingerprint_getAllProperties_caller_params*)caller_params {
    [[Fingerprint_getAllProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getAllProperties:) withObject:caller_params];
}

+(void) getAllProperties_in_UI_thread:(Fingerprint_getAllProperties_caller_params*)caller_params {
    [[Fingerprint_getAllProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getAllProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_getAllProperties_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::getAllProperties"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::getAllProperties parameter %d is nil!", i);
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
        
        [Fingerprint_getAllProperties_caller getAllProperties_in_thread:[Fingerprint_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_getAllProperties_caller getAllProperties:[Fingerprint_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_setProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_setProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_setProperty_caller_params* par = [[[Fingerprint_setProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_setProperty_caller : NSObject {

}
+(Fingerprint_setProperty_caller*) getSharedInstance;
+(void) setProperty:(Fingerprint_setProperty_caller_params*)caller_params;
+(void) setProperty_in_thread:(Fingerprint_setProperty_caller_params*)caller_params;
+(void) setProperty_in_UI_thread:(Fingerprint_setProperty_caller_params*)caller_params;

@end

static Fingerprint_setProperty_caller* our_Fingerprint_setProperty_caller = nil;

@implementation Fingerprint_setProperty_caller

+(Fingerprint_setProperty_caller*) getSharedInstance {
    if (our_Fingerprint_setProperty_caller == nil) {
        our_Fingerprint_setProperty_caller = [[Fingerprint_setProperty_caller alloc] init];
    }
    return our_Fingerprint_setProperty_caller;
}

-(void) command_setProperty:(Fingerprint_setProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperty:(NSString*)[params objectAtIndex:0] propertyValue:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperty:(Fingerprint_setProperty_caller_params*)caller_params {
    [[Fingerprint_setProperty_caller getSharedInstance] command_setProperty:caller_params];
}

+(void) setProperty_in_thread:(Fingerprint_setProperty_caller_params*)caller_params {
    [[Fingerprint_setProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperty:) withObject:caller_params];
}

+(void) setProperty_in_UI_thread:(Fingerprint_setProperty_caller_params*)caller_params {
    [[Fingerprint_setProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_setProperty_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::setProperty"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::setProperty parameter %d is nil!", i);
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
        
        [Fingerprint_setProperty_caller setProperty_in_thread:[Fingerprint_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_setProperty_caller setProperty:[Fingerprint_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Fingerprint_setProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IFingerprint> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Fingerprint_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Fingerprint_setProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Fingerprint_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IFingerprint>)_item _methodResult:(CMethodResult*)_methodResult {
    Fingerprint_setProperties_caller_params* par = [[[Fingerprint_setProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Fingerprint_setProperties_caller : NSObject {

}
+(Fingerprint_setProperties_caller*) getSharedInstance;
+(void) setProperties:(Fingerprint_setProperties_caller_params*)caller_params;
+(void) setProperties_in_thread:(Fingerprint_setProperties_caller_params*)caller_params;
+(void) setProperties_in_UI_thread:(Fingerprint_setProperties_caller_params*)caller_params;

@end

static Fingerprint_setProperties_caller* our_Fingerprint_setProperties_caller = nil;

@implementation Fingerprint_setProperties_caller

+(Fingerprint_setProperties_caller*) getSharedInstance {
    if (our_Fingerprint_setProperties_caller == nil) {
        our_Fingerprint_setProperties_caller = [[Fingerprint_setProperties_caller alloc] init];
    }
    return our_Fingerprint_setProperties_caller;
}

-(void) command_setProperties:(Fingerprint_setProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IFingerprint> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperties:(NSDictionary*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperties:(Fingerprint_setProperties_caller_params*)caller_params {
    [[Fingerprint_setProperties_caller getSharedInstance] command_setProperties:caller_params];
}

+(void) setProperties_in_thread:(Fingerprint_setProperties_caller_params*)caller_params {
    [[Fingerprint_setProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperties:) withObject:caller_params];
}

+(void) setProperties_in_UI_thread:(Fingerprint_setProperties_caller_params*)caller_params {
    [[Fingerprint_setProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Fingerprint_setProperties_Obj(rho::json::CJSONArray& argv, id<IFingerprint>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Fingerprint::setProperties"];

    
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
                params[i] = Fingerprint_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Fingerprint::setProperties parameter %d is nil!", i);
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
        
        [Fingerprint_setProperties_caller setProperties_in_thread:[Fingerprint_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Fingerprint_setProperties_caller setProperties:[Fingerprint_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Fingerprint_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IFingerprint> item = Fingerprint_makeInstanceByJSObject(strObjID);
    return js_Fingerprint_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Fingerprint_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IFingerprint> item = [factory getFingerprintByID:defID];
    return js_Fingerprint_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







rho::String js_s_Fingerprint_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:defID level:0] UTF8String];

    return res;
}

rho::String js_s_Fingerprint_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:[CRhoAPIClassInstance rubyClassByName:@"Rho.Fingerprint" instanceID:defID] level:0] UTF8String];

    return res;
}

rho::String js_s_Fingerprint_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IFingerprintFactory> factory = [FingerprintFactorySingleton getFingerprintFactoryInstance];
    id<IFingerprintSingleton> singleton = [factory getFingerprintSingleton];

    rho::json::CJSONEntry el = argv[0];

    if (el.isString()) {
        NSString* defID = [NSString stringWithUTF8String:(el.getString())];

        [singleton setDefaultID:defID];

        return [[CJSConverter convertToJS:nil level:0] UTF8String];
    }

    return "\"result\":null,\"error\":\"Method parameter should be defined as string!\"";
}

