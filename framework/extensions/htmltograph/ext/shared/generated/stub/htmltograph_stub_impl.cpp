//
//  HtmlToGraphImpl.cpp
#include "common/RhoStd.h"
#include "common/AutoPointer.h"
#include "common/RhodesApp.h"
#include "common/RhoConf.h"
#include "generated/cpp/HtmlToGraphBase.h"
#include "logging/RhoLog.h"

namespace rho {
    
    using namespace apiGenerator;
    using namespace common;
    
    class CHtmlToGraphSingletonImpl: public CHtmlToGraphSingletonBase
    {
    public:
        
        CHtmlToGraphSingletonImpl(): CHtmlToGraphSingletonBase(){}
        
        //methods
        // enumerate  
        virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) {
            // RAWLOGC_INFO("enumerate","HtmlToGraph");
            
        } 

    };
    
    class CHtmlToGraphImpl : public CHtmlToGraphBase
    {
    public:
        virtual ~CHtmlToGraphImpl() {}

        //methods

        virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void getPlatformName(rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void getGraphIOS( const rho::String& htmlString, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void getGraphAndroid( const rho::String& htmlString, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void calcSumm( int a,  int b, rho::apiGenerator::CMethodResult& oResult) {

        } 

        virtual void joinStrings( const rho::String& a,  const rho::String& b, rho::apiGenerator::CMethodResult& oResult) {

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
    
    class CHtmlToGraphFactory: public CHtmlToGraphFactoryBase    {
    public:
        CHtmlToGraphFactory(){}
        
        IHtmlToGraphSingleton* createModuleSingleton()
        { 
            return new CHtmlToGraphSingletonImpl();
        }
        
        virtual IHtmlToGraph* createModuleByID(const rho::String& strID){ return new CHtmlToGraphImpl(); };
        
    };
    
}

extern "C" void Init_HtmlToGraph_extension()
{
    rho::CHtmlToGraphFactory::setInstance( new rho::CHtmlToGraphFactory() );
    rho::Init_HtmlToGraph_API();
    
}