//
//  FingerprintImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/FingerprintBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CFingerprintSingletonImpl: public CFingerprintSingletonBase
    {
    public:
        
        CFingerprintSingletonImpl(): CFingerprintSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","Fingerprint");
            
        } 

    };
    
    class CFingerprintImpl : public CFingerprintBase
    {
    public:
        virtual ~CFingerprintImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void enableFingerprintScan(rho::apiGenerator::CMethodResult& oResult) {

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
    
    class CFingerprintFactory: public CFingerprintFactoryBase    {
    public:
        CFingerprintFactory(){}
        
        IFingerprintSingleton* createModuleSingleton()
        { 
            return new CFingerprintSingletonImpl();
        }
        
        virtual IFingerprint* createModuleByID(const rho::String& strID){ return new CFingerprintImpl(); };
        
    };
    
}

extern "C" void Init_Fingerprint_extension()
{
    rho::CFingerprintFactory::setInstance( new rho::CFingerprintFactory() );
    rho::Init_Fingerprint_API();
    
}