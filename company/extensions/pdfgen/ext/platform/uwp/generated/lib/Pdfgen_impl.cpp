#include "Pdfgen_impl.h"
#include "PdfgenFactory.h"
#include "api_generator/uwp/MethodResultImpl.h"

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

void CPdfgenImpl::generateAndroidPDF(const rho::String& inputHTMLFileName, const rho::String& orientation, const rho::String& isSinglePDFRequired, const rho::String& password, CMethodResult& oResult)
{
        Platform::String^ _inputHTMLFileName = rho::common::convertStringToWP8(inputHTMLFileName);
        Platform::String^ _orientation = rho::common::convertStringToWP8(orientation);
        Platform::String^ _isSinglePDFRequired = rho::common::convertStringToWP8(isSinglePDFRequired);
        Platform::String^ _password = rho::common::convertStringToWP8(password);
    try {
        _runtime->generateAndroidPDF(_inputHTMLFileName, _orientation, _isSinglePDFRequired, _password, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CPdfgenImpl::generateAndroidPDFCharts(const rho::String& chartJSON, const rho::String& chartOutputFileName, const rho::String& chartType, CMethodResult& oResult)
{
        Platform::String^ _chartJSON = rho::common::convertStringToWP8(chartJSON);
        Platform::String^ _chartOutputFileName = rho::common::convertStringToWP8(chartOutputFileName);
        Platform::String^ _chartType = rho::common::convertStringToWP8(chartType);
    try {
        _runtime->generateAndroidPDFCharts(_chartJSON, _chartOutputFileName, _chartType, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CPdfgenImpl::generateIOSPDF(const rho::String& htmlContent, const rho::String& targetFilePath, CMethodResult& oResult)
{
        Platform::String^ _htmlContent = rho::common::convertStringToWP8(htmlContent);
        Platform::String^ _targetFilePath = rho::common::convertStringToWP8(targetFilePath);
    try {
        _runtime->generateIOSPDF(_htmlContent, _targetFilePath, ref new CMethodResultImpl((int64)&oResult));
    } catch (Platform::Exception^ e) {
        LOG(ERROR) + rho::common::convertStringAFromWP8(e->ToString());
    }
}

void CPdfgenImpl::mergeIOSPDF(const rho::String& listOfPaths, const rho::String& targetFilePath, const rho::String& masterPassword, const rho::String& password, CMethodResult& oResult)
{
        Platform::String^ _listOfPaths = rho::common::convertStringToWP8(listOfPaths);
        Platform::String^ _targetFilePath = rho::common::convertStringToWP8(targetFilePath);
        Platform::String^ _masterPassword = rho::common::convertStringToWP8(masterPassword);
        Platform::String^ _password = rho::common::convertStringToWP8(password);
    try {
        _runtime->mergeIOSPDF(_listOfPaths, _targetFilePath, _masterPassword, _password, ref new CMethodResultImpl((int64)&oResult));
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
    return new CPdfgenImpl(strID, _impl->getImpl(rho::common::convertStringToWP8(strID)));
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
