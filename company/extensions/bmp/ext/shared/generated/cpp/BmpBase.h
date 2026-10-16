#pragma once

#include "IBmp.h"
#include "logging/RhoLog.h"
#include "common/StringConverter.h"
#include "common/ExtManager.h"


namespace rho {

using namespace rho::apiGenerator;
using namespace rho;

// hash keys used in properties and parameters 
namespace bmp {

    static const char PROPERTY_SIMPLE_STRING_PROPERTY[] = "simpleStringProperty"; 
 
} 

class CBmpFactoryBase : public CModuleFactoryBase<IBmp, IBmpSingleton, IBmpFactory>
{
protected:
    static rho::common::CAutoPtr<CBmpFactoryBase> m_pInstance;
    HashtablePtr<rho::String,IBmp*> m_hashModules;

public:

    static void setInstance(CBmpFactoryBase* pInstance){ m_pInstance = pInstance; }
    static CBmpFactoryBase* getInstance(){ return m_pInstance; }

    static IBmpSingleton* getBmpSingletonS(){ return getInstance()->getModuleSingleton(); }

    virtual IBmp* getModuleByID(const rho::String& strID)
    {
        if ( !m_hashModules.containsKey(strID) )
        {
            IBmp* pObj = createModuleByID(strID);
            m_hashModules.put(strID, pObj );

            return pObj;
        }

        return m_hashModules[strID];
    }

    virtual IBmp* createModuleByID(const rho::String& strID){ return (IBmp*)0; };
    virtual void deleteModuleByID(const rho::String& strID)
    {
        m_hashModules.remove(strID);
    }

};

class CBmpSingletonBase : public CModuleSingletonBase< IBmpSingleton >, public rho::common::IRhoExtension
{
protected:
    DEFINE_LOGCLASS;


    rho::String m_strDefaultID;




public:
    virtual rho::LogCategory getModuleLogCategory(){ return getLogCategory(); }

    CBmpSingletonBase();
    ~CBmpSingletonBase();




    virtual void setDefaultID(const rho::String& strDefaultID){ m_strDefaultID = strDefaultID; }
    virtual rho::String getDefaultID()
    { 
        if ( m_strDefaultID.length() == 0 )
            setDefaultID(getInitialDefaultID());
        return m_strDefaultID; 
    }

};

class CBmpBase: public IBmp
{
protected:
    DEFINE_LOGCLASS;


    rho::Hashtable<rho::String, rho::String> m_hashProps;
    rho::Hashtable<rho::String, rho::apiGenerator::CMethodAccessor< IBmp > *> m_mapPropAccessors;

public:


    CBmpBase();

    virtual void getProperty( const rho::String& propertyName, CMethodResult& oResult);
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, CMethodResult& oResult);
    virtual void getAllProperties(CMethodResult& oResult);
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, CMethodResult& oResult);
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, CMethodResult& oResult);
    virtual void clearAllProperties(CMethodResult& oResult);


    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);

    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);


    static CBmpBase* getInstance(){ return static_cast< CBmpBase* >(CBmpFactoryBase::getInstance()->getModuleByID(CBmpFactoryBase::getBmpSingletonS()->getDefaultID())); }
 

};

extern "C" void Init_Bmp_API();


}
