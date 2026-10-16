#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "HtmlToGraph"




rho::String js_HtmlToGraph_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_HtmlToGraph_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_getPlatformName(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getPlatformName(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_getGraphIOS(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getGraphIOS(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_getGraphAndroid(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getGraphAndroid(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_calcSumm(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_calcSumm(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_joinStrings(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_joinStrings(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_HtmlToGraph_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_HtmlToGraph_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_HtmlToGraph_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class HtmlToGraphDispatcher : public ApiHandler<Func_JS>
  {
  public:
    HtmlToGraphDispatcher() : ApiHandler("Rho:HtmlToGraph") {}
    virtual ~HtmlToGraphDispatcher() {}
    virtual void initialize();
  };
  
  void HtmlToGraphDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:HtmlToGraph API...");


    defineInstanceMethod("simpleStringProperty", js_HtmlToGraph_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_HtmlToGraph_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_HtmlToGraph_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_HtmlToGraph_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_HtmlToGraph_enumerate);


    defineInstanceMethod("getPlatformName", js_HtmlToGraph_getPlatformName);
    //  should define static method !     defineStaticMethod("def_getPlatformName", js_s_HtmlToGraph_def_getPlatformName);;


    defineInstanceMethod("getGraphIOS", js_HtmlToGraph_getGraphIOS);
    //  should define static method !     defineStaticMethod("def_getGraphIOS", js_s_HtmlToGraph_def_getGraphIOS);;


    defineInstanceMethod("getGraphAndroid", js_HtmlToGraph_getGraphAndroid);
    //  should define static method !     defineStaticMethod("def_getGraphAndroid", js_s_HtmlToGraph_def_getGraphAndroid);;


    defineInstanceMethod("calcSumm", js_HtmlToGraph_calcSumm);
    //  should define static method !     defineStaticMethod("def_calcSumm", js_s_HtmlToGraph_def_calcSumm);;


    defineInstanceMethod("joinStrings", js_HtmlToGraph_joinStrings);
    //  should define static method !     defineStaticMethod("def_joinStrings", js_s_HtmlToGraph_def_joinStrings);;


    defineInstanceMethod("getProperty", js_HtmlToGraph_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_HtmlToGraph_def_getProperty);;


    defineInstanceMethod("getProperties", js_HtmlToGraph_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_HtmlToGraph_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_HtmlToGraph_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_HtmlToGraph_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_HtmlToGraph_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_HtmlToGraph_def_setProperty);;


    defineInstanceMethod("setProperties", js_HtmlToGraph_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_HtmlToGraph_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_HtmlToGraph_getDefaultID);
    defineStaticMethod("getDefault", js_s_HtmlToGraph_getDefault);
    defineStaticMethod("setDefaultID", js_s_HtmlToGraph_setDefaultID);

    RAWTRACE("Rho:HtmlToGraph API - done");
  }
}

extern "C" void Init_JSAPI_HtmlToGraph(void)
{
  rho::apiGenerator::defineJSApiModule(new HtmlToGraphDispatcher);
}
