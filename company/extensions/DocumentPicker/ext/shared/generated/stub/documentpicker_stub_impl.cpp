//
//  DocumentPickerImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/DocumentPickerBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CDocumentPickerSingletonImpl: public CDocumentPickerSingletonBase
    {
    public:
        
        CDocumentPickerSingletonImpl(): CDocumentPickerSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","DocumentPicker");
            
        } 

    };
    
    class CDocumentPickerImpl : public CDocumentPickerBase
    {
    public:
        virtual ~CDocumentPickerImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void pickDocument( const rho::String& supportedExtensionList, rho::apiGenerator::CMethodResult& oResult) {

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
    
    class CDocumentPickerFactory: public CDocumentPickerFactoryBase    {
    public:
        CDocumentPickerFactory(){}
        
        IDocumentPickerSingleton* createModuleSingleton()
        { 
            return new CDocumentPickerSingletonImpl();
        }
        
        virtual IDocumentPicker* createModuleByID(const rho::String& strID){ return new CDocumentPickerImpl(); };
        
    };
    
}

extern "C" void Init_DocumentPicker_extension()
{
    rho::CDocumentPickerFactory::setInstance( new rho::CDocumentPickerFactory() );
    rho::Init_DocumentPicker_API();
    
}