#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "BGService"




rho::String js_BGService_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_BGService_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_startBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_startBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_stopBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_stopBackgroundService(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_checkBackgroundServiceStatus(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_checkBackgroundServiceStatus(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_BGService_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_BGService_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_BGService_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class BGServiceDispatcher : public ApiHandler<Func_JS>
  {
  public:
    BGServiceDispatcher() : ApiHandler("Rho:BGService") {}
    virtual ~BGServiceDispatcher() {}
    virtual void initialize();
  };
  
  void BGServiceDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:BGService API...");


    defineInstanceMethod("simpleStringProperty", js_BGService_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_BGService_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_BGService_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_BGService_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_BGService_enumerate);


    defineInstanceMethod("startBackgroundService", js_BGService_startBackgroundService);
    //  should define static method !     defineStaticMethod("def_startBackgroundService", js_s_BGService_def_startBackgroundService);;


    defineInstanceMethod("stopBackgroundService", js_BGService_stopBackgroundService);
    //  should define static method !     defineStaticMethod("def_stopBackgroundService", js_s_BGService_def_stopBackgroundService);;


    defineInstanceMethod("checkBackgroundServiceStatus", js_BGService_checkBackgroundServiceStatus);
    //  should define static method !     defineStaticMethod("def_checkBackgroundServiceStatus", js_s_BGService_def_checkBackgroundServiceStatus);;


    defineInstanceMethod("getProperty", js_BGService_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_BGService_def_getProperty);;


    defineInstanceMethod("getProperties", js_BGService_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_BGService_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_BGService_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_BGService_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_BGService_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_BGService_def_setProperty);;


    defineInstanceMethod("setProperties", js_BGService_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_BGService_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_BGService_getDefaultID);
    defineStaticMethod("getDefault", js_s_BGService_getDefault);
    defineStaticMethod("setDefaultID", js_s_BGService_setDefaultID);

    RAWTRACE("Rho:BGService API - done");
  }
}

extern "C" void Init_JSAPI_BGService(void)
{
  rho::apiGenerator::defineJSApiModule(new BGServiceDispatcher);
}
