#pragma once

#include "../../../../shared/generated/cpp/DocumentPickerBase.h"
#include "DocumentPickerRuntime.h"


namespace rho {
class CDocumentPickerFactory: public CDocumentPickerFactoryBase
{
private:
    static rhoruntime::IDocumentPickerFactoryImpl^ _impl;
public:
    static void setImpl(rhoruntime::IDocumentPickerFactoryImpl^ impl) { _impl = impl; }
    ~CDocumentPickerFactory(){}
    virtual IDocumentPickerSingleton* createModuleSingleton();
    virtual IDocumentPicker* createModuleByID(const rho::String& strID);
};

}
