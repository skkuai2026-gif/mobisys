//
//  BmpImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/BmpBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CBmpSingletonImpl: public CBmpSingletonBase
    {
    public:
        
        CBmpSingletonImpl(): CBmpSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","Bmp");
            
        } 

    };
    
    class CBmpImpl : public CBmpBase
    {
    public:
        virtual ~CBmpImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void sensorDataFetch(rho::apiGenerator::CMethodResult& oResult) {

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
    
    class CBmpFactory: public CBmpFactoryBase    {
    public:
        CBmpFactory(){}
        
        IBmpSingleton* createModuleSingleton()
        { 
            return new CBmpSingletonImpl();
        }
        
        virtual IBmp* createModuleByID(const rho::String& strID){ return new CBmpImpl(); };
        
    };
    
}

extern "C" void Init_Bmp_extension()
{
    rho::CBmpFactory::setInstance( new rho::CBmpFactory() );
    rho::Init_Bmp_API();
    
}