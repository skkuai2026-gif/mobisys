// DocumentPickerRuntime.cpp
#include "DocumentPickerRuntime.h"
#include "DocumentPickerFactory.h"
#include "DocumentPicker_impl.h"
#include "../../wp8/rhoruntime/common/RhoConvertWP8.h"

using namespace Platform;
using namespace rho::apiGenerator;

using namespace rho;

namespace rhoruntime
{

DocumentPickerRuntimeComponent::DocumentPickerRuntimeComponent(IDocumentPickerImpl^ impl):
    _impl(impl), _cppImpl(0)
{
    // TODO: implement runtime component constructor
}

int64 DocumentPickerRuntimeComponent::getCppImpl()
{
    if (_cppImpl == 0)
    {
        _cppImpl = _impl->getNativeImpl();
    }
    return _cppImpl;
}

DocumentPickerSingletonComponent::DocumentPickerSingletonComponent(IDocumentPickerSingletonImpl^ impl):
    _impl(impl)
{
    // TODO: implement singleton component constructor
}

void DocumentPickerSingletonComponent::enumerate(IMethodResult^ oResult)
{
    //((CDocumentPickerImpl*)getCppImpl())->enumerate(*(CMethodResult*)(oResult->getNative()));
}

void DocumentPickerRuntimeComponent::getProperty(Platform::String^ propertyName, IMethodResult^ oResult)
{
    ((CDocumentPickerImpl*)getCppImpl())->getProperty(rho::common::convertStringAFromWP8(propertyName), *(CMethodResult*)(oResult->getNative()));
}

void DocumentPickerRuntimeComponent::getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult)
{
    ((CDocumentPickerImpl*)getCppImpl())->getProperties(rho::common::convertArrayFromWP8(arrayofNames), *(CMethodResult*)(oResult->getNative()));
}

void DocumentPickerRuntimeComponent::getAllProperties(IMethodResult^ oResult)
{
    ((CDocumentPickerImpl*)getCppImpl())->getAllProperties(*(CMethodResult*)(oResult->getNative()));
}

void DocumentPickerRuntimeComponent::setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult)
{
    ((CDocumentPickerImpl*)getCppImpl())->setProperty(rho::common::convertStringAFromWP8(propertyName), rho::common::convertStringAFromWP8(propertyValue), *(CMethodResult*)(oResult->getNative()));
}

void DocumentPickerRuntimeComponent::setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult)
{
    ((CDocumentPickerImpl*)getCppImpl())->setProperties(rho::common::convertHashFromWP8(propertyMap), *(CMethodResult*)(oResult->getNative()));
}

void DocumentPickerFactoryComponent::setImpl(IDocumentPickerFactoryImpl^ impl)
{
    CDocumentPickerFactory::setImpl(impl);
}

}