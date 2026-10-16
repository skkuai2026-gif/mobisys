#pragma once

#include "../../../../shared/generated/cpp/BmpBase.h"
#include "BmpRuntime.h"


namespace rho {
class CBmpFactory: public CBmpFactoryBase
{
private:
    static rhoruntime::IBmpFactoryImpl^ _impl;
public:
    static void setImpl(rhoruntime::IBmpFactoryImpl^ impl) { _impl = impl; }
    ~CBmpFactory(){}
    virtual IBmpSingleton* createModuleSingleton();
    virtual IBmp* createModuleByID(const rho::String& strID);
};

}
