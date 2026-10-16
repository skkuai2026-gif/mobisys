#pragma once

#include "../../../../shared/generated/cpp/IHtmlToGraph.h"
#include "api_generator/uwp/IMethodResult.h"

namespace rhoruntime
{
    public interface class IHtmlToGraphImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void getPlatformName(IMethodResult^ oResult);
        void getGraphIOS(Platform::String^ htmlString, IMethodResult^ oResult);
        void getGraphAndroid(Platform::String^ htmlString, IMethodResult^ oResult);
        void calcSumm(int a, int b, IMethodResult^ oResult);
        void joinStrings(Platform::String^ a, Platform::String^ b, IMethodResult^ oResult);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    };

    public interface class IHtmlToGraphSingletonImpl
    {
    public:
        void enumerate(IMethodResult^ oResult);
    };
    public interface class IHtmlToGraphFactoryImpl
    {
    public:
        IHtmlToGraphImpl^ getImpl(Platform::String^ id);
        IHtmlToGraphSingletonImpl^ getSingletonImpl();
    };

    public ref class HtmlToGraphRuntimeComponent sealed
    {
    public:
        HtmlToGraphRuntimeComponent(IHtmlToGraphImpl^ impl);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    private:
        IHtmlToGraphImpl^ _impl;
        int64 _cppImpl;
        int64 getCppImpl();
    };

    public ref class HtmlToGraphSingletonComponent sealed: public IHtmlToGraphSingletonImpl
    {
    public:
        HtmlToGraphSingletonComponent(IHtmlToGraphSingletonImpl^ impl);
        virtual void enumerate(IMethodResult^ oResult);
    private:
        IHtmlToGraphSingletonImpl^ _impl;
    };

    public ref class HtmlToGraphFactoryComponent sealed
    {
    public:
        static void setImpl(IHtmlToGraphFactoryImpl^ impl);
    };
}
