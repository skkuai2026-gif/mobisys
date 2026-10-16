#pragma once

#include "IFingerprint.h"
#include "logging/RhoLog.h"
#include "common/StringConverter.h"
#include "common/ExtManager.h"


namespace rho {

using namespace rho::apiGenerator;
using namespace rho;

// hash keys used in properties and parameters 
namespace fingerprint {

    static const char HK_AUTH_STATUS[] = "authStatus"; 

    static const char HK_STATUS_MESSAGE[] = "statusMessage"; 

    static const char PROPERTY_SIMPLE_STRING_PROPERTY[] = "simpleStringProperty"; 
 
} 

class CFingerprintFactoryBase : public CModuleFactoryBase<IFingerprint, IFingerprintSingleton, IFingerprintFactory>
{
protected:
    static rho::common::CAutoPtr<CFingerprintFactoryBase> m_pInstance;
    HashtablePtr<rho::String,IFingerprint*> m_hashModules;

public:

    static void setInstance(CFingerprintFactoryBase* pInstance){ m_pInstance = pInstance; }
    static CFingerprintFactoryBase* getInstance(){ return m_pInstance; }

    static IFingerprintSingleton* getFingerprintSingletonS(){ return getInstance()->getModuleSingleton(); }

    virtual IFingerprint* getModuleByID(const rho::String& strID)
    {
        if ( !m_hashModules.containsKey(strID) )
        {
            IFingerprint* pObj = createModuleByID(strID);
            m_hashModules.put(strID, pObj );

            return pObj;
        }

        return m_hashModules[strID];
    }

    virtual IFingerprint* createModuleByID(const rho::String& strID){ return (IFingerprint*)0; };
    virtual void deleteModuleByID(const rho::String& strID)
    {
        m_hashModules.remove(strID);
    }

};

class CFingerprintSingletonBase : public CModuleSingletonBase< IFingerprintSingleton >, public rho::common::IRhoExtension
{
protected:
    DEFINE_LOGCLASS;


    rho::String m_strDefaultID;




public:
    virtual rho::LogCategory getModuleLogCategory(){ return getLogCategory(); }

    CFingerprintSingletonBase();
    ~CFingerprintSingletonBase();




    virtual void setDefaultID(const rho::String& strDefaultID){ m_strDefaultID = strDefaultID; }
    virtual rho::String getDefaultID()
    { 
        if ( m_strDefaultID.length() == 0 )
            setDefaultID(getInitialDefaultID());
        return m_strDefaultID; 
    }

};

class CFingerprintBase: public IFingerprint
{
protected:
    DEFINE_LOGCLASS;


    rho::Hashtable<rho::String, rho::String> m_hashProps;
    rho::Hashtable<rho::String, rho::apiGenerator::CMethodAccessor< IFingerprint > *> m_mapPropAccessors;

public:


    CFingerprintBase();

    virtual void getProperty( const rho::String& propertyName, CMethodResult& oResult);
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, CMethodResult& oResult);
    virtual void getAllProperties(CMethodResult& oResult);
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, CMethodResult& oResult);
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, CMethodResult& oResult);
    virtual void clearAllProperties(CMethodResult& oResult);


    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);

    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);


    static CFingerprintBase* getInstance(){ return static_cast< CFingerprintBase* >(CFingerprintFactoryBase::getInstance()->getModuleByID(CFingerprintFactoryBase::getFingerprintSingletonS()->getDefaultID())); }
 

};

extern "C" void Init_Fingerprint_API();


}
