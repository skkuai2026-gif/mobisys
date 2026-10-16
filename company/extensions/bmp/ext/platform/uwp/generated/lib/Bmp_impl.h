#include "common/RhodesApp.h"
#include "api_generator/uwp/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/BmpBase.h"
#include "BmpRuntime.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"


namespace rho {

class CBmpImpl: public CBmpBase
{
private:
    rhoruntime::IBmpImpl^ _runtime;
public:
    CBmpImpl(const rho::String& strID, rhoruntime::IBmpImpl^ runtime): CBmpBase(), _runtime(runtime)
    {
        _runtime->setNativeImpl(rho::common::convertStringToWP8(strID), (int64)this);
    }

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);
    virtual void setSimpleStringProperty(const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);
    virtual void sensorDataFetch(rho::apiGenerator::CMethodResult& oResult);
};

}
