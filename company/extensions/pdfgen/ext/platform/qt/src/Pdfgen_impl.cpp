#include "../../../shared/generated/cpp/PdfgenBase.h"

namespace rho {

using namespace apiGenerator;

class CPdfgenImpl: public CPdfgenBase
{
public:
    CPdfgenImpl(const rho::String& strID): CPdfgenBase()
    {
    }

    virtual void getPlatformName(rho::apiGenerator::CMethodResult& oResult) {
         oResult.set("Win32");
    }

    virtual void calcSumm( int a,  int b, rho::apiGenerator::CMethodResult& oResult) {
         oResult.set(a+b);
    }
    
    virtual void joinStrings( const rho::String& a,  const rho::String& b, rho::apiGenerator::CMethodResult& oResult) {
         oResult.set(a+b);
    }

};

class CPdfgenSingleton: public CPdfgenSingletonBase
{
    ~CPdfgenSingleton(){}
    virtual rho::String getInitialDefaultID();
    virtual void enumerate(CMethodResult& oResult);
};

class CPdfgenFactory: public CPdfgenFactoryBase
{
    ~CPdfgenFactory(){}
    virtual IPdfgenSingleton* createModuleSingleton();
    virtual IPdfgen* createModuleByID(const rho::String& strID);
};

extern "C" void Init_Pdfgen_extension()
{
    CPdfgenFactory::setInstance( new CPdfgenFactory() );
    Init_Pdfgen_API();
}

IPdfgen* CPdfgenFactory::createModuleByID(const rho::String& strID)
{
    return new CPdfgenImpl(strID);
}

IPdfgenSingleton* CPdfgenFactory::createModuleSingleton()
{
    return new CPdfgenSingleton();
}

void CPdfgenSingleton::enumerate(CMethodResult& oResult)
{
    rho::Vector<rho::String> arIDs;
    arIDs.addElement("SC1");
    arIDs.addElement("SC2");

    oResult.set(arIDs);
}

rho::String CPdfgenSingleton::getInitialDefaultID()
{
    CMethodResult oRes;
    enumerate(oRes);

    rho::Vector<rho::String>& arIDs = oRes.getStringArray();
        
    return arIDs[0];
}

}