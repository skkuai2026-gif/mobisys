#pragma once

#include "IPdfgen.h"
#include "logging/RhoLog.h"
#include "common/StringConverter.h"
#include "common/ExtManager.h"


namespace rho {

using namespace rho::apiGenerator;
using namespace rho;

// hash keys used in properties and parameters 
namespace pdfgen {

    static const char PROPERTY_SIMPLE_STRING_PROPERTY[] = "simpleStringProperty"; 
 
} 

class CPdfgenFactoryBase : public CModuleFactoryBase<IPdfgen, IPdfgenSingleton, IPdfgenFactory>
{
protected:
    static rho::common::CAutoPtr<CPdfgenFactoryBase> m_pInstance;
    HashtablePtr<rho::String,IPdfgen*> m_hashModules;

public:

    static void setInstance(CPdfgenFactoryBase* pInstance){ m_pInstance = pInstance; }
    static CPdfgenFactoryBase* getInstance(){ return m_pInstance; }

    static IPdfgenSingleton* getPdfgenSingletonS(){ return getInstance()->getModuleSingleton(); }

    virtual IPdfgen* getModuleByID(const rho::String& strID)
    {
        if ( !m_hashModules.containsKey(strID) )
        {
            IPdfgen* pObj = createModuleByID(strID);
            m_hashModules.put(strID, pObj );

            return pObj;
        }

        return m_hashModules[strID];
    }

    virtual IPdfgen* createModuleByID(const rho::String& strID){ return (IPdfgen*)0; };
    virtual void deleteModuleByID(const rho::String& strID)
    {
        m_hashModules.remove(strID);
    }

};

class CPdfgenSingletonBase : public CModuleSingletonBase< IPdfgenSingleton >, public rho::common::IRhoExtension
{
protected:
    DEFINE_LOGCLASS;


    rho::String m_strDefaultID;




public:
    virtual rho::LogCategory getModuleLogCategory(){ return getLogCategory(); }

    CPdfgenSingletonBase();
    ~CPdfgenSingletonBase();




    virtual void setDefaultID(const rho::String& strDefaultID){ m_strDefaultID = strDefaultID; }
    virtual rho::String getDefaultID()
    { 
        if ( m_strDefaultID.length() == 0 )
            setDefaultID(getInitialDefaultID());
        return m_strDefaultID; 
    }

};

class CPdfgenBase: public IPdfgen
{
protected:
    DEFINE_LOGCLASS;


    rho::Hashtable<rho::String, rho::String> m_hashProps;
    rho::Hashtable<rho::String, rho::apiGenerator::CMethodAccessor< IPdfgen > *> m_mapPropAccessors;

public:


    CPdfgenBase();

    virtual void getProperty( const rho::String& propertyName, CMethodResult& oResult);
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, CMethodResult& oResult);
    virtual void getAllProperties(CMethodResult& oResult);
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, CMethodResult& oResult);
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, CMethodResult& oResult);
    virtual void clearAllProperties(CMethodResult& oResult);


    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);

    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);


    static CPdfgenBase* getInstance(){ return static_cast< CPdfgenBase* >(CPdfgenFactoryBase::getInstance()->getModuleByID(CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID())); }
 

};

extern "C" void Init_Pdfgen_API();


}
