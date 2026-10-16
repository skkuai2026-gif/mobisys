#pragma once

#include "../../../../shared/generated/cpp/PdfgenBase.h"
#include "PdfgenRuntime.h"


namespace rho {
class CPdfgenFactory: public CPdfgenFactoryBase
{
private:
    static rhoruntime::IPdfgenFactoryImpl^ _impl;
public:
    static void setImpl(rhoruntime::IPdfgenFactoryImpl^ impl) { _impl = impl; }
    ~CPdfgenFactory(){}
    virtual IPdfgenSingleton* createModuleSingleton();
    virtual IPdfgen* createModuleByID(const rho::String& strID);
};

}
