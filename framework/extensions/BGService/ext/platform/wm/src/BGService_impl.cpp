#include "../../../shared/generated/cpp/BGServiceBase.h"

namespace rho {

using namespace apiGenerator;

class CBGServiceImpl: public CBGServiceBase
{
public:
    CBGServiceImpl(const rho::String& strID): CBGServiceBase()
    {
    }

    virtual void getPlatformName(rho::apiGenerator::CMethodResult& oResult) {
         oResult.set("WM");
    }

    virtual void calcSumm( int a,  int b, rho::apiGenerator::CMethodResult& oResult) {
         oResult.set(a+b);
    }
    
    virtual void joinStrings( const rho::String& a,  const rho::String& b, rho::apiGenerator::CMethodResult& oResult) {
         oResult.set(a+b);
    }

};

class CBGServiceSingleton: public CBGServiceSingletonBase
{
    ~CBGServiceSingleton(){}
    virtual rho::String getInitialDefaultID();
    virtual void enumerate(CMethodResult& oResult);
};

class CBGServiceFactory: public CBGServiceFactoryBase
{
    ~CBGServiceFactory(){}
    virtual IBGServiceSingleton* createModuleSingleton();
    virtual IBGService* createModuleByID(const rho::String& strID);
};

extern "C" void Init_BGService_extension()
{
    CBGServiceFactory::setInstance( new CBGServiceFactory() );
    Init_BGService_API();
}

IBGService* CBGServiceFactory::createModuleByID(const rho::String& strID)
{
    return new CBGServiceImpl(strID);
}

IBGServiceSingleton* CBGServiceFactory::createModuleSingleton()
{
    return new CBGServiceSingleton();
}

void CBGServiceSingleton::enumerate(CMethodResult& oResult)
{
    rho::Vector<rho::String> arIDs;
    arIDs.addElement("SC1");
    arIDs.addElement("SC2");

    oResult.set(arIDs);
}

rho::String CBGServiceSingleton::getInitialDefaultID()
{
    CMethodResult oRes;
    enumerate(oRes);

    rho::Vector<rho::String>& arIDs = oRes.getStringArray();
        
    return arIDs[0];
}

}