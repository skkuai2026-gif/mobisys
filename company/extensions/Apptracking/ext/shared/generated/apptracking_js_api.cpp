#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Apptracking"




rho::String js_Apptracking_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_Apptracking_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_requestAppTrackingPermission(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_requestAppTrackingPermission(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Apptracking_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_Apptracking_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Apptracking_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class ApptrackingDispatcher : public ApiHandler<Func_JS>
  {
  public:
    ApptrackingDispatcher() : ApiHandler("Rho:Apptracking") {}
    virtual ~ApptrackingDispatcher() {}
    virtual void initialize();
  };
  
  void ApptrackingDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:Apptracking API...");


    defineInstanceMethod("simpleStringProperty", js_Apptracking_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_Apptracking_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_Apptracking_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_Apptracking_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_Apptracking_enumerate);


    defineInstanceMethod("requestAppTrackingPermission", js_Apptracking_requestAppTrackingPermission);
    //  should define static method !     defineStaticMethod("def_requestAppTrackingPermission", js_s_Apptracking_def_requestAppTrackingPermission);;


    defineInstanceMethod("getProperty", js_Apptracking_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_Apptracking_def_getProperty);;


    defineInstanceMethod("getProperties", js_Apptracking_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_Apptracking_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_Apptracking_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_Apptracking_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_Apptracking_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_Apptracking_def_setProperty);;


    defineInstanceMethod("setProperties", js_Apptracking_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_Apptracking_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_Apptracking_getDefaultID);
    defineStaticMethod("getDefault", js_s_Apptracking_getDefault);
    defineStaticMethod("setDefaultID", js_s_Apptracking_setDefaultID);

    RAWTRACE("Rho:Apptracking API - done");
  }
}

extern "C" void Init_JSAPI_Apptracking(void)
{
  rho::apiGenerator::defineJSApiModule(new ApptrackingDispatcher);
}
