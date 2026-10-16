#pragma once

#include "../../../../shared/generated/cpp/IApptracking.h"
#include "api_generator/uwp/IMethodResult.h"

namespace rhoruntime
{
    public interface class IApptrackingImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void requestAppTrackingPermission(IMethodResult^ oResult);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    };

    public interface class IApptrackingSingletonImpl
    {
    public:
        void enumerate(IMethodResult^ oResult);
    };
    public interface class IApptrackingFactoryImpl
    {
    public:
        IApptrackingImpl^ getImpl(Platform::String^ id);
        IApptrackingSingletonImpl^ getSingletonImpl();
    };

    public ref class ApptrackingRuntimeComponent sealed
    {
    public:
        ApptrackingRuntimeComponent(IApptrackingImpl^ impl);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    private:
        IApptrackingImpl^ _impl;
        int64 _cppImpl;
        int64 getCppImpl();
    };

    public ref class ApptrackingSingletonComponent sealed: public IApptrackingSingletonImpl
    {
    public:
        ApptrackingSingletonComponent(IApptrackingSingletonImpl^ impl);
        virtual void enumerate(IMethodResult^ oResult);
    private:
        IApptrackingSingletonImpl^ _impl;
    };

    public ref class ApptrackingFactoryComponent sealed
    {
    public:
        static void setImpl(IApptrackingFactoryImpl^ impl);
    };
}
