#include "common/RhodesApp.h"
#include "api_generator/wp8/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/PdfgenBase.h"
#include "PdfgenRuntime.h"
#include "../../wp8/rhoruntime/common/RhoConvertWP8.h"


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
    virtual void generatePDF(const rho::String& htmlContent, const rho::String& targetFilePath, rho::apiGenerator::CMethodResult& oResult);
    virtual void mergePDF(const rho::String& listOfPaths, const rho::String& targetFilePath, rho::apiGenerator::CMethodResult& oResult);
};

}
