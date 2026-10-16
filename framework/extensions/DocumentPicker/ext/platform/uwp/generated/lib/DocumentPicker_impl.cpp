#include "DocumentPicker_impl.h"
#include "DocumentPickerFactory.h"
#include "api_generator/uwp/MethodResultImpl.h"

using namespace rho::apiGenerator;
using namespace rhoruntime;

namespace rho {


void CDocumentPickerImpl::getSimpleStringProperty(CMethodResult& oResult)
{
    try {
        _runtime->getSimpleStringProperty(ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CDocumentPickerImpl::setSimpleStringProperty(const rho::String& simpleStringProperty, CMethodResult& oResult)
{
        Platform::String^ _simpleStringProperty = rho::common::convertStringToWP8(simpleStringProperty);
    try {
        _runtime->setSimpleStringProperty(_simpleStringProperty, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CDocumentPickerImpl::pickDocument(const rho::String& supportedExtensionList, CMethodResult& oResult)
{
        Platform::String^ _supportedExtensionList = rho::common::convertStringToWP8(supportedExtensionList);
    try {
        _runtime->pickDocument(_supportedExtensionList, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}


class CDocumentPickerSingleton: public CDocumentPickerSingletonBase
{
private:
    IDocumentPickerSingletonImpl^ _runtime;
public:
    CDocumentPickerSingleton(IDocumentPickerSingletonImpl^ runtime): CDocumentPickerSingletonBase(), _runtime(runtime) {}
    ~CDocumentPickerSingleton(){}

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

IDocumentPickerFactoryImpl^ CDocumentPickerFactory::_impl;

IDocumentPicker* CDocumentPickerFactory::createModuleByID(const rho::String& strID)
{
    return new CDocumentPickerImpl(strID, _impl->getImpl(rho::common::convertStringToWP8(strID)));
}

IDocumentPickerSingleton* CDocumentPickerFactory::createModuleSingleton()
{
    return new CDocumentPickerSingleton(_impl->getSingletonImpl());
}

}

extern "C" void Init_DocumentPicker_extension()
{
    rho::CDocumentPickerFactory::setInstance( new rho::CDocumentPickerFactory() );
    rho::Init_DocumentPicker_API();

    RHODESAPP().getExtManager().requireRubyFile("RhoDocumentPickerApi");
}
