#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "DocumentPicker"




rho::String js_DocumentPicker_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_DocumentPicker_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_pickDocument(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_pickDocument(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_DocumentPicker_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_DocumentPicker_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_DocumentPicker_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class DocumentPickerDispatcher : public ApiHandler<Func_JS>
  {
  public:
    DocumentPickerDispatcher() : ApiHandler("Rho:DocumentPicker") {}
    virtual ~DocumentPickerDispatcher() {}
    virtual void initialize();
  };
  
  void DocumentPickerDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:DocumentPicker API...");


    defineInstanceMethod("simpleStringProperty", js_DocumentPicker_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_DocumentPicker_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_DocumentPicker_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_DocumentPicker_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_DocumentPicker_enumerate);


    defineInstanceMethod("pickDocument", js_DocumentPicker_pickDocument);
    //  should define static method !     defineStaticMethod("def_pickDocument", js_s_DocumentPicker_def_pickDocument);;


    defineInstanceMethod("getProperty", js_DocumentPicker_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_DocumentPicker_def_getProperty);;


    defineInstanceMethod("getProperties", js_DocumentPicker_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_DocumentPicker_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_DocumentPicker_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_DocumentPicker_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_DocumentPicker_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_DocumentPicker_def_setProperty);;


    defineInstanceMethod("setProperties", js_DocumentPicker_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_DocumentPicker_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_DocumentPicker_getDefaultID);
    defineStaticMethod("getDefault", js_s_DocumentPicker_getDefault);
    defineStaticMethod("setDefaultID", js_s_DocumentPicker_setDefaultID);

    RAWTRACE("Rho:DocumentPicker API - done");
  }
}

extern "C" void Init_JSAPI_DocumentPicker(void)
{
  rho::apiGenerator::defineJSApiModule(new DocumentPickerDispatcher);
}
