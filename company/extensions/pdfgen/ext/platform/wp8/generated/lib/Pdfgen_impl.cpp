#include "Pdfgen_impl.h"
#include "PdfgenFactory.h"
#include "api_generator/wp8/MethodResultImpl.h"

using namespace rho::apiGenerator;
using namespace rhoruntime;

namespace rho {


void CPdfgenImpl::getSimpleStringProperty(CMethodResult& oResult)
{
    try {
        _runtime->getSimpleStringProperty(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CPdfgenImpl::setSimpleStringProperty(const rho::String& simpleStringProperty, CMethodResult& oResult)
{
        Platform::String^ _simpleStringProperty = rho::common::convertStringToWP8(simpleStringProperty);
    try {
        _runtime->setSimpleStringProperty(_simpleStringProperty, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CPdfgenImpl::generatePDF(const rho::String& htmlContent, const rho::String& targetFilePath, CMethodResult& oResult)
{
        Platform::String^ _htmlContent = rho::common::convertStringToWP8(htmlContent);
        Platform::String^ _targetFilePath = rho::common::convertStringToWP8(targetFilePath);
    try {
        _runtime->generatePDF(_htmlContent, _targetFilePath, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CPdfgenImpl::mergePDF(const rho::String& listOfPaths, const rho::String& targetFilePath, CMethodResult& oResult)
{
        Platform::String^ _listOfPaths = rho::common::convertStringToWP8(listOfPaths);
        Platform::String^ _targetFilePath = rho::common::convertStringToWP8(targetFilePath);
    try {
        _runtime->mergePDF(_listOfPaths, _targetFilePath, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}


class CPdfgenSingleton: public CPdfgenSingletonBase
{
private:
    IPdfgenSingletonImpl^ _runtime;
public:
    CPdfgenSingleton(IPdfgenSingletonImpl^ runtime): CPdfgenSingletonBase(), _runtime(runtime) {}
    ~CPdfgenSingleton(){}

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

IPdfgenFactoryImpl^ CPdfgenFactory::_impl;

IPdfgen* CPdfgenFactory::createModuleByID(const rho::String& strID)
{
    return new CPdfgenImpl(strID, _impl->getImpl());
}

IPdfgenSingleton* CPdfgenFactory::createModuleSingleton()
{
    return new CPdfgenSingleton(_impl->getSingletonImpl());
}

}

extern "C" void Init_Pdfgen_extension()
{
    rho::CPdfgenFactory::setInstance( new rho::CPdfgenFactory() );
    rho::Init_Pdfgen_API();

    RHODESAPP().getExtManager().requireRubyFile("RhoPdfgenApi");
}
