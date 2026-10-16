#include "Bmp_impl.h"
#include "BmpFactory.h"
#include "api_generator/uwp/MethodResultImpl.h"

using namespace rho::apiGenerator;
using namespace rhoruntime;

namespace rho {


void CBmpImpl::getSimpleStringProperty(CMethodResult& oResult)
{
    try {
        _runtime->getSimpleStringProperty(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CBmpImpl::setSimpleStringProperty(const rho::String& simpleStringProperty, CMethodResult& oResult)
{
        Platform::String^ _simpleStringProperty = rho::common::convertStringToWP8(simpleStringProperty);
    try {
        _runtime->setSimpleStringProperty(_simpleStringProperty, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CBmpImpl::sensorDataFetch(CMethodResult& oResult)
{
    try {
        _runtime->sensorDataFetch(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}


class CBmpSingleton: public CBmpSingletonBase
{
private:
    IBmpSingletonImpl^ _runtime;
public:
    CBmpSingleton(IBmpSingletonImpl^ runtime): CBmpSingletonBase(), _runtime(runtime) {}
    ~CBmpSingleton(){}

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

IBmpFactoryImpl^ CBmpFactory::_impl;

IBmp* CBmpFactory::createModuleByID(const rho::String& strID)
{
    return new CBmpImpl(strID, _impl->getImpl(rho::common::convertStringToWP8(strID)));
}

IBmpSingleton* CBmpFactory::createModuleSingleton()
{
    return new CBmpSingleton(_impl->getSingletonImpl());
}

}

extern "C" void Init_Bmp_extension()
{
    rho::CBmpFactory::setInstance( new rho::CBmpFactory() );
    rho::Init_Bmp_API();

    RHODESAPP().getExtManager().requireRubyFile("RhoBmpApi");
}
