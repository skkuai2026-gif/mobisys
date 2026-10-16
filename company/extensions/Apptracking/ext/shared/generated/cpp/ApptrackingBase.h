#pragma once

#include "IApptracking.h"
#include "logging/RhoLog.h"
#include "common/StringConverter.h"
#include "common/ExtManager.h"


namespace rho {

using namespace rho::apiGenerator;
using namespace rho;

// hash keys used in properties and parameters 
namespace apptracking {

    static const char PROPERTY_SIMPLE_STRING_PROPERTY[] = "simpleStringProperty"; 
 
} 

class CApptrackingFactoryBase : public CModuleFactoryBase<IApptracking, IApptrackingSingleton, IApptrackingFactory>
{
protected:
    static rho::common::CAutoPtr<CApptrackingFactoryBase> m_pInstance;
    HashtablePtr<rho::String,IApptracking*> m_hashModules;

public:

    static void setInstance(CApptrackingFactoryBase* pInstance){ m_pInstance = pInstance; }
    static CApptrackingFactoryBase* getInstance(){ return m_pInstance; }

    static IApptrackingSingleton* getApptrackingSingletonS(){ return getInstance()->getModuleSingleton(); }

    virtual IApptracking* getModuleByID(const rho::String& strID)
    {
        if ( !m_hashModules.containsKey(strID) )
        {
            IApptracking* pObj = createModuleByID(strID);
            m_hashModules.put(strID, pObj );

            return pObj;
        }

        return m_hashModules[strID];
    }

    virtual IApptracking* createModuleByID(const rho::String& strID){ return (IApptracking*)0; };
    virtual void deleteModuleByID(const rho::String& strID)
    {
        m_hashModules.remove(strID);
    }

};

class CApptrackingSingletonBase : public CModuleSingletonBase< IApptrackingSingleton >, public rho::common::IRhoExtension
{
protected:
    DEFINE_LOGCLASS;


    rho::String m_strDefaultID;




public:
    virtual rho::LogCategory getModuleLogCategory(){ return getLogCategory(); }

    CApptrackingSingletonBase();
    ~CApptrackingSingletonBase();




    virtual void setDefaultID(const rho::String& strDefaultID){ m_strDefaultID = strDefaultID; }
    virtual rho::String getDefaultID()
    { 
        if ( m_strDefaultID.length() == 0 )
            setDefaultID(getInitialDefaultID());
        return m_strDefaultID; 
    }

};

class CApptrackingBase: public IApptracking
{
protected:
    DEFINE_LOGCLASS;


    rho::Hashtable<rho::String, rho::String> m_hashProps;
    rho::Hashtable<rho::String, rho::apiGenerator::CMethodAccessor< IApptracking > *> m_mapPropAccessors;

public:


    CApptrackingBase();

    virtual void getProperty( const rho::String& propertyName, CMethodResult& oResult);
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, CMethodResult& oResult);
    virtual void getAllProperties(CMethodResult& oResult);
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, CMethodResult& oResult);
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, CMethodResult& oResult);
    virtual void clearAllProperties(CMethodResult& oResult);


    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);

    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);


    static CApptrackingBase* getInstance(){ return static_cast< CApptrackingBase* >(CApptrackingFactoryBase::getInstance()->getModuleByID(CApptrackingFactoryBase::getApptrackingSingletonS()->getDefaultID())); }
 

};

extern "C" void Init_Apptracking_API();


}
