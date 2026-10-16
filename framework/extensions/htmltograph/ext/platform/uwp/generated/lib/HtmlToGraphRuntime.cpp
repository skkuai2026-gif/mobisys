// HtmlToGraphRuntime.cpp
#include "HtmlToGraphRuntime.h"
#include "HtmlToGraphFactory.h"
#include "HtmlToGraph_impl.h"
#include "../../uwp/rhoruntime/common/RhoConvertWP8.h"

using namespace Platform;
using namespace rho::apiGenerator;

using namespace rho;

namespace rhoruntime
{

HtmlToGraphRuntimeComponent::HtmlToGraphRuntimeComponent(IHtmlToGraphImpl^ impl):
    _impl(impl), _cppImpl(0)
{
    // TODO: implement runtime component constructor
}

int64 HtmlToGraphRuntimeComponent::getCppImpl()
{
    if (_cppImpl == 0)
    {
        _cppImpl = _impl->getNativeImpl();
    }
    return _cppImpl;
}

HtmlToGraphSingletonComponent::HtmlToGraphSingletonComponent(IHtmlToGraphSingletonImpl^ impl):
    _impl(impl)
{
    // TODO: implement singleton component constructor
}

void HtmlToGraphSingletonComponent::enumerate(IMethodResult^ oResult)
{
    //((CHtmlToGraphImpl*)getCppImpl())->enumerate(*(CMethodResult*)(oResult->getNative()));
}

void HtmlToGraphRuntimeComponent::getProperty(Platform::String^ propertyName, IMethodResult^ oResult)
{
    ((CHtmlToGraphImpl*)getCppImpl())->getProperty(rho::common::convertStringAFromWP8(propertyName), *(CMethodResult*)(oResult->getNative()));
}

void HtmlToGraphRuntimeComponent::getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult)
{
    ((CHtmlToGraphImpl*)getCppImpl())->getProperties(rho::common::convertArrayFromWP8(arrayofNames), *(CMethodResult*)(oResult->getNative()));
}

void HtmlToGraphRuntimeComponent::getAllProperties(IMethodResult^ oResult)
{
    ((CHtmlToGraphImpl*)getCppImpl())->getAllProperties(*(CMethodResult*)(oResult->getNative()));
}

void HtmlToGraphRuntimeComponent::setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult)
{
    ((CHtmlToGraphImpl*)getCppImpl())->setProperty(rho::common::convertStringAFromWP8(propertyName), rho::common::convertStringAFromWP8(propertyValue), *(CMethodResult*)(oResult->getNative()));
}

void HtmlToGraphRuntimeComponent::setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult)
{
    ((CHtmlToGraphImpl*)getCppImpl())->setProperties(rho::common::convertHashFromWP8(propertyMap), *(CMethodResult*)(oResult->getNative()));
}

void HtmlToGraphFactoryComponent::setImpl(IHtmlToGraphFactoryImpl^ impl)
{
    CHtmlToGraphFactory::setImpl(impl);
}

}