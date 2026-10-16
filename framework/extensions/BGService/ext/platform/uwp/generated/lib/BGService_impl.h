#include "common/RhodesApp.h"
#include "api_generator/uwp/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/BGServiceBase.h"
#include "BGServiceRuntime.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"


namespace rho {

class CBGServiceImpl: public CBGServiceBase
{
private:
    rhoruntime::IBGServiceImpl^ _runtime;
public:
    CBGServiceImpl(const rho::String& strID, rhoruntime::IBGServiceImpl^ runtime): CBGServiceBase(), _runtime(runtime)
    {
        _runtime->setNativeImpl(rho::common::convertStringToWP8(strID), (int64)this);
    }

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);
    virtual void setSimpleStringProperty(const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);
    virtual void startBackgroundService(const rho::String& bgServiceRubyFunc, rho::apiGenerator::CMethodResult& oResult);
    virtual void stopBackgroundService(rho::apiGenerator::CMethodResult& oResult);
    virtual void checkBackgroundServiceStatus(rho::apiGenerator::CMethodResult& oResult);
};

}
