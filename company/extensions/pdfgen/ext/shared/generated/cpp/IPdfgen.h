#pragma once

#include "common/RhoStd.h"
#include "api_generator/MethodResult.h"
#include "api_generator/BaseClasses.h"


namespace rho {
///////////////////////////////////////////////////////////



struct IPdfgen
{
//constants


//methods
    virtual ~IPdfgen(){}

    virtual void getSimpleStringProperty(rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void setSimpleStringProperty( const rho::String& simpleStringProperty, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void generateAndroidPDF( const rho::String& inputHTMLFileName,  const rho::String& orientation,  const rho::String& isSinglePDFRequired,  const rho::String& password, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void generateAndroidPDFCharts( const rho::String& chartJSON,  const rho::String& chartOutputFileName,  const rho::String& chartType, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void generateIOSPDF( const rho::String& htmlContent,  const rho::String& targetFilePath, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void mergeIOSPDF( const rho::String& listOfPaths,  const rho::String& targetFilePath,  const rho::String& masterPassword,  const rho::String& password, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void getProperty( const rho::String& propertyName, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void getProperties( const rho::Vector<rho::String>& arrayofNames, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void getAllProperties(rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void setProperty( const rho::String& propertyName,  const rho::String& propertyValue, rho::apiGenerator::CMethodResult& oResult) = 0;
    virtual void setProperties( const rho::Hashtable<rho::String, rho::String>& propertyMap, rho::apiGenerator::CMethodResult& oResult) = 0;

};

struct IPdfgenSingleton
{
//constants


    virtual ~IPdfgenSingleton(){}

//methods
    virtual void enumerate(rho::apiGenerator::CMethodResult& oResult) = 0;


    virtual rho::String getDefaultID() = 0;
    virtual rho::String getInitialDefaultID() = 0;
    virtual void setDefaultID(const rho::String& strID) = 0;

    virtual void addCommandToQueue(rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor) = 0;
    virtual void callCommandInThread(rho::common::IRhoRunnable* pFunctor) = 0;
};

struct IPdfgenFactory
{
    virtual ~IPdfgenFactory(){}

    virtual IPdfgenSingleton* getModuleSingleton() = 0;


    virtual IPdfgen* getModuleByID(const rho::String& strID) = 0;

};


}
