#include "HtmlToGraph_impl.h"
#include "HtmlToGraphFactory.h"
#include "api_generator/uwp/MethodResultImpl.h"

using namespace rho::apiGenerator;
using namespace rhoruntime;

namespace rho {


void CHtmlToGraphImpl::getSimpleStringProperty(CMethodResult& oResult)
{
    try {
        _runtime->getSimpleStringProperty(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CHtmlToGraphImpl::setSimpleStringProperty(const rho::String& simpleStringProperty, CMethodResult& oResult)
{
        Platform::String^ _simpleStringProperty = rho::common::convertStringToWP8(simpleStringProperty);
    try {
        _runtime->setSimpleStringProperty(_simpleStringProperty, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CHtmlToGraphImpl::getPlatformName(CMethodResult& oResult)
{
    try {
        _runtime->getPlatformName(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CHtmlToGraphImpl::getGraphIOS(const rho::String& htmlString, CMethodResult& oResult)
{
        Platform::String^ _htmlString = rho::common::convertStringToWP8(htmlString);
    try {
        _runtime->getGraphIOS(_htmlString, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CHtmlToGraphImpl::getGraphAndroid(const rho::String& htmlString, CMethodResult& oResult)
{
        Platform::String^ _htmlString = rho::common::convertStringToWP8(htmlString);
    try {
        _runtime->getGraphAndroid(_htmlString, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CHtmlToGraphImpl::calcSumm(int a, int b, CMethodResult& oResult)
{
    try {
        _runtime->calcSumm(a, b, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CHtmlToGraphImpl::joinStrings(const rho::String& a, const rho::String& b, CMethodResult& oResult)
{
        Platform::String^ _a = rho::common::convertStringToWP8(a);
        Platform::String^ _b = rho::common::convertStringToWP8(b);
    try {
        _runtime->joinStrings(_a, _b, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}


class CHtmlToGraphSingleton: public CHtmlToGraphSingletonBase
{
private:
    IHtmlToGraphSingletonImpl^ _runtime;
public:
    CHtmlToGraphSingleton(IHtmlToGraphSingletonImpl^ runtime): CHtmlToGraphSingletonBase(), _runtime(runtime) {}
    ~CHtmlToGraphSingleton(){}

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

IHtmlToGraphFactoryImpl^ CHtmlToGraphFactory::_impl;

IHtmlToGraph* CHtmlToGraphFactory::createModuleByID(const rho::String& strID)
{
    return new CHtmlToGraphImpl(strID, _impl->getImpl(rho::common::convertStringToWP8(strID)));
}

IHtmlToGraphSingleton* CHtmlToGraphFactory::createModuleSingleton()
{
    return new CHtmlToGraphSingleton(_impl->getSingletonImpl());
}

}

extern "C" void Init_HtmlToGraph_extension()
{
    rho::CHtmlToGraphFactory::setInstance( new rho::CHtmlToGraphFactory() );
    rho::Init_HtmlToGraph_API();

    RHODESAPP().getExtManager().requireRubyFile("RhoHtmlToGraphApi");
}
