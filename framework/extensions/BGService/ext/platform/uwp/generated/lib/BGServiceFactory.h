#pragma once

#include "../../../../shared/generated/cpp/BGServiceBase.h"
#include "BGServiceRuntime.h"


namespace rho {
class CBGServiceFactory: public CBGServiceFactoryBase
{
private:
    static rhoruntime::IBGServiceFactoryImpl^ _impl;
public:
    static void setImpl(rhoruntime::IBGServiceFactoryImpl^ impl) { _impl = impl; }
    ~CBGServiceFactory(){}
    virtual IBGServiceSingleton* createModuleSingleton();
    virtual IBGService* createModuleByID(const rho::String& strID);
};

}
