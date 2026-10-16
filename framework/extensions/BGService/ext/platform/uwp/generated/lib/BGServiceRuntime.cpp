// BGServiceRuntime.cpp
#include "BGServiceRuntime.h"
#include "BGServiceFactory.h"
#include "BGService_impl.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"

using namespace Platform;
using namespace rho::apiGenerator;

using namespace rho;

namespace rhoruntime
{

BGServiceRuntimeComponent::BGServiceRuntimeComponent(IBGServiceImpl^ impl):
    _impl(impl), _cppImpl(0)
{
    // TODO: implement runtime component constructor
}

int64 BGServiceRuntimeComponent::getCppImpl()
{
    if (_cppImpl == 0)
    {
        _cppImpl = _impl->getNativeImpl();
    }
    return _cppImpl;
}

BGServiceSingletonComponent::BGServiceSingletonComponent(IBGServiceSingletonImpl^ impl):
    _impl(impl)
{
    // TODO: implement singleton component constructor
}

void BGServiceSingletonComponent::enumerate(IMethodResult^ oResult)
{
    //((CBGServiceImpl*)getCppImpl())->enumerate(*(CMethodResult*)(oResult->getNative()));
}

void BGServiceRuntimeComponent::getProperty(Platform::String^ propertyName, IMethodResult^ oResult)
{
    ((CBGServiceImpl*)getCppImpl())->getProperty(rho::common::convertStringAFromWP8(propertyName), *(CMethodResult*)(oResult->getNative()));
}

void BGServiceRuntimeComponent::getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult)
{
    ((CBGServiceImpl*)getCppImpl())->getProperties(rho::common::convertArrayFromWP8(arrayofNames), *(CMethodResult*)(oResult->getNative()));
}

void BGServiceRuntimeComponent::getAllProperties(IMethodResult^ oResult)
{
    ((CBGServiceImpl*)getCppImpl())->getAllProperties(*(CMethodResult*)(oResult->getNative()));
}

void BGServiceRuntimeComponent::setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult)
{
    ((CBGServiceImpl*)getCppImpl())->setProperty(rho::common::convertStringAFromWP8(propertyName), rho::common::convertStringAFromWP8(propertyValue), *(CMethodResult*)(oResult->getNative()));
}

void BGServiceRuntimeComponent::setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult)
{
    ((CBGServiceImpl*)getCppImpl())->setProperties(rho::common::convertHashFromWP8(propertyMap), *(CMethodResult*)(oResult->getNative()));
}

void BGServiceFactoryComponent::setImpl(IBGServiceFactoryImpl^ impl)
{
    CBGServiceFactory::setImpl(impl);
}

}