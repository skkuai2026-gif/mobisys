#include "../../../shared/generated/cpp/ApptrackingBase.h"

namespace rho {

using namespace apiGenerator;

class CApptrackingImpl: public CApptrackingBase
{
public:
    CApptrackingImpl(const rho::String& strID): CApptrackingBase()
    {
    }

    virtual void getPlatformName(rho::apiGenerator::CMethodResult& oResult) {
         oResult.set("UWP");
    }

    virtual void calcSumm( int a,  int b, rho::apiGenerator::CMethodResult& oResult) {
         oResult.set(a+b);
    }
    
    virtual void joinStrings( const rho::String& a,  const rho::String& b, rho::apiGenerator::CMethodResult& oResult) {
         oResult.set(a+b);
    }
};

class CApptrackingSingleton: public CApptrackingSingletonBase
{
    ~CApptrackingSingleton(){}
    virtual rho::String getInitialDefaultID();
    virtual void enumerate(CMethodResult& oResult);
};

class CApptrackingFactory: public CApptrackingFactoryBase
{
    ~CApptrackingFactory(){}
    virtual IApptrackingSingleton* createModuleSingleton();
    virtual IApptracking* createModuleByID(const rho::String& strID);
};

extern "C" void Init_Apptracking_extension()
{
    CApptrackingFactory::setInstance( new CApptrackingFactory() );
    Init_Apptracking_API();
}

IApptracking* CApptrackingFactory::createModuleByID(const rho::String& strID)
{
    return new CApptrackingImpl(strID);
}

IApptrackingSingleton* CApptrackingFactory::createModuleSingleton()
{
    return new CApptrackingSingleton();
}

void CApptrackingSingleton::enumerate(CMethodResult& oResult)
{
    rho::Vector<rho::String> arIDs;
    arIDs.addElement("SC1");
    arIDs.addElement("SC2");

    oResult.set(arIDs);
}

rho::String CApptrackingSingleton::getInitialDefaultID()
{
    CMethodResult oRes;
    enumerate(oRes);

    rho::Vector<rho::String>& arIDs = oRes.getStringArray();
        
    return arIDs[0];
}

}