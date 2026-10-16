#include "common/RhodesApp.h"
#include "api_generator/uwp/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/ApptrackingBase.h"
#include "ApptrackingRuntime.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"


namespace rho {

class CApptrackingImpl: public CApptrackingBase
{
private:
    rhoruntime::IApptrackingImpl^ _runtime;
public:
    CApptrackingImpl(const rho::String& strID, rhoruntime::IApptrackingImpl^ runtime): CApptrackingBase(), _runtime(runtime)
    {
        _runtime->setNativeImpl(rho::common::convertStringToWP8(strID), (int64)this);
    }

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);
    virtual void setSimpleStringProperty(const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);
    virtual void requestAppTrackingPermission(rho::apiGenerator::CMethodResult& oResult);
};

}
