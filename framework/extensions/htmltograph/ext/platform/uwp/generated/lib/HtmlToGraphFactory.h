#pragma once

#include "../../../../shared/generated/cpp/HtmlToGraphBase.h"
#include "HtmlToGraphRuntime.h"


namespace rho {
class CHtmlToGraphFactory: public CHtmlToGraphFactoryBase
{
private:
    static rhoruntime::IHtmlToGraphFactoryImpl^ _impl;
public:
    static void setImpl(rhoruntime::IHtmlToGraphFactoryImpl^ impl) { _impl = impl; }
    ~CHtmlToGraphFactory(){}
    virtual IHtmlToGraphSingleton* createModuleSingleton();
    virtual IHtmlToGraph* createModuleByID(const rho::String& strID);
};

}
