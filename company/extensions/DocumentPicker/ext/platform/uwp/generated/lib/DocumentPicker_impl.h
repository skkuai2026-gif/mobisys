#include "common/RhodesApp.h"
#include "api_generator/uwp/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/DocumentPickerBase.h"
#include "DocumentPickerRuntime.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"


namespace rho {

class CDocumentPickerImpl: public CDocumentPickerBase
{
private:
    rhoruntime::IDocumentPickerImpl^ _runtime;
public:
    CDocumentPickerImpl(const rho::String& strID, rhoruntime::IDocumentPickerImpl^ runtime): CDocumentPickerBase(), _runtime(runtime)
    {
        _runtime->setNativeImpl(rho::common::convertStringToWP8(strID), (int64)this);
    }

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);
    virtual void setSimpleStringProperty(const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);
    virtual void pickDocument(const rho::String& supportedExtensionList, rho::apiGenerator::CMethodResult& oResult);
};

}
