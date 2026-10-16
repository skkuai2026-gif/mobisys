#pragma once

#include "../../../../shared/generated/cpp/ApptrackingBase.h"
#include "ApptrackingRuntime.h"


namespace rho {
class CApptrackingFactory: public CApptrackingFactoryBase
{
private:
    static rhoruntime::IApptrackingFactoryImpl^ _impl;
public:
    static void setImpl(rhoruntime::IApptrackingFactoryImpl^ impl) { _impl = impl; }
    ~CApptrackingFactory(){}
    virtual IApptrackingSingleton* createModuleSingleton();
    virtual IApptracking* createModuleByID(const rho::String& strID);
};

}
