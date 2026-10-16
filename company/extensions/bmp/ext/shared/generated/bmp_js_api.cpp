#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Bmp"




rho::String js_Bmp_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_Bmp_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_sensorDataFetch(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_sensorDataFetch(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Bmp_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_Bmp_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Bmp_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class BmpDispatcher : public ApiHandler<Func_JS>
  {
  public:
    BmpDispatcher() : ApiHandler("Rho:Bmp") {}
    virtual ~BmpDispatcher() {}
    virtual void initialize();
  };
  
  void BmpDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:Bmp API...");


    defineInstanceMethod("simpleStringProperty", js_Bmp_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_Bmp_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_Bmp_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_Bmp_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_Bmp_enumerate);


    defineInstanceMethod("sensorDataFetch", js_Bmp_sensorDataFetch);
    //  should define static method !     defineStaticMethod("def_sensorDataFetch", js_s_Bmp_def_sensorDataFetch);;


    defineInstanceMethod("getProperty", js_Bmp_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_Bmp_def_getProperty);;


    defineInstanceMethod("getProperties", js_Bmp_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_Bmp_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_Bmp_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_Bmp_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_Bmp_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_Bmp_def_setProperty);;


    defineInstanceMethod("setProperties", js_Bmp_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_Bmp_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_Bmp_getDefaultID);
    defineStaticMethod("getDefault", js_s_Bmp_getDefault);
    defineStaticMethod("setDefaultID", js_s_Bmp_setDefaultID);

    RAWTRACE("Rho:Bmp API - done");
  }
}

extern "C" void Init_JSAPI_Bmp(void)
{
  rho::apiGenerator::defineJSApiModule(new BmpDispatcher);
}
