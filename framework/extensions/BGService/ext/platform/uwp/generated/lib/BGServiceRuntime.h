#pragma once

#include "../../../../shared/generated/cpp/IBGService.h"
#include "api_generator/uwp/IMethodResult.h"

namespace rhoruntime
{
    public interface class IBGServiceImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void startBackgroundService(Platform::String^ bgServiceRubyFunc, IMethodResult^ oResult);
        void stopBackgroundService(IMethodResult^ oResult);
        void checkBackgroundServiceStatus(IMethodResult^ oResult);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    };

    public interface class IBGServiceSingletonImpl
    {
    public:
        void enumerate(IMethodResult^ oResult);
    };
    public interface class IBGServiceFactoryImpl
    {
    public:
        IBGServiceImpl^ getImpl(Platform::String^ id);
        IBGServiceSingletonImpl^ getSingletonImpl();
    };

    public ref class BGServiceRuntimeComponent sealed
    {
    public:
        BGServiceRuntimeComponent(IBGServiceImpl^ impl);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    private:
        IBGServiceImpl^ _impl;
        int64 _cppImpl;
        int64 getCppImpl();
    };

    public ref class BGServiceSingletonComponent sealed: public IBGServiceSingletonImpl
    {
    public:
        BGServiceSingletonComponent(IBGServiceSingletonImpl^ impl);
        virtual void enumerate(IMethodResult^ oResult);
    private:
        IBGServiceSingletonImpl^ _impl;
    };

    public ref class BGServiceFactoryComponent sealed
    {
    public:
        static void setImpl(IBGServiceFactoryImpl^ impl);
    };
}
