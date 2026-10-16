#include "BGService_impl.h"
#include "BGServiceFactory.h"
#include "api_generator/uwp/MethodResultImpl.h"

using namespace rho::apiGenerator;
using namespace rhoruntime;

namespace rho {


void CBGServiceImpl::getSimpleStringProperty(CMethodResult& oResult)
{
    try {
        _runtime->getSimpleStringProperty(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CBGServiceImpl::setSimpleStringProperty(const rho::String& simpleStringProperty, CMethodResult& oResult)
{
        Platform::String^ _simpleStringProperty = rho::common::convertStringToWP8(simpleStringProperty);
    try {
        _runtime->setSimpleStringProperty(_simpleStringProperty, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CBGServiceImpl::startBackgroundService(const rho::String& bgServiceRubyFunc, CMethodResult& oResult)
{
        Platform::String^ _bgServiceRubyFunc = rho::common::convertStringToWP8(bgServiceRubyFunc);
    try {
        _runtime->startBackgroundService(_bgServiceRubyFunc, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CBGServiceImpl::stopBackgroundService(CMethodResult& oResult)
{
    try {
        _runtime->stopBackgroundService(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CBGServiceImpl::checkBackgroundServiceStatus(CMethodResult& oResult)
{
    try {
        _runtime->checkBackgroundServiceStatus(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}


class CBGServiceSingleton: public CBGServiceSingletonBase
{
private:
    IBGServiceSingletonImpl^ _runtime;
public:
    CBGServiceSingleton(IBGServiceSingletonImpl^ runtime): CBGServiceSingletonBase(), _runtime(runtime) {}
    ~CBGServiceSingleton(){}

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

IBGServiceFactoryImpl^ CBGServiceFactory::_impl;

IBGService* CBGServiceFactory::createModuleByID(const rho::String& strID)
{
    return new CBGServiceImpl(strID, _impl->getImpl(rho::common::convertStringToWP8(strID)));
}

IBGServiceSingleton* CBGServiceFactory::createModuleSingleton()
{
    return new CBGServiceSingleton(_impl->getSingletonImpl());
}

}

extern "C" void Init_BGService_extension()
{
    rho::CBGServiceFactory::setInstance( new rho::CBGServiceFactory() );
    rho::Init_BGService_API();

    RHODESAPP().getExtManager().requireRubyFile("RhoBGServiceApi");
}
