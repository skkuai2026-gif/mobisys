//
//  BGServiceImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/BGServiceBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CBGServiceSingletonImpl: public CBGServiceSingletonBase
    {
    public:
        
        CBGServiceSingletonImpl(): CBGServiceSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","BGService");
            
        } 

    };
    
    class CBGServiceImpl : public CBGServiceBase
    {
    public:
        virtual ~CBGServiceImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void startBackgroundService( const rho::String& bgServiceRubyFunc, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void stopBackgroundService(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void checkBackgroundServiceStatus(rho::apiGenerator::CMethodResult& oResult) {

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
    
    class CBGServiceFactory: public CBGServiceFactoryBase    {
    public:
        CBGServiceFactory(){}
        
        IBGServiceSingleton* createModuleSingleton()
        { 
            return new CBGServiceSingletonImpl();
        }
        
        virtual IBGService* createModuleByID(const rho::String& strID){ return new CBGServiceImpl(); };
        
    };
    
}

extern "C" void Init_BGService_extension()
{
    rho::CBGServiceFactory::setInstance( new rho::CBGServiceFactory() );
    rho::Init_BGService_API();
    
}