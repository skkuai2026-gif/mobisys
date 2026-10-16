
#import "IDocumentPicker.h"
//#import "api_generator/common/ruby_helpers.h"

#include "api_generator/js_helpers.h"

#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CJSConverter.h"

extern VALUE getRuby_DocumentPicker_Module();



id<IDocumentPicker> DocumentPicker_makeInstanceByJSObject(rho::String sid) {
    const char* szID = sid.c_str();
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    return [factory getDocumentPickerByID:[NSString stringWithUTF8String:szID]];
}









@interface DocumentPicker_getSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_getSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_getSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_getSimpleStringProperty_caller_params* par = [[[DocumentPicker_getSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_getSimpleStringProperty_caller : NSObject {

}
+(DocumentPicker_getSimpleStringProperty_caller*) getSharedInstance;
+(void) getSimpleStringProperty:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_thread:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params;
+(void) getSimpleStringProperty_in_UI_thread:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params;

@end

static DocumentPicker_getSimpleStringProperty_caller* our_DocumentPicker_getSimpleStringProperty_caller = nil;

@implementation DocumentPicker_getSimpleStringProperty_caller

+(DocumentPicker_getSimpleStringProperty_caller*) getSharedInstance {
    if (our_DocumentPicker_getSimpleStringProperty_caller == nil) {
        our_DocumentPicker_getSimpleStringProperty_caller = [[DocumentPicker_getSimpleStringProperty_caller alloc] init];
    }
    return our_DocumentPicker_getSimpleStringProperty_caller;
}

-(void) command_getSimpleStringProperty:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params {

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getSimpleStringProperty:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getSimpleStringProperty:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params {
    [[DocumentPicker_getSimpleStringProperty_caller getSharedInstance] command_getSimpleStringProperty:caller_params];
}

+(void) getSimpleStringProperty_in_thread:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params {
    [[DocumentPicker_getSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getSimpleStringProperty:) withObject:caller_params];
}

+(void) getSimpleStringProperty_in_UI_thread:(DocumentPicker_getSimpleStringProperty_caller_params*)caller_params {
    [[DocumentPicker_getSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_getSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::simpleStringProperty"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::getSimpleStringProperty parameter %d is nil!", i);
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
        
        [DocumentPicker_getSimpleStringProperty_caller getSimpleStringProperty_in_thread:[DocumentPicker_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_getSimpleStringProperty_caller getSimpleStringProperty:[DocumentPicker_getSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_getSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_setSimpleStringProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_setSimpleStringProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_setSimpleStringProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_setSimpleStringProperty_caller_params* par = [[[DocumentPicker_setSimpleStringProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_setSimpleStringProperty_caller : NSObject {

}
+(DocumentPicker_setSimpleStringProperty_caller*) getSharedInstance;
+(void) setSimpleStringProperty:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_thread:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params;
+(void) setSimpleStringProperty_in_UI_thread:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params;

@end

static DocumentPicker_setSimpleStringProperty_caller* our_DocumentPicker_setSimpleStringProperty_caller = nil;

@implementation DocumentPicker_setSimpleStringProperty_caller

+(DocumentPicker_setSimpleStringProperty_caller*) getSharedInstance {
    if (our_DocumentPicker_setSimpleStringProperty_caller == nil) {
        our_DocumentPicker_setSimpleStringProperty_caller = [[DocumentPicker_setSimpleStringProperty_caller alloc] init];
    }
    return our_DocumentPicker_setSimpleStringProperty_caller;
}

-(void) command_setSimpleStringProperty:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setSimpleStringProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setSimpleStringProperty:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params {
    [[DocumentPicker_setSimpleStringProperty_caller getSharedInstance] command_setSimpleStringProperty:caller_params];
}

+(void) setSimpleStringProperty_in_thread:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params {
    [[DocumentPicker_setSimpleStringProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setSimpleStringProperty:) withObject:caller_params];
}

+(void) setSimpleStringProperty_in_UI_thread:(DocumentPicker_setSimpleStringProperty_caller_params*)caller_params {
    [[DocumentPicker_setSimpleStringProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setSimpleStringProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_setSimpleStringProperty_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::simpleStringProperty="];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::setSimpleStringProperty parameter %d is nil!", i);
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
        
        [DocumentPicker_setSimpleStringProperty_caller setSimpleStringProperty_in_thread:[DocumentPicker_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_setSimpleStringProperty_caller setSimpleStringProperty:[DocumentPicker_setSimpleStringProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_setSimpleStringProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_enumerate_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPickerSingleton> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPickerSingleton>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_enumerate_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_enumerate_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPickerSingleton>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_enumerate_caller_params* par = [[[DocumentPicker_enumerate_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_enumerate_caller : NSObject {

}
+(DocumentPicker_enumerate_caller*) getSharedInstance;
+(void) enumerate:(DocumentPicker_enumerate_caller_params*)caller_params;
+(void) enumerate_in_thread:(DocumentPicker_enumerate_caller_params*)caller_params;
+(void) enumerate_in_UI_thread:(DocumentPicker_enumerate_caller_params*)caller_params;

@end

static DocumentPicker_enumerate_caller* our_DocumentPicker_enumerate_caller = nil;

@implementation DocumentPicker_enumerate_caller

+(DocumentPicker_enumerate_caller*) getSharedInstance {
    if (our_DocumentPicker_enumerate_caller == nil) {
        our_DocumentPicker_enumerate_caller = [[DocumentPicker_enumerate_caller alloc] init];
    }
    return our_DocumentPicker_enumerate_caller;
}

-(void) command_enumerate:(DocumentPicker_enumerate_caller_params*)caller_params {

    id<IDocumentPickerSingleton> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem enumerate:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) enumerate:(DocumentPicker_enumerate_caller_params*)caller_params {
    [[DocumentPicker_enumerate_caller getSharedInstance] command_enumerate:caller_params];
}

+(void) enumerate_in_thread:(DocumentPicker_enumerate_caller_params*)caller_params {
    [[DocumentPicker_enumerate_caller getSharedInstance] performSelectorInBackground:@selector(command_enumerate:) withObject:caller_params];
}

+(void) enumerate_in_UI_thread:(DocumentPicker_enumerate_caller_params*)caller_params {
    [[DocumentPicker_enumerate_caller getSharedInstance] performSelectorOnMainThread:@selector(command_enumerate:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_enumerate_Obj(rho::json::CJSONArray& argv, id<IDocumentPickerSingleton>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::enumerate"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::enumerate parameter %d is nil!", i);
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
    

    [methodResult enableObjectCreationModeWithJSClassPath:@"Rho.DocumentPicker"];

    if (method_receive_callback) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setJSCallback:[NSString stringWithUTF8String:strCallbackID.c_str()] webViewUID:[NSString stringWithUTF8String:strJsVmID.c_str()]];
        [methodResult setCallbackParam:[NSString stringWithUTF8String:strCallbackParam.c_str()]];
        
        [DocumentPicker_enumerate_caller enumerate_in_thread:[DocumentPicker_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_enumerate_caller enumerate:[DocumentPicker_enumerate_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_s_DocumentPicker_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];
    return js_DocumentPicker_enumerate_Obj(argv, singleton, strCallbackID, strJsVmID, strCallbackParam);

}







@interface DocumentPicker_pickDocument_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_pickDocument_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_pickDocument_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_pickDocument_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_pickDocument_caller_params* par = [[[DocumentPicker_pickDocument_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_pickDocument_caller : NSObject {

}
+(DocumentPicker_pickDocument_caller*) getSharedInstance;
+(void) pickDocument:(DocumentPicker_pickDocument_caller_params*)caller_params;
+(void) pickDocument_in_thread:(DocumentPicker_pickDocument_caller_params*)caller_params;
+(void) pickDocument_in_UI_thread:(DocumentPicker_pickDocument_caller_params*)caller_params;

@end

static DocumentPicker_pickDocument_caller* our_DocumentPicker_pickDocument_caller = nil;

@implementation DocumentPicker_pickDocument_caller

+(DocumentPicker_pickDocument_caller*) getSharedInstance {
    if (our_DocumentPicker_pickDocument_caller == nil) {
        our_DocumentPicker_pickDocument_caller = [[DocumentPicker_pickDocument_caller alloc] init];
    }
    return our_DocumentPicker_pickDocument_caller;
}

-(void) command_pickDocument:(DocumentPicker_pickDocument_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem pickDocument:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) pickDocument:(DocumentPicker_pickDocument_caller_params*)caller_params {
    [[DocumentPicker_pickDocument_caller getSharedInstance] command_pickDocument:caller_params];
}

+(void) pickDocument_in_thread:(DocumentPicker_pickDocument_caller_params*)caller_params {
    [[DocumentPicker_pickDocument_caller getSharedInstance] performSelectorInBackground:@selector(command_pickDocument:) withObject:caller_params];
}

+(void) pickDocument_in_UI_thread:(DocumentPicker_pickDocument_caller_params*)caller_params {
    [[DocumentPicker_pickDocument_caller getSharedInstance] performSelectorOnMainThread:@selector(command_pickDocument:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_pickDocument_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::pickDocument"];

    
    static RHO_API_PARAM rho_api_params[] = { {RHO_API_STRING, 0, "supportedExtensionList", 0, 0 } };

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::pickDocument parameter %d is nil!", i);
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
        
        [DocumentPicker_pickDocument_caller pickDocument_in_thread:[DocumentPicker_pickDocument_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_pickDocument_caller pickDocument:[DocumentPicker_pickDocument_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_pickDocument(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_pickDocument_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_pickDocument(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_pickDocument_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_getProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_getProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_getProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_getProperty_caller_params* par = [[[DocumentPicker_getProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_getProperty_caller : NSObject {

}
+(DocumentPicker_getProperty_caller*) getSharedInstance;
+(void) getProperty:(DocumentPicker_getProperty_caller_params*)caller_params;
+(void) getProperty_in_thread:(DocumentPicker_getProperty_caller_params*)caller_params;
+(void) getProperty_in_UI_thread:(DocumentPicker_getProperty_caller_params*)caller_params;

@end

static DocumentPicker_getProperty_caller* our_DocumentPicker_getProperty_caller = nil;

@implementation DocumentPicker_getProperty_caller

+(DocumentPicker_getProperty_caller*) getSharedInstance {
    if (our_DocumentPicker_getProperty_caller == nil) {
        our_DocumentPicker_getProperty_caller = [[DocumentPicker_getProperty_caller alloc] init];
    }
    return our_DocumentPicker_getProperty_caller;
}

-(void) command_getProperty:(DocumentPicker_getProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperty:(NSString*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperty:(DocumentPicker_getProperty_caller_params*)caller_params {
    [[DocumentPicker_getProperty_caller getSharedInstance] command_getProperty:caller_params];
}

+(void) getProperty_in_thread:(DocumentPicker_getProperty_caller_params*)caller_params {
    [[DocumentPicker_getProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperty:) withObject:caller_params];
}

+(void) getProperty_in_UI_thread:(DocumentPicker_getProperty_caller_params*)caller_params {
    [[DocumentPicker_getProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_getProperty_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::getProperty"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::getProperty parameter %d is nil!", i);
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
        
        [DocumentPicker_getProperty_caller getProperty_in_thread:[DocumentPicker_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_getProperty_caller getProperty:[DocumentPicker_getProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_getProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_getProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_getProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_getProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_getProperties_caller_params* par = [[[DocumentPicker_getProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_getProperties_caller : NSObject {

}
+(DocumentPicker_getProperties_caller*) getSharedInstance;
+(void) getProperties:(DocumentPicker_getProperties_caller_params*)caller_params;
+(void) getProperties_in_thread:(DocumentPicker_getProperties_caller_params*)caller_params;
+(void) getProperties_in_UI_thread:(DocumentPicker_getProperties_caller_params*)caller_params;

@end

static DocumentPicker_getProperties_caller* our_DocumentPicker_getProperties_caller = nil;

@implementation DocumentPicker_getProperties_caller

+(DocumentPicker_getProperties_caller*) getSharedInstance {
    if (our_DocumentPicker_getProperties_caller == nil) {
        our_DocumentPicker_getProperties_caller = [[DocumentPicker_getProperties_caller alloc] init];
    }
    return our_DocumentPicker_getProperties_caller;
}

-(void) command_getProperties:(DocumentPicker_getProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getProperties:(NSArray*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getProperties:(DocumentPicker_getProperties_caller_params*)caller_params {
    [[DocumentPicker_getProperties_caller getSharedInstance] command_getProperties:caller_params];
}

+(void) getProperties_in_thread:(DocumentPicker_getProperties_caller_params*)caller_params {
    [[DocumentPicker_getProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getProperties:) withObject:caller_params];
}

+(void) getProperties_in_UI_thread:(DocumentPicker_getProperties_caller_params*)caller_params {
    [[DocumentPicker_getProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_getProperties_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::getProperties"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::getProperties parameter %d is nil!", i);
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
        
        [DocumentPicker_getProperties_caller getProperties_in_thread:[DocumentPicker_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_getProperties_caller getProperties:[DocumentPicker_getProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_getProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_getAllProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_getAllProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_getAllProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_getAllProperties_caller_params* par = [[[DocumentPicker_getAllProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_getAllProperties_caller : NSObject {

}
+(DocumentPicker_getAllProperties_caller*) getSharedInstance;
+(void) getAllProperties:(DocumentPicker_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_thread:(DocumentPicker_getAllProperties_caller_params*)caller_params;
+(void) getAllProperties_in_UI_thread:(DocumentPicker_getAllProperties_caller_params*)caller_params;

@end

static DocumentPicker_getAllProperties_caller* our_DocumentPicker_getAllProperties_caller = nil;

@implementation DocumentPicker_getAllProperties_caller

+(DocumentPicker_getAllProperties_caller*) getSharedInstance {
    if (our_DocumentPicker_getAllProperties_caller == nil) {
        our_DocumentPicker_getAllProperties_caller = [[DocumentPicker_getAllProperties_caller alloc] init];
    }
    return our_DocumentPicker_getAllProperties_caller;
}

-(void) command_getAllProperties:(DocumentPicker_getAllProperties_caller_params*)caller_params {

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem getAllProperties:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) getAllProperties:(DocumentPicker_getAllProperties_caller_params*)caller_params {
    [[DocumentPicker_getAllProperties_caller getSharedInstance] command_getAllProperties:caller_params];
}

+(void) getAllProperties_in_thread:(DocumentPicker_getAllProperties_caller_params*)caller_params {
    [[DocumentPicker_getAllProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_getAllProperties:) withObject:caller_params];
}

+(void) getAllProperties_in_UI_thread:(DocumentPicker_getAllProperties_caller_params*)caller_params {
    [[DocumentPicker_getAllProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_getAllProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_getAllProperties_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[0+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::getAllProperties"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::getAllProperties parameter %d is nil!", i);
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
        
        [DocumentPicker_getAllProperties_caller getAllProperties_in_thread:[DocumentPicker_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_getAllProperties_caller getAllProperties:[DocumentPicker_getAllProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_getAllProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_setProperty_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_setProperty_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_setProperty_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_setProperty_caller_params* par = [[[DocumentPicker_setProperty_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_setProperty_caller : NSObject {

}
+(DocumentPicker_setProperty_caller*) getSharedInstance;
+(void) setProperty:(DocumentPicker_setProperty_caller_params*)caller_params;
+(void) setProperty_in_thread:(DocumentPicker_setProperty_caller_params*)caller_params;
+(void) setProperty_in_UI_thread:(DocumentPicker_setProperty_caller_params*)caller_params;

@end

static DocumentPicker_setProperty_caller* our_DocumentPicker_setProperty_caller = nil;

@implementation DocumentPicker_setProperty_caller

+(DocumentPicker_setProperty_caller*) getSharedInstance {
    if (our_DocumentPicker_setProperty_caller == nil) {
        our_DocumentPicker_setProperty_caller = [[DocumentPicker_setProperty_caller alloc] init];
    }
    return our_DocumentPicker_setProperty_caller;
}

-(void) command_setProperty:(DocumentPicker_setProperty_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperty:(NSString*)[params objectAtIndex:0] propertyValue:(NSString*)[params objectAtIndex:1] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperty:(DocumentPicker_setProperty_caller_params*)caller_params {
    [[DocumentPicker_setProperty_caller getSharedInstance] command_setProperty:caller_params];
}

+(void) setProperty_in_thread:(DocumentPicker_setProperty_caller_params*)caller_params {
    [[DocumentPicker_setProperty_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperty:) withObject:caller_params];
}

+(void) setProperty_in_UI_thread:(DocumentPicker_setProperty_caller_params*)caller_params {
    [[DocumentPicker_setProperty_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperty:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_setProperty_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[2+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::setProperty"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::setProperty parameter %d is nil!", i);
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
        
        [DocumentPicker_setProperty_caller setProperty_in_thread:[DocumentPicker_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_setProperty_caller setProperty:[DocumentPicker_setProperty_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_setProperty_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







@interface DocumentPicker_setProperties_caller_params : NSObject

@property (nonatomic, copy) NSArray* params;
@property (assign) id<IDocumentPicker> item;
@property (assign) CMethodResult* methodResult;

-(void)dealloc;

+(DocumentPicker_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation DocumentPicker_setProperties_caller_params

@synthesize params,item,methodResult;

-(void)dealloc {
    [params release];
    [super dealloc];
}

+(DocumentPicker_setProperties_caller_params*) makeParams:(NSArray*)_params _item:(id<IDocumentPicker>)_item _methodResult:(CMethodResult*)_methodResult {
    DocumentPicker_setProperties_caller_params* par = [[[DocumentPicker_setProperties_caller_params alloc] init] autorelease];
    par.params = _params;
    par.item = _item;
    par.methodResult = [_methodResult retain];
    return [par retain];
}

@end


@interface DocumentPicker_setProperties_caller : NSObject {

}
+(DocumentPicker_setProperties_caller*) getSharedInstance;
+(void) setProperties:(DocumentPicker_setProperties_caller_params*)caller_params;
+(void) setProperties_in_thread:(DocumentPicker_setProperties_caller_params*)caller_params;
+(void) setProperties_in_UI_thread:(DocumentPicker_setProperties_caller_params*)caller_params;

@end

static DocumentPicker_setProperties_caller* our_DocumentPicker_setProperties_caller = nil;

@implementation DocumentPicker_setProperties_caller

+(DocumentPicker_setProperties_caller*) getSharedInstance {
    if (our_DocumentPicker_setProperties_caller == nil) {
        our_DocumentPicker_setProperties_caller = [[DocumentPicker_setProperties_caller alloc] init];
    }
    return our_DocumentPicker_setProperties_caller;
}

-(void) command_setProperties:(DocumentPicker_setProperties_caller_params*)caller_params {

    NSArray* params = caller_params.params;

    id<IDocumentPicker> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    
    [objItem setProperties:(NSDictionary*)[params objectAtIndex:0] methodResult:methodResult ];
    [caller_params.methodResult release];
    [caller_params release];
}


+(void) setProperties:(DocumentPicker_setProperties_caller_params*)caller_params {
    [[DocumentPicker_setProperties_caller getSharedInstance] command_setProperties:caller_params];
}

+(void) setProperties_in_thread:(DocumentPicker_setProperties_caller_params*)caller_params {
    [[DocumentPicker_setProperties_caller getSharedInstance] performSelectorInBackground:@selector(command_setProperties:) withObject:caller_params];
}

+(void) setProperties_in_UI_thread:(DocumentPicker_setProperties_caller_params*)caller_params {
    [[DocumentPicker_setProperties_caller getSharedInstance] performSelectorOnMainThread:@selector(command_setProperties:) withObject:caller_params waitUntilDone:NO];
}


@end


rho::String js_DocumentPicker_setProperties_Obj(rho::json::CJSONArray& argv, id<IDocumentPicker>objItem, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[1+1];
    BOOL method_return_result = YES;
    BOOL method_receive_callback = NO;
    int argc = argv.getSize();


    [methodResult setMethodSignature:@"DocumentPicker::setProperties"];

    
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
                params[i] = DocumentPicker_makeInstanceByJSObject(argv.getItem(i).getString());
            }
            else {
                rho::json::CJSONEntry entry = argv.getItem(i);
                params[i] = [[CJSConverter convertFromJS:&entry rho_api_param:&(rho_api_params[i])] retain];
            }
            // TODO: Handle CMethodResultError
            if (params[i] == nil) {
                //NSLog(@"DocumentPicker::setProperties parameter %d is nil!", i);
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
        
        [DocumentPicker_setProperties_caller setProperties_in_thread:[DocumentPicker_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        

        // FIXME: callback should not be retained, it must be saved outside of this call
        [methodResult retain];
    }
    else {
        // we do not have callback
        
        [DocumentPicker_setProperties_caller setProperties:[DocumentPicker_setProperties_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        
    }
    rho::String resValue = rho::String("\"result\":null");
    if ((!method_receive_callback) && (method_return_result)) {
        resValue = [[methodResult toJSON] UTF8String];
    }
    [methodResult release];
    return resValue;
}


rho::String js_DocumentPicker_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {

    id<IDocumentPicker> item = DocumentPicker_makeInstanceByJSObject(strObjID);
    return js_DocumentPicker_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);

}

rho::String js_s_DocumentPicker_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam) {
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    id<IDocumentPicker> item = [factory getDocumentPickerByID:defID];
    return js_DocumentPicker_setProperties_Obj(argv, item, strCallbackID, strJsVmID, strCallbackParam);
}







rho::String js_s_DocumentPicker_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:defID level:0] UTF8String];

    return res;
}

rho::String js_s_DocumentPicker_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    NSString* defID = [singleton getDefaultID];

    rho::String res =  [[CJSConverter convertToJS:[CRhoAPIClassInstance rubyClassByName:@"Rho.DocumentPicker" instanceID:defID] level:0] UTF8String];

    return res;
}

rho::String js_s_DocumentPicker_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    id<IDocumentPickerFactory> factory = [DocumentPickerFactorySingleton getDocumentPickerFactoryInstance];
    id<IDocumentPickerSingleton> singleton = [factory getDocumentPickerSingleton];

    rho::json::CJSONEntry el = argv[0];

    if (el.isString()) {
        NSString* defID = [NSString stringWithUTF8String:(el.getString())];

        [singleton setDefaultID:defID];

        return [[CJSConverter convertToJS:nil level:0] UTF8String];
    }

    return "\"result\":null,\"error\":\"Method parameter should be defined as string!\"";
}

