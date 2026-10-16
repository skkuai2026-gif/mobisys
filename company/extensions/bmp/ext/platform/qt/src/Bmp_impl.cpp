#include "../../../shared/generated/cpp/BmpBase.h"

namespace rho {

using namespace apiGenerator;

class CBmpImpl: public CBmpBase
{
public:
    CBmpImpl(const rho::String& strID): CBmpBase()
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

class CBmpSingleton: public CBmpSingletonBase
{
    ~CBmpSingleton(){}
    virtual rho::String getInitialDefaultID();
    virtual void enumerate(CMethodResult& oResult);
};

class CBmpFactory: public CBmpFactoryBase
{
    ~CBmpFactory(){}
    virtual IBmpSingleton* createModuleSingleton();
    virtual IBmp* createModuleByID(const rho::String& strID);
};

extern "C" void Init_Bmp_extension()
{
    CBmpFactory::setInstance( new CBmpFactory() );
    Init_Bmp_API();
}

IBmp* CBmpFactory::createModuleByID(const rho::String& strID)
{
    return new CBmpImpl(strID);
}

IBmpSingleton* CBmpFactory::createModuleSingleton()
{
    return new CBmpSingleton();
}

void CBmpSingleton::enumerate(CMethodResult& oResult)
{
    rho::Vector<rho::String> arIDs;
    arIDs.addElement("SC1");
    arIDs.addElement("SC2");

    oResult.set(arIDs);
}

rho::String CBmpSingleton::getInitialDefaultID()
{
    CMethodResult oRes;
    enumerate(oRes);

    rho::Vector<rho::String>& arIDs = oRes.getStringArray();
        
    return arIDs[0];
}

}