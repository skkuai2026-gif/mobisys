
#import "IPdfgen.h"
//#import "api_generator/common/ruby_helpers.h"

#include "api_generator/js_helpers.h"

#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CJSConverter.h"

extern VALUE getRuby_Pdfgen_Module();



id<IPdfgen> Pdfgen_makeInstanceByJSObject(rho::String sid) {
    const char* szID = sid.c_str();
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    return [factory getPdfgenByID:[NSString stringWithUTF8String:szID]];
}









@interface Pdfgen_getSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_getSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_getSimpleStringProperty_caller_params* par = [[[Pdfgen_getSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_getSimpleStringProperty_caller : NSObject {

}
+(Pdfgen_getSimpleStringProperty_caller*) getSharedInstance;
+(void) getSimpleStringProperty:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_thread:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_UI_thread:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params;

@end

static Pdfgen_getSimpleStringProperty_caller* our_Pdfgen_getSimpleStringProperty_caller = nil;

@implementation Pdfgen_getSimpleStringProperty_caller

+(Pdfgen_getSimpleStringProperty_caller*) getSharedInstance {
    if (our_Pdfgen_getSimpleStringProperty_caller == nil) {
        our_Pdfgen_getSimpleStringProperty_caller = [[Pdfgen_getSimpleStringProperty_caller alloc] init];
    }
    return our_Pdfgen_getSimpleStringProperty_caller;
}

-(void) command_getSimpleStringProperty:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params {

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getSimpleStringProperty:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getSimpleStringProperty:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params {
    [[Pdfgen_getSimpleStringProperty_caller getSharedInstance] command_getSimpleStringProperty:caller_params];
}

+(void) getSimpleStringProperty_in_thread:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params {
    [[Pdfgen_getSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getSimpleStringProperty:) withObject:caller_params];
}

+(void) getSimpleStringProperty_in_UI_thread:(Pdfgen_getSimpleStringProperty_caller_params*)caller_params {
    [[Pdfgen_getSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_getSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::simpleStringProperty"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::getSimpleStringProperty parameter %d is nil!", i);
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
        
        [Pdfgen_getSimpleStringProperty_caller getSimpleStringProperty_in_thread:[Pdfgen_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_getSimpleStringProperty_caller getSimpleStringProperty:[Pdfgen_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_setSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_setSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_setSimpleStringProperty_caller_params* par = [[[Pdfgen_setSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_setSimpleStringProperty_caller : NSObject {

}
+(Pdfgen_setSimpleStringProperty_caller*) getSharedInstance;
+(void) setSimpleStringProperty:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_thread:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_UI_thread:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params;

@end

static Pdfgen_setSimpleStringProperty_caller* our_Pdfgen_setSimpleStringProperty_caller = nil;

@implementation Pdfgen_setSimpleStringProperty_caller

+(Pdfgen_setSimpleStringProperty_caller*) getSharedInstance {
    if (our_Pdfgen_setSimpleStringProperty_caller == nil) {
        our_Pdfgen_setSimpleStringProperty_caller = [[Pdfgen_setSimpleStringProperty_caller alloc] init];
    }
    return our_Pdfgen_setSimpleStringProperty_caller;
}

-(void) command_setSimpleStringProperty:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setSimpleStringProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setSimpleStringProperty:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params {
    [[Pdfgen_setSimpleStringProperty_caller getSharedInstance] command_setSimpleStringProperty:caller_params];
}

+(void) setSimpleStringProperty_in_thread:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params {
    [[Pdfgen_setSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setSimpleStringProperty:) withObject:caller_params];
}

+(void) setSimpleStringProperty_in_UI_thread:(Pdfgen_setSimpleStringProperty_caller_params*)caller_params {
    [[Pdfgen_setSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_setSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::simpleStringProperty="];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::setSimpleStringProperty parameter %d is nil!", i);
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
        
        [Pdfgen_setSimpleStringProperty_caller setSimpleStringProperty_in_thread:[Pdfgen_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_setSimpleStringProperty_caller setSimpleStringProperty:[Pdfgen_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_enumerate_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgenSingleton> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgenSingleton>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_enumerate_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgenSingleton>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_enumerate_caller_params* par = [[[Pdfgen_enumerate_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_enumerate_caller : NSObject {

}
+(Pdfgen_enumerate_caller*) getSharedInstance;
+(void) enumerate:(Pdfgen_enumerate_caller_params*)caller_params;
+(void) enumerate_in_thread:(Pdfgen_enumerate_caller_params*)caller_params;
+(void) enumerate_in_UI_thread:(Pdfgen_enumerate_caller_params*)caller_params;

@end

static Pdfgen_enumerate_caller* our_Pdfgen_enumerate_caller = nil;

@implementation Pdfgen_enumerate_caller

+(Pdfgen_enumerate_caller*) getSharedInstance {
    if (our_Pdfgen_enumerate_caller == nil) {
        our_Pdfgen_enumerate_caller = [[Pdfgen_enumerate_caller alloc] init];
    }
    return our_Pdfgen_enumerate_caller;
}

-(void) command_enumerate:(Pdfgen_enumerate_caller_params*)caller_params {

    id<IPdfgenSingleton> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enumerate:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enumerate:(Pdfgen_enumerate_caller_params*)caller_params {
    [[Pdfgen_enumerate_caller getSharedInstance] command_enumerate:caller_params];
}

+(void) enumerate_in_thread:(Pdfgen_enumerate_caller_params*)caller_params {
    [[Pdfgen_enumerate_caller getSharedInstance] performSelectorInBackground:@selector(command_enumerate:) withObject:caller_params];
}

+(void) enumerate_in_UI_thread:(Pdfgen_enumerate_caller_params*)caller_params {
    [[Pdfgen_enumerate_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enumerate:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_enumerate_Obj(rho::json::CJSONArray& argv, id<IPdfgenSingleton>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::enumerate"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::enumerate parameter %d is nil!", i);
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
    

    [methodResult enableObjectCreationModeWithJSClassPath:@"Rho.Pdfgen"];

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [Pdfgen_enumerate_caller enumerate_in_thread:[Pdfgen_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_enumerate_caller enumerate:[Pdfgen_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_s_Pdfgen_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];
    return js_Pdfgen_enumerate_Obj(argv, singleton, strCallbackID, strJsVmID, strCallbackParam);

}







@interface Pdfgen_generateAndroidPDF_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_generateAndroidPDF_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_generateAndroidPDF_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_generateAndroidPDF_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_generateAndroidPDF_caller_params* par = [[[Pdfgen_generateAndroidPDF_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_generateAndroidPDF_caller : NSObject {

}
+(Pdfgen_generateAndroidPDF_caller*) getSharedInstance;
+(void) generateAndroidPDF:(Pdfgen_generateAndroidPDF_caller_params*)caller_params;
+(void) generateAndroidPDF_in_thread:(Pdfgen_generateAndroidPDF_caller_params*)caller_params;
+(void) generateAndroidPDF_in_UI_thread:(Pdfgen_generateAndroidPDF_caller_params*)caller_params;

@end

static Pdfgen_generateAndroidPDF_caller* our_Pdfgen_generateAndroidPDF_caller = nil;

@implementation Pdfgen_generateAndroidPDF_caller

+(Pdfgen_generateAndroidPDF_caller*) getSharedInstance {
    if (our_Pdfgen_generateAndroidPDF_caller == nil) {
        our_Pdfgen_generateAndroidPDF_caller = [[Pdfgen_generateAndroidPDF_caller alloc] init];
    }
    return our_Pdfgen_generateAndroidPDF_caller;
}

-(void) command_generateAndroidPDF:(Pdfgen_generateAndroidPDF_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem generateAndroidPDF:(NSString*)[params objectAtIndex:0] orientation:(NSString*)[params objectAtIndex:1] isSinglePDFRequired:(NSString*)[params objectAtIndex:2] password:(NSString*)[params objectAtIndex:3] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) generateAndroidPDF:(Pdfgen_generateAndroidPDF_caller_params*)caller_params {
    [[Pdfgen_generateAndroidPDF_caller getSharedInstance] command_generateAndroidPDF:caller_params];
}

+(void) generateAndroidPDF_in_thread:(Pdfgen_generateAndroidPDF_caller_params*)caller_params {
    [[Pdfgen_generateAndroidPDF_caller getSharedInstance] performSelectorInBackground:@selector(command_generateAndroidPDF:) withObject:caller_params];
}

+(void) generateAndroidPDF_in_UI_thread:(Pdfgen_generateAndroidPDF_caller_params*)caller_params {
    [[Pdfgen_generateAndroidPDF_caller getSharedInstance] performSelectorOnMainThread:@selector(command_generateAndroidPDF:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_generateAndroidPDF_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[4+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::generateAndroidPDF"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "inputHTMLFileName", 0, 0 }, {RHO_API_STRING, 0, "orientation", 0, 0 }, {RHO_API_STRING, 0, "isSinglePDFRequired", 0, 0 }, {RHO_API_STRING, 0, "password", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO, NO, NO, NO };

    int i;

    // init
    for (i = 0; i < (4); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (4); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::generateAndroidPDF parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(4)];
    for (i = 0 ; i < (4); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [Pdfgen_generateAndroidPDF_caller generateAndroidPDF_in_thread:[Pdfgen_generateAndroidPDF_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_generateAndroidPDF_caller generateAndroidPDF:[Pdfgen_generateAndroidPDF_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_generateAndroidPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_generateAndroidPDF_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_generateAndroidPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_generateAndroidPDF_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_generateAndroidPDFCharts_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_generateAndroidPDFCharts_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_generateAndroidPDFCharts_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_generateAndroidPDFCharts_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_generateAndroidPDFCharts_caller_params* par = [[[Pdfgen_generateAndroidPDFCharts_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_generateAndroidPDFCharts_caller : NSObject {

}
+(Pdfgen_generateAndroidPDFCharts_caller*) getSharedInstance;
+(void) generateAndroidPDFCharts:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params;
+(void) generateAndroidPDFCharts_in_thread:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params;
+(void) generateAndroidPDFCharts_in_UI_thread:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params;

@end

static Pdfgen_generateAndroidPDFCharts_caller* our_Pdfgen_generateAndroidPDFCharts_caller = nil;

@implementation Pdfgen_generateAndroidPDFCharts_caller

+(Pdfgen_generateAndroidPDFCharts_caller*) getSharedInstance {
    if (our_Pdfgen_generateAndroidPDFCharts_caller == nil) {
        our_Pdfgen_generateAndroidPDFCharts_caller = [[Pdfgen_generateAndroidPDFCharts_caller alloc] init];
    }
    return our_Pdfgen_generateAndroidPDFCharts_caller;
}

-(void) command_generateAndroidPDFCharts:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem generateAndroidPDFCharts:(NSString*)[params objectAtIndex:0] chartOutputFileName:(NSString*)[params objectAtIndex:1] chartType:(NSString*)[params objectAtIndex:2] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) generateAndroidPDFCharts:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params {
    [[Pdfgen_generateAndroidPDFCharts_caller getSharedInstance] command_generateAndroidPDFCharts:caller_params];
}

+(void) generateAndroidPDFCharts_in_thread:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params {
    [[Pdfgen_generateAndroidPDFCharts_caller getSharedInstance] performSelectorInBackground:@selector(command_generateAndroidPDFCharts:) withObject:caller_params];
}

+(void) generateAndroidPDFCharts_in_UI_thread:(Pdfgen_generateAndroidPDFCharts_caller_params*)caller_params {
    [[Pdfgen_generateAndroidPDFCharts_caller getSharedInstance] performSelectorOnMainThread:@selector(command_generateAndroidPDFCharts:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_generateAndroidPDFCharts_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[3+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::generateAndroidPDFCharts"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "chartJSON", 0, 0 }, {RHO_API_STRING, 0, "chartOutputFileName", 0, 0 }, {RHO_API_STRING, 0, "chartType", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO, NO, NO };

    int i;

    // init
    for (i = 0; i < (3); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (3); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::generateAndroidPDFCharts parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(3)];
    for (i = 0 ; i < (3); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [Pdfgen_generateAndroidPDFCharts_caller generateAndroidPDFCharts_in_UI_thread:[Pdfgen_generateAndroidPDFCharts_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_generateAndroidPDFCharts_caller generateAndroidPDFCharts_in_UI_thread:[Pdfgen_generateAndroidPDFCharts_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        method_return_result = NO;
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_generateAndroidPDFCharts(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_generateAndroidPDFCharts_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_generateAndroidPDFCharts(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_generateAndroidPDFCharts_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_generateIOSPDF_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_generateIOSPDF_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_generateIOSPDF_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_generateIOSPDF_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_generateIOSPDF_caller_params* par = [[[Pdfgen_generateIOSPDF_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_generateIOSPDF_caller : NSObject {

}
+(Pdfgen_generateIOSPDF_caller*) getSharedInstance;
+(void) generateIOSPDF:(Pdfgen_generateIOSPDF_caller_params*)caller_params;
+(void) generateIOSPDF_in_thread:(Pdfgen_generateIOSPDF_caller_params*)caller_params;
+(void) generateIOSPDF_in_UI_thread:(Pdfgen_generateIOSPDF_caller_params*)caller_params;

@end

static Pdfgen_generateIOSPDF_caller* our_Pdfgen_generateIOSPDF_caller = nil;

@implementation Pdfgen_generateIOSPDF_caller

+(Pdfgen_generateIOSPDF_caller*) getSharedInstance {
    if (our_Pdfgen_generateIOSPDF_caller == nil) {
        our_Pdfgen_generateIOSPDF_caller = [[Pdfgen_generateIOSPDF_caller alloc] init];
    }
    return our_Pdfgen_generateIOSPDF_caller;
}

-(void) command_generateIOSPDF:(Pdfgen_generateIOSPDF_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem generateIOSPDF:(NSString*)[params objectAtIndex:0] targetFilePath:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) generateIOSPDF:(Pdfgen_generateIOSPDF_caller_params*)caller_params {
    [[Pdfgen_generateIOSPDF_caller getSharedInstance] command_generateIOSPDF:caller_params];
}

+(void) generateIOSPDF_in_thread:(Pdfgen_generateIOSPDF_caller_params*)caller_params {
    [[Pdfgen_generateIOSPDF_caller getSharedInstance] performSelectorInBackground:@selector(command_generateIOSPDF:) withObject:caller_params];
}

+(void) generateIOSPDF_in_UI_thread:(Pdfgen_generateIOSPDF_caller_params*)caller_params {
    [[Pdfgen_generateIOSPDF_caller getSharedInstance] performSelectorOnMainThread:@selector(command_generateIOSPDF:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_generateIOSPDF_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::generateIOSPDF"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "htmlContent", 0, 0 }, {RHO_API_STRING, 0, "targetFilePath", 0, 0 } };

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::generateIOSPDF parameter %d is nil!", i);
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
        
        [Pdfgen_generateIOSPDF_caller generateIOSPDF_in_thread:[Pdfgen_generateIOSPDF_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_generateIOSPDF_caller generateIOSPDF:[Pdfgen_generateIOSPDF_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_generateIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_generateIOSPDF_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_generateIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_generateIOSPDF_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_mergeIOSPDF_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_mergeIOSPDF_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_mergeIOSPDF_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_mergeIOSPDF_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_mergeIOSPDF_caller_params* par = [[[Pdfgen_mergeIOSPDF_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_mergeIOSPDF_caller : NSObject {

}
+(Pdfgen_mergeIOSPDF_caller*) getSharedInstance;
+(void) mergeIOSPDF:(Pdfgen_mergeIOSPDF_caller_params*)caller_params;
+(void) mergeIOSPDF_in_thread:(Pdfgen_mergeIOSPDF_caller_params*)caller_params;
+(void) mergeIOSPDF_in_UI_thread:(Pdfgen_mergeIOSPDF_caller_params*)caller_params;

@end

static Pdfgen_mergeIOSPDF_caller* our_Pdfgen_mergeIOSPDF_caller = nil;

@implementation Pdfgen_mergeIOSPDF_caller

+(Pdfgen_mergeIOSPDF_caller*) getSharedInstance {
    if (our_Pdfgen_mergeIOSPDF_caller == nil) {
        our_Pdfgen_mergeIOSPDF_caller = [[Pdfgen_mergeIOSPDF_caller alloc] init];
    }
    return our_Pdfgen_mergeIOSPDF_caller;
}

-(void) command_mergeIOSPDF:(Pdfgen_mergeIOSPDF_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem mergeIOSPDF:(NSString*)[params objectAtIndex:0] targetFilePath:(NSString*)[params objectAtIndex:1] masterPassword:(NSString*)[params objectAtIndex:2] password:(NSString*)[params objectAtIndex:3] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) mergeIOSPDF:(Pdfgen_mergeIOSPDF_caller_params*)caller_params {
    [[Pdfgen_mergeIOSPDF_caller getSharedInstance] command_mergeIOSPDF:caller_params];
}

+(void) mergeIOSPDF_in_thread:(Pdfgen_mergeIOSPDF_caller_params*)caller_params {
    [[Pdfgen_mergeIOSPDF_caller getSharedInstance] performSelectorInBackground:@selector(command_mergeIOSPDF:) withObject:caller_params];
}

+(void) mergeIOSPDF_in_UI_thread:(Pdfgen_mergeIOSPDF_caller_params*)caller_params {
    [[Pdfgen_mergeIOSPDF_caller getSharedInstance] performSelectorOnMainThread:@selector(command_mergeIOSPDF:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_mergeIOSPDF_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[4+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::mergeIOSPDF"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "listOfPaths", 0, 0 }, {RHO_API_STRING, 0, "targetFilePath", 0, 0 }, {RHO_API_STRING, 0, "masterPassword", 0, 0 }, {RHO_API_STRING, 0, "password", 0, 0 } };

    
    BOOL is_factory_param[] = { NO, NO, NO, NO, NO };

    int i;

    // init
    for (i = 0; i < (4); i++) {
        params[i] = [CJSConverter getObjectiveCNULL];
    }

    

    // enumerate params
    for (int i = 0; i < (4); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::mergeIOSPDF parameter %d is nil!", i);
                rho::String resValue = rho::String("\"result\":null,\"error\":\"Method parameter is nil!\"");
                return resValue;
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(4)];
    for (i = 0 ; i < (4); i++) {
        [params_array addObject:params[i]];
    }

    
        if (strCallbackID.size() > 0) {
            method_receive_callback = YES;
        }
    

    

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [Pdfgen_mergeIOSPDF_caller mergeIOSPDF_in_thread:[Pdfgen_mergeIOSPDF_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_mergeIOSPDF_caller mergeIOSPDF:[Pdfgen_mergeIOSPDF_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_mergeIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_mergeIOSPDF_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_mergeIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_mergeIOSPDF_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_getProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_getProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_getProperty_caller_params* par = [[[Pdfgen_getProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_getProperty_caller : NSObject {

}
+(Pdfgen_getProperty_caller*) getSharedInstance;
+(void) getProperty:(Pdfgen_getProperty_caller_params*)caller_params;
+(void) getProperty_in_thread:(Pdfgen_getProperty_caller_params*)caller_params;
+(void) getProperty_in_UI_thread:(Pdfgen_getProperty_caller_params*)caller_params;

@end

static Pdfgen_getProperty_caller* our_Pdfgen_getProperty_caller = nil;

@implementation Pdfgen_getProperty_caller

+(Pdfgen_getProperty_caller*) getSharedInstance {
    if (our_Pdfgen_getProperty_caller == nil) {
        our_Pdfgen_getProperty_caller = [[Pdfgen_getProperty_caller alloc] init];
    }
    return our_Pdfgen_getProperty_caller;
}

-(void) command_getProperty:(Pdfgen_getProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperty:(Pdfgen_getProperty_caller_params*)caller_params {
    [[Pdfgen_getProperty_caller getSharedInstance] command_getProperty:caller_params];
}

+(void) getProperty_in_thread:(Pdfgen_getProperty_caller_params*)caller_params {
    [[Pdfgen_getProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperty:) withObject:caller_params];
}

+(void) getProperty_in_UI_thread:(Pdfgen_getProperty_caller_params*)caller_params {
    [[Pdfgen_getProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_getProperty_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::getProperty"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::getProperty parameter %d is nil!", i);
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
        
        [Pdfgen_getProperty_caller getProperty_in_thread:[Pdfgen_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_getProperty_caller getProperty:[Pdfgen_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_getProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_getProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_getProperties_caller_params* par = [[[Pdfgen_getProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_getProperties_caller : NSObject {

}
+(Pdfgen_getProperties_caller*) getSharedInstance;
+(void) getProperties:(Pdfgen_getProperties_caller_params*)caller_params;
+(void) getProperties_in_thread:(Pdfgen_getProperties_caller_params*)caller_params;
+(void) getProperties_in_UI_thread:(Pdfgen_getProperties_caller_params*)caller_params;

@end

static Pdfgen_getProperties_caller* our_Pdfgen_getProperties_caller = nil;

@implementation Pdfgen_getProperties_caller

+(Pdfgen_getProperties_caller*) getSharedInstance {
    if (our_Pdfgen_getProperties_caller == nil) {
        our_Pdfgen_getProperties_caller = [[Pdfgen_getProperties_caller alloc] init];
    }
    return our_Pdfgen_getProperties_caller;
}

-(void) command_getProperties:(Pdfgen_getProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperties:(NSArray*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperties:(Pdfgen_getProperties_caller_params*)caller_params {
    [[Pdfgen_getProperties_caller getSharedInstance] command_getProperties:caller_params];
}

+(void) getProperties_in_thread:(Pdfgen_getProperties_caller_params*)caller_params {
    [[Pdfgen_getProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperties:) withObject:caller_params];
}

+(void) getProperties_in_UI_thread:(Pdfgen_getProperties_caller_params*)caller_params {
    [[Pdfgen_getProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_getProperties_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::getProperties"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::getProperties parameter %d is nil!", i);
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
        
        [Pdfgen_getProperties_caller getProperties_in_thread:[Pdfgen_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_getProperties_caller getProperties:[Pdfgen_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_getAllProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_getAllProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_getAllProperties_caller_params* par = [[[Pdfgen_getAllProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_getAllProperties_caller : NSObject {

}
+(Pdfgen_getAllProperties_caller*) getSharedInstance;
+(void) getAllProperties:(Pdfgen_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_thread:(Pdfgen_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_UI_thread:(Pdfgen_getAllProperties_caller_params*)caller_params;

@end

static Pdfgen_getAllProperties_caller* our_Pdfgen_getAllProperties_caller = nil;

@implementation Pdfgen_getAllProperties_caller

+(Pdfgen_getAllProperties_caller*) getSharedInstance {
    if (our_Pdfgen_getAllProperties_caller == nil) {
        our_Pdfgen_getAllProperties_caller = [[Pdfgen_getAllProperties_caller alloc] init];
    }
    return our_Pdfgen_getAllProperties_caller;
}

-(void) command_getAllProperties:(Pdfgen_getAllProperties_caller_params*)caller_params {

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getAllProperties:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getAllProperties:(Pdfgen_getAllProperties_caller_params*)caller_params {
    [[Pdfgen_getAllProperties_caller getSharedInstance] command_getAllProperties:caller_params];
}

+(void) getAllProperties_in_thread:(Pdfgen_getAllProperties_caller_params*)caller_params {
    [[Pdfgen_getAllProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getAllProperties:) withObject:caller_params];
}

+(void) getAllProperties_in_UI_thread:(Pdfgen_getAllProperties_caller_params*)caller_params {
    [[Pdfgen_getAllProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getAllProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_getAllProperties_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::getAllProperties"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::getAllProperties parameter %d is nil!", i);
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
        
        [Pdfgen_getAllProperties_caller getAllProperties_in_thread:[Pdfgen_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_getAllProperties_caller getAllProperties:[Pdfgen_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_setProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_setProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_setProperty_caller_params* par = [[[Pdfgen_setProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_setProperty_caller : NSObject {

}
+(Pdfgen_setProperty_caller*) getSharedInstance;
+(void) setProperty:(Pdfgen_setProperty_caller_params*)caller_params;
+(void) setProperty_in_thread:(Pdfgen_setProperty_caller_params*)caller_params;
+(void) setProperty_in_UI_thread:(Pdfgen_setProperty_caller_params*)caller_params;

@end

static Pdfgen_setProperty_caller* our_Pdfgen_setProperty_caller = nil;

@implementation Pdfgen_setProperty_caller

+(Pdfgen_setProperty_caller*) getSharedInstance {
    if (our_Pdfgen_setProperty_caller == nil) {
        our_Pdfgen_setProperty_caller = [[Pdfgen_setProperty_caller alloc] init];
    }
    return our_Pdfgen_setProperty_caller;
}

-(void) command_setProperty:(Pdfgen_setProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperty:(NSString*)[params objectAtIndex:0] propertyValue:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperty:(Pdfgen_setProperty_caller_params*)caller_params {
    [[Pdfgen_setProperty_caller getSharedInstance] command_setProperty:caller_params];
}

+(void) setProperty_in_thread:(Pdfgen_setProperty_caller_params*)caller_params {
    [[Pdfgen_setProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperty:) withObject:caller_params];
}

+(void) setProperty_in_UI_thread:(Pdfgen_setProperty_caller_params*)caller_params {
    [[Pdfgen_setProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_setProperty_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::setProperty"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::setProperty parameter %d is nil!", i);
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
        
        [Pdfgen_setProperty_caller setProperty_in_thread:[Pdfgen_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_setProperty_caller setProperty:[Pdfgen_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface Pdfgen_setProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IPdfgen> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(Pdfgen_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation Pdfgen_setProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(Pdfgen_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IPdfgen>)_item _methodResult:(CMethodResult*)_methodResult {
    Pdfgen_setProperties_caller_params* par = [[[Pdfgen_setProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface Pdfgen_setProperties_caller : NSObject {

}
+(Pdfgen_setProperties_caller*) getSharedInstance;
+(void) setProperties:(Pdfgen_setProperties_caller_params*)caller_params;
+(void) setProperties_in_thread:(Pdfgen_setProperties_caller_params*)caller_params;
+(void) setProperties_in_UI_thread:(Pdfgen_setProperties_caller_params*)caller_params;

@end

static Pdfgen_setProperties_caller* our_Pdfgen_setProperties_caller = nil;

@implementation Pdfgen_setProperties_caller

+(Pdfgen_setProperties_caller*) getSharedInstance {
    if (our_Pdfgen_setProperties_caller == nil) {
        our_Pdfgen_setProperties_caller = [[Pdfgen_setProperties_caller alloc] init];
    }
    return our_Pdfgen_setProperties_caller;
}

-(void) command_setProperties:(Pdfgen_setProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IPdfgen> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperties:(NSDictionary*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperties:(Pdfgen_setProperties_caller_params*)caller_params {
    [[Pdfgen_setProperties_caller getSharedInstance] command_setProperties:caller_params];
}

+(void) setProperties_in_thread:(Pdfgen_setProperties_caller_params*)caller_params {
    [[Pdfgen_setProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperties:) withObject:caller_params];
}

+(void) setProperties_in_UI_thread:(Pdfgen_setProperties_caller_params*)caller_params {
    [[Pdfgen_setProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_Pdfgen_setProperties_Obj(rho::json::CJSONArray& argv, id<IPdfgen>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"Pdfgen::setProperties"];

    
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
                params[i] = Pdfgen_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"Pdfgen::setProperties parameter %d is nil!", i);
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
        
        [Pdfgen_setProperties_caller setProperties_in_thread:[Pdfgen_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [Pdfgen_setProperties_caller setProperties:[Pdfgen_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_Pdfgen_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IPdfgen> item = Pdfgen_makeInstanceByJSObject(strObjID);
    return js_Pdfgen_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_Pdfgen_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IPdfgen> item = [factory getPdfgenByID:defID];
    return js_Pdfgen_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







rho::String js_s_Pdfgen_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:defID level:0] UTF8String];

    return res;
}

rho::String js_s_Pdfgen_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:[CRhoAPIClassInstance rubyClassByName:@"Rho.Pdfgen" instanceID:defID] level:0] UTF8String];

    return res;
}

rho::String js_s_Pdfgen_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IPdfgenFactory> factory = [PdfgenFactorySingleton getPdfgenFactoryInstance];
    id<IPdfgenSingleton> singleton = [factory getPdfgenSingleton];

    rho::json::CJSONEntry el = argv[0];

    if (el.isString()) {
        NSString* defID = [NSString stringWithUTF8String:(el.getString())];

        [singleton setDefaultID:defID];

        return [[CJSConverter convertToJS:nil level:0] UTF8String];
    }

    return "\"result\":null,\"error\":\"Method parameter should be defined as string!\"";
}

