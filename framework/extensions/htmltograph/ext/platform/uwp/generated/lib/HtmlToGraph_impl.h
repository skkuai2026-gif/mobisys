#include "common/RhodesApp.h"
#include "api_generator/uwp/MethodResultImpl.h"
#include "../../../../shared/generated/cpp/HtmlToGraphBase.h"
#include "HtmlToGraphRuntime.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"


namespace rho {

class CHtmlToGraphImpl: public CHtmlToGraphBase
{
private:
    rhoruntime::IHtmlToGraphImpl^ _runtime;
public:
    CHtmlToGraphImpl(const rho::String& strID, rhoruntime::IHtmlToGraphImpl^ runtime): CHtmlToGraphBase(), _runtime(runtime)
    {
        _runtime->setNativeImpl(rho::common::convertStringToWP8(strID), (int64)this);
    }

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);
    virtual void setSimpleStringProperty(const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);
    virtual void getPlatformName(rho::apiGenerator::CMethodResult& oResult);
    virtual void getGraphIOS(const rho::String& htmlString, rho::apiGenerator::CMethodResult& oResult);
    virtual void getGraphAndroid(const rho::String& htmlString, rho::apiGenerator::CMethodResult& oResult);
    virtual void calcSumm(int a, int b, rho::apiGenerator::CMethodResult& oResult);
    virtual void joinStrings(const rho::String& a, const rho::String& b, rho::apiGenerator::CMethodResult& oResult);
};

}
