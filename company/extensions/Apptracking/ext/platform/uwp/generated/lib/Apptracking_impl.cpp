#include "Apptracking_impl.h"
#include "ApptrackingFactory.h"
#include "api_generator/uwp/MethodResultImpl.h"

using namespace rho::apiGenerator;
using namespace rhoruntime;

namespace rho {


void CApptrackingImpl::getSimpleStringProperty(CMethodResult& oResult)
{
    try {
        _runtime->getSimpleStringProperty(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CApptrackingImpl::setSimpleStringProperty(const rho::String& simpleStringProperty, CMethodResult& oResult)
{
        Platform::String^ _simpleStringProperty = rho::common::convertStringToWP8(simpleStringProperty);
    try {
        _runtime->setSimpleStringProperty(_simpleStringProperty, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CApptrackingImpl::requestAppTrackingPermission(CMethodResult& oResult)
{
    try {
        _runtime->requestAppTrackingPermission(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}


class CApptrackingSingleton: public CApptrackingSingletonBase
{
private:
    IApptrackingSingletonImpl^ _runtime;
public:
    CApptrackingSingleton(IApptrackingSingletonImpl^ runtime): CApptrackingSingletonBase(), _runtime(runtime) {}
    ~CApptrackingSingleton(){}

    virtual void enumerate(CMethodResult& oResult)
    {
        try {
            _runtime->enumerate(ref new CMethodResultImpl((int64)&oResult));
        } catch (Platform::Exception^ e) {
            LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
        }
    }


    virtual rho::String getDefaultID(){return "1";} // TODO: implement getDefaultID
    virtual rho::String getInitialDefaultID(){return "1";} // TODO: implement getInitialDefaultID
    virtual void setDefaultID(const rho::String& strID){} // TODO: implement setDefaultID
    
    //virtual void addCommandToQueue(rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor){} // TODO: implement addCommandToQueue
    //virtual void callCommandInThread(rho::common::IRhoRunnable* pFunctor){} // TODO: implement callCommandInThread
};

IApptrackingFactoryImpl^ CApptrackingFactory::_impl;

IApptracking* CApptrackingFactory::createModuleByID(const rho::String& strID)
{
    return new CApptrackingImpl(strID, _impl->getImpl(rho::common::convertStringToWP8(strID)));
}

IApptrackingSingleton* CApptrackingFactory::createModuleSingleton()
{
    return new CApptrackingSingleton(_impl->getSingletonImpl());
}

}

extern "C" void Init_Apptracking_extension()
{
    rho::CApptrackingFactory::setInstance( new rho::CApptrackingFactory() );
    rho::Init_Apptracking_API();

    RHODESAPP().getExtManager().requireRubyFile("RhoApptrackingApi");
}
