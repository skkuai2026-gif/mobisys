#include "api_generator/js_helpers.h"
#include "api_generator/Api.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Pdfgen"




rho::String js_Pdfgen_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_s_Pdfgen_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_generateAndroidPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_generateAndroidPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_generateAndroidPDFCharts(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_generateAndroidPDFCharts(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_generateIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_generateIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_mergeIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_mergeIOSPDF(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);

rho::String js_Pdfgen_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_def_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



rho::String js_s_Pdfgen_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);
rho::String js_s_Pdfgen_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam);



namespace {
  using namespace rho::apiGenerator;
  class PdfgenDispatcher : public ApiHandler<Func_JS>
  {
  public:
    PdfgenDispatcher() : ApiHandler("Rho:Pdfgen") {}
    virtual ~PdfgenDispatcher() {}
    virtual void initialize();
  };
  
  void PdfgenDispatcher::initialize()
  {
    ApiHandler<Func_JS>::initialize();
    
    RAWTRACE("Initializing Rho:Pdfgen API...");


    defineInstanceMethod("simpleStringProperty", js_Pdfgen_getSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty", js_s_Pdfgen_def_getSimpleStringProperty);;


    defineInstanceMethod("simpleStringProperty=", js_Pdfgen_setSimpleStringProperty);
    //  should define static method !     defineStaticMethod("def_simpleStringProperty=", js_s_Pdfgen_def_setSimpleStringProperty);;


    defineStaticMethod("enumerate", js_s_Pdfgen_enumerate);


    defineInstanceMethod("generateAndroidPDF", js_Pdfgen_generateAndroidPDF);
    //  should define static method !     defineStaticMethod("def_generateAndroidPDF", js_s_Pdfgen_def_generateAndroidPDF);;


    defineInstanceMethod("generateAndroidPDFCharts", js_Pdfgen_generateAndroidPDFCharts);
    //  should define static method !     defineStaticMethod("def_generateAndroidPDFCharts", js_s_Pdfgen_def_generateAndroidPDFCharts);;


    defineInstanceMethod("generateIOSPDF", js_Pdfgen_generateIOSPDF);
    //  should define static method !     defineStaticMethod("def_generateIOSPDF", js_s_Pdfgen_def_generateIOSPDF);;


    defineInstanceMethod("mergeIOSPDF", js_Pdfgen_mergeIOSPDF);
    //  should define static method !     defineStaticMethod("def_mergeIOSPDF", js_s_Pdfgen_def_mergeIOSPDF);;


    defineInstanceMethod("getProperty", js_Pdfgen_getProperty);
    //  should define static method !     defineStaticMethod("def_getProperty", js_s_Pdfgen_def_getProperty);;


    defineInstanceMethod("getProperties", js_Pdfgen_getProperties);
    //  should define static method !     defineStaticMethod("def_getProperties", js_s_Pdfgen_def_getProperties);;


    defineInstanceMethod("getAllProperties", js_Pdfgen_getAllProperties);
    //  should define static method !     defineStaticMethod("def_getAllProperties", js_s_Pdfgen_def_getAllProperties);;


    defineInstanceMethod("setProperty", js_Pdfgen_setProperty);
    //  should define static method !     defineStaticMethod("def_setProperty", js_s_Pdfgen_def_setProperty);;


    defineInstanceMethod("setProperties", js_Pdfgen_setProperties);
    //  should define static method !     defineStaticMethod("def_setProperties", js_s_Pdfgen_def_setProperties);;


    defineStaticMethod("getDefaultID", js_s_Pdfgen_getDefaultID);
    defineStaticMethod("getDefault", js_s_Pdfgen_getDefault);
    defineStaticMethod("setDefaultID", js_s_Pdfgen_setDefaultID);

    RAWTRACE("Rho:Pdfgen API - done");
  }
}

extern "C" void Init_JSAPI_Pdfgen(void)
{
  rho::apiGenerator::defineJSApiModule(new PdfgenDispatcher);
}
