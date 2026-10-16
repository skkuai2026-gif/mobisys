#include "common/RhodesApp.h"
#include "api_generator/uwp/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/PdfgenBase.h"
#include "PdfgenRuntime.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"


namespace rho {

class CPdfgenImpl: public CPdfgenBase
{
private:
    rhoruntime::IPdfgenImpl^ _runtime;
public:
    CPdfgenImpl(const rho::String& strID, rhoruntime::IPdfgenImpl^ runtime): CPdfgenBase(), _runtime(runtime)
    {
        _runtime->setNativeImpl(rho::common::convertStringToWP8(strID), (int64)this);
    }

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);
    virtual void setSimpleStringProperty(const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);
    virtual void generateAndroidPDF(const rho::String& inputHTMLFileName, const rho::String& orientation, const rho::String& isSinglePDFRequired, const rho::String& password, rho::apiGenerator::CMethodResult& oResult);
    virtual void generateAndroidPDFCharts(const rho::String& chartJSON, const rho::String& chartOutputFileName, const rho::String& chartType, rho::apiGenerator::CMethodResult& oResult);
    virtual void generateIOSPDF(const rho::String& htmlContent, const rho::String& targetFilePath, rho::apiGenerator::CMethodResult& oResult);
    virtual void mergeIOSPDF(const rho::String& listOfPaths, const rho::String& targetFilePath, const rho::String& masterPassword, const rho::String& password, rho::apiGenerator::CMethodResult& oResult);
};

}
