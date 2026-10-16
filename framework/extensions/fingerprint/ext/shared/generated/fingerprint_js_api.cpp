#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Fingerprint"




rho::String js_Fingerprint_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_Fingerprint_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_enableFingerprintScan(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_enableFingerprintScan(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Fingerprint_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_Fingerprint_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Fingerprint_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class FingerprintDispatcher : public ApiHandler<Func_JS>
  {
  public:
    FingerprintDispatcher() : ApiHandler("Rho:Fingerprint") {}
    virtual ~FingerprintDispatcher() {}
    virtual void initialize();
  };
  
  void FingerprintDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:Fingerprint API...");


    defineInstanceMethod("simpleStringProperty", js_Fingerprint_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_Fingerprint_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_Fingerprint_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_Fingerprint_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_Fingerprint_enumerate);


    defineInstanceMethod("enableFingerprintScan", js_Fingerprint_enableFingerprintScan);
    //  should define static method !     defineStaticMethod("def_enableFingerprintScan", js_s_Fingerprint_def_enableFingerprintScan);;


    defineInstanceMethod("getProperty", js_Fingerprint_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_Fingerprint_def_getProperty);;


    defineInstanceMethod("getProperties", js_Fingerprint_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_Fingerprint_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_Fingerprint_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_Fingerprint_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_Fingerprint_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_Fingerprint_def_setProperty);;


    defineInstanceMethod("setProperties", js_Fingerprint_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_Fingerprint_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_Fingerprint_getDefaultID);
    defineStaticMethod("getDefault", js_s_Fingerprint_getDefault);
    defineStaticMethod("setDefaultID", js_s_Fingerprint_setDefaultID);

    RAWTRACE("Rho:Fingerprint API - done");
  }
}

extern "C" void Init_JSAPI_Fingerprint(void)
{
  rho::apiGenerator::defineJSApiModule(new FingerprintDispatcher);
}
