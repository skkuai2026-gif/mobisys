// PdfgenRuntime.cpp
#include "PdfgenRuntime.h"
#include "PdfgenFactory.h"
#include "Pdfgen_impl.h"
#include "../../wp8/rhoruntime/common/RhoConvertWP8.h"

using namespace Platform;
using namespace rho::apiGenerator;

using namespace rho;

namespace rhoruntime
{

PdfgenRuntimeComponent::PdfgenRuntimeComponent(IPdfgenImpl^ impl):
    _impl(impl), _cppImpl(0)
{
    // TODO: implement runtime component constructor
}

int64 PdfgenRuntimeComponent::getCppImpl()
{
    if (_cppImpl == 0)
    {
        _cppImpl = _impl->getNativeImpl();
    }
    return _cppImpl;
}

PdfgenSingletonComponent::PdfgenSingletonComponent(IPdfgenSingletonImpl^ impl):
    _impl(impl)
{
    // TODO: implement singleton component constructor
}

void PdfgenSingletonComponent::enumerate(IMethodResult^ oResult)
{
    //((CPdfgenImpl*)getCppImpl())->enumerate(*(CMethodResult*)(oResult->getNative()));
}

void PdfgenRuntimeComponent::getProperty(Platform::String^ propertyName, IMethodResult^ oResult)
{
    ((CPdfgenImpl*)getCppImpl())->getProperty(rho::common::convertStringAFromWP8(propertyName), *(CMethodResult*)(oResult->getNative()));
}

void PdfgenRuntimeComponent::getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult)
{
    ((CPdfgenImpl*)getCppImpl())->getProperties(rho::common::convertArrayFromWP8(arrayofNames), *(CMethodResult*)(oResult->getNative()));
}

void PdfgenRuntimeComponent::getAllProperties(IMethodResult^ oResult)
{
    ((CPdfgenImpl*)getCppImpl())->getAllProperties(*(CMethodResult*)(oResult->getNative()));
}

void PdfgenRuntimeComponent::setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult)
{
    ((CPdfgenImpl*)getCppImpl())->setProperty(rho::common::convertStringAFromWP8(propertyName), rho::common::convertStringAFromWP8(propertyValue), *(CMethodResult*)(oResult->getNative()));
}

void PdfgenRuntimeComponent::setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult)
{
    ((CPdfgenImpl*)getCppImpl())->setProperties(rho::common::convertHashFromWP8(propertyMap), *(CMethodResult*)(oResult->getNative()));
}

void PdfgenFactoryComponent::setImpl(IPdfgenFactoryImpl^ impl)
{
    CPdfgenFactory::setImpl(impl);
}

}