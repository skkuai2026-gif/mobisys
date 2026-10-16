//
//  ApptrackingImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/ApptrackingBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CApptrackingSingletonImpl: public CApptrackingSingletonBase
    {
    public:
        
        CApptrackingSingletonImpl(): CApptrackingSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","Apptracking");
            
        } 

    };
    
    class CApptrackingImpl : public CApptrackingBase
    {
    public:
        virtual ~CApptrackingImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void requestAppTrackingPermission(rho::apiGenerator::CMethodResult& oResult) {

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
    
    class CApptrackingFactory: public CApptrackingFactoryBase    {
    public:
        CApptrackingFactory(){}
        
        IApptrackingSingleton* createModuleSingleton()
        { 
            return new CApptrackingSingletonImpl();
        }
        
        virtual IApptracking* createModuleByID(const rho::String& strID){ return new CApptrackingImpl(); };
        
    };
    
}

extern "C" void Init_Apptracking_extension()
{
    rho::CApptrackingFactory::setInstance( new rho::CApptrackingFactory() );
    rho::Init_Apptracking_API();
    
}