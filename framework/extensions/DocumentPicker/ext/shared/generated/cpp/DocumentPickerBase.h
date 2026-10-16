#pragma once

#include "IDocumentPicker.h"
#include "logging/RhoLog.h"
#include "common/StringConverter.h"
#include "common/ExtManager.h"


namespace rho {

using namespace rho::apiGenerator;
using namespace rho;

// hash keys used in properties and parameters 
namespace documentpicker {

    static const char HK_FILE_PATH[] = "filePath"; 

    static const char HK_STATUS[] = "status"; 

    static const char PROPERTY_SIMPLE_STRING_PROPERTY[] = "simpleStringProperty"; 
 
} 

class CDocumentPickerFactoryBase : public CModuleFactoryBase<IDocumentPicker, IDocumentPickerSingleton, IDocumentPickerFactory>
{
protected:
    static rho::common::CAutoPtr<CDocumentPickerFactoryBase> m_pInstance;
    HashtablePtr<rho::String,IDocumentPicker*> m_hashModules;

public:

    static void setInstance(CDocumentPickerFactoryBase* pInstance){ m_pInstance = pInstance; }
    static CDocumentPickerFactoryBase* getInstance(){ return m_pInstance; }

    static IDocumentPickerSingleton* getDocumentPickerSingletonS(){ return getInstance()->getModuleSingleton(); }

    virtual IDocumentPicker* getModuleByID(const rho::String& strID)
    {
        if ( !m_hashModules.containsKey(strID) )
        {
            IDocumentPicker* pObj = createModuleByID(strID);
            m_hashModules.put(strID, pObj );

            return pObj;
        }

        return m_hashModules[strID];
    }

    virtual IDocumentPicker* createModuleByID(const rho::String& strID){ return (IDocumentPicker*)0; };
    virtual void deleteModuleByID(const rho::String& strID)
    {
        m_hashModules.remove(strID);
    }

};

class CDocumentPickerSingletonBase : public CModuleSingletonBase< IDocumentPickerSingleton >, public rho::common::IRhoExtension
{
protected:
    DEFINE_LOGCLASS;


    rho::String m_strDefaultID;




public:
    virtual rho::LogCategory getModuleLogCategory(){ return getLogCategory(); }

    CDocumentPickerSingletonBase();
    ~CDocumentPickerSingletonBase();




    virtual void setDefaultID(const rho::String& strDefaultID){ m_strDefaultID = strDefaultID; }
    virtual rho::String getDefaultID()
    { 
        if ( m_strDefaultID.length() == 0 )
            setDefaultID(getInitialDefaultID());
        return m_strDefaultID; 
    }

};

class CDocumentPickerBase: public IDocumentPicker
{
protected:
    DEFINE_LOGCLASS;


    rho::Hashtable<rho::String, rho::String> m_hashProps;
    rho::Hashtable<rho::String, rho::apiGenerator::CMethodAccessor< IDocumentPicker > *> m_mapPropAccessors;

public:


    CDocumentPickerBase();

    virtual void getProperty( const rho::String& propertyName, CMethodResult& oResult);
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, CMethodResult& oResult);
    virtual void getAllProperties(CMethodResult& oResult);
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, CMethodResult& oResult);
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, CMethodResult& oResult);
    virtual void clearAllProperties(CMethodResult& oResult);


    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult);

    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult);


    static CDocumentPickerBase* getInstance(){ return static_cast< CDocumentPickerBase* >(CDocumentPickerFactoryBase::getInstance()->getModuleByID(CDocumentPickerFactoryBase::getDocumentPickerSingletonS()->getDefaultID())); }
 

};

extern "C" void Init_DocumentPicker_API();


}
