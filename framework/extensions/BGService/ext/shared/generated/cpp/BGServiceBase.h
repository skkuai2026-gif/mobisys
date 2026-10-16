#pragma once

#include "IBGService.h"
#include "logging/RhoLog.h"
#include "common/StringConverter.h"
#include "common/ExtManager.h"


namespace rho {

using namespace rho::apiGenerator;
using namespace rho;

// hash keys used in properties and parameters 
namespace bgservice {

    static const char PROPERTY_SIMPLE_STRING_PROPERTY[] = "simpleStringProperty"; 
 
} 

class CBGServiceFactoryBase : public CModuleFactoryBase<IBGService, IBGServiceSingleton, IBGServiceFactory>
{
protected:
    static rho::common::CAutoPtr<CBGServiceFactoryBase> m_pInstance;
    HashtablePtr<rho::String,IBGService*> m_hashModules;

public:

    static void setInstance(CBGServiceFactoryBase* pInstance){ m_pInstance = pInstance; }
    static CBGServiceFactoryBase* getInstance(){ return m_pInstance; }

    static IBGServiceSingleton* getBGServiceSingletonS(){ return getInstance()->getModuleSingleton(); }

    virtual IBGService* getModuleByID(const rho::String& strID)
    {
        if ( !m_hashModules.containsKey(strID) )
        {
            IBGService* pObj = createModuleByID(strID);
            m_hashModules.put(strID, pObj );

            return pObj;
        }

        return m_hashModules[strID];
    }

    virtual IBGService* createModuleByID(const rho::String& strID){ return (IBGService*)0; };
    virtual void deleteModuleByID(const rho::String& strID)
    {
        m_hashModules.remove(strID);
    }

};

class CBGServiceSingletonBase : public CModuleSingletonBase< IBGServiceSingleton >, public rho::common::IRhoExtension
{
protected:
    DEFINE_LOGCLASS;


    rho::String m_strDefaultID;




public:
    virtual rho::LogCategory getModuleLogCategory(){ return getLogCategory(); }

    CBGServiceSingletonBase();
    ~CBGServiceSingletonBase();




    virtual void setDefaultID(const rho::String& strDefaultID){ m_strDefaultID = strDefaultID; }
    virtual rho::String getDefaultID()
    { 
        if ( m_strDefaultID.length() == 0 )
            setDefaultID(getInitialDefaultID());
        return m_strDefaultID; 
    }

};

class CBGServiceBase: public IBGService
{
protected:
    DEFINE_LOGCLASS;


    rho::Hashtable<rho::String, rho::String> m_hashProps;
    rho::Hashtable<rho::String, rho::apiGenerator::CMethodAccessor< IBGService > *> m_mapPropAccessors;

public:


    CBGServiceBase();

    virtual void getProperty( const rho::String& propertyName, CMethodResult& oResult);
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, CMethodResult& oResult);
    virtual void getAllProperties(CMethodResult& oResult);
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, CMethodResult& oResult);
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, CMethodResult& oResult);
    virtual void clearAllProperties(CMethodResult& oResult);


    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);

    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);


    static CBGServiceBase* getInstance(){ return static_cast< CBGServiceBase* >(CBGServiceFactoryBase::getInstance()->getModuleByID(CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID())); }
 

};

extern "C" void Init_BGService_API();


}
