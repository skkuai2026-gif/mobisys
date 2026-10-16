//
//  PdfgenImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/PdfgenBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CPdfgenSingletonImpl: public CPdfgenSingletonBase
    {
    public:
        
        CPdfgenSingletonImpl(): CPdfgenSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","Pdfgen");
            
        } 

    };
    
    class CPdfgenImpl : public CPdfgenBase
    {
    public:
        virtual ~CPdfgenImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void generateAndroidPDF( const rho::String& inputHTMLFileName,  const rho::String& orientation,  const rho::String& isSinglePDFRequired,  const rho::String& password, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void generateAndroidPDFCharts( const rho::String& chartJSON,  const rho::String& chartOutputFileName,  const rho::String& chartType, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void generateIOSPDF( const rho::String& htmlContent,  const rho::String& targetFilePath, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void mergeIOSPDF( const rho::String& listOfPaths,  const rho::String& targetFilePath,  const rho::String& masterPassword,  const rho::String& password, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void getProperty( const rho::String& propertyName, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void getAllProperties(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, rho::apiGenerator::CMethodResult& oResult) {

        } 

    };
    
    ////////////////////////////////////////////////////////////////////////
    
    class CPdfgenFactory: public CPdfgenFactoryBase    {
    public:
        CPdfgenFactory(){}
        
        IPdfgenSingleton* createModuleSingleton()
        { 
            return new CPdfgenSingletonImpl();
        }
        
        virtual IPdfgen* createModuleByID(const rho::String& strID){ return new CPdfgenImpl(); };
        
    };
    
}

extern "C" void Init_Pdfgen_extension()
{
    rho::CPdfgenFactory::setInstance( new rho::CPdfgenFactory() );
    rho::Init_Pdfgen_API();
    
}