// ApptrackingRuntime.cpp
#include "ApptrackingRuntime.h"
#include "ApptrackingFactory.h"
#include "Apptracking_impl.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"

using namespace Platform;
using namespace rho::apiGenerator;

using namespace rho;

namespace rhoruntime
{

ApptrackingRuntimeComponent::ApptrackingRuntimeComponent(IApptrackingImpl^ impl):
    _impl(impl), _cppImpl(0)
{
    // TODO: implement runtime component constructor
}

int64 ApptrackingRuntimeComponent::getCppImpl()
{
    if (_cppImpl == 0)
    {
        _cppImpl = _impl->getNativeImpl();
    }
    return _cppImpl;
}

ApptrackingSingletonComponent::ApptrackingSingletonComponent(IApptrackingSingletonImpl^ impl):
    _impl(impl)
{
    // TODO: implement singleton component constructor
}

void ApptrackingSingletonComponent::enumerate(IMethodResult^ oResult)
{
    //((CApptrackingImpl*)getCppImpl())->enumerate(*(CMethodResult*)(oResult->getNative()));
}

void ApptrackingRuntimeComponent::getProperty(Platform::String^ propertyName, IMethodResult^ oResult)
{
    ((CApptrackingImpl*)getCppImpl())->getProperty(rho::common::convertStringAFromWP8(propertyName), *(CMethodResult*)(oResult->getNative()));
}

void ApptrackingRuntimeComponent::getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult)
{
    ((CApptrackingImpl*)getCppImpl())->getProperties(rho::common::convertArrayFromWP8(arrayofNames), *(CMethodResult*)(oResult->getNative()));
}

void ApptrackingRuntimeComponent::getAllProperties(IMethodResult^ oResult)
{
    ((CApptrackingImpl*)getCppImpl())->getAllProperties(*(CMethodResult*)(oResult->getNative()));
}

void ApptrackingRuntimeComponent::setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult)
{
    ((CApptrackingImpl*)getCppImpl())->setProperty(rho::common::convertStringAFromWP8(propertyName), rho::common::convertStringAFromWP8(propertyValue), *(CMethodResult*)(oResult->getNative()));
}

void ApptrackingRuntimeComponent::setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult)
{
    ((CApptrackingImpl*)getCppImpl())->setProperties(rho::common::convertHashFromWP8(propertyMap), *(CMethodResult*)(oResult->getNative()));
}

void ApptrackingFactoryComponent::setImpl(IApptrackingFactoryImpl^ impl)
{
    CApptrackingFactory::setImpl(impl);
}

}