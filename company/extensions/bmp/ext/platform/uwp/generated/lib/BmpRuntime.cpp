// BmpRuntime.cpp
#include "BmpRuntime.h"
#include "BmpFactory.h"
#include "Bmp_impl.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"

using namespace Platform;
using namespace rho::apiGenerator;

using namespace rho;

namespace rhoruntime
{

BmpRuntimeComponent::BmpRuntimeComponent(IBmpImpl^ impl):
    _impl(impl), _cppImpl(0)
{
    // TODO: implement runtime component constructor
}

int64 BmpRuntimeComponent::getCppImpl()
{
    if (_cppImpl == 0)
    {
        _cppImpl = _impl->getNativeImpl();
    }
    return _cppImpl;
}

BmpSingletonComponent::BmpSingletonComponent(IBmpSingletonImpl^ impl):
    _impl(impl)
{
    // TODO: implement singleton component constructor
}

void BmpSingletonComponent::enumerate(IMethodResult^ oResult)
{
    //((CBmpImpl*)getCppImpl())->enumerate(*(CMethodResult*)(oResult->getNative()));
}

void BmpRuntimeComponent::getProperty(Platform::String^ propertyName, IMethodResult^ oResult)
{
    ((CBmpImpl*)getCppImpl())->getProperty(rho::common::convertStringAFromWP8(propertyName), *(CMethodResult*)(oResult->getNative()));
}

void BmpRuntimeComponent::getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult)
{
    ((CBmpImpl*)getCppImpl())->getProperties(rho::common::convertArrayFromWP8(arrayofNames), *(CMethodResult*)(oResult->getNative()));
}

void BmpRuntimeComponent::getAllProperties(IMethodResult^ oResult)
{
    ((CBmpImpl*)getCppImpl())->getAllProperties(*(CMethodResult*)(oResult->getNative()));
}

void BmpRuntimeComponent::setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult)
{
    ((CBmpImpl*)getCppImpl())->setProperty(rho::common::convertStringAFromWP8(propertyName), rho::common::convertStringAFromWP8(propertyValue), *(CMethodResult*)(oResult->getNative()));
}

void BmpRuntimeComponent::setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult)
{
    ((CBmpImpl*)getCppImpl())->setProperties(rho::common::convertHashFromWP8(propertyMap), *(CMethodResult*)(oResult->getNative()));
}

void BmpFactoryComponent::setImpl(IBmpFactoryImpl^ impl)
{
    CBmpFactory::setImpl(impl);
}

}