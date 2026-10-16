#pragma once

#include "../../../../shared/generated/cpp/IBmp.h"
#include "api_generator/uwp/IMethodResult.h"

namespace rhoruntime
{
    public interface class IBmpImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void sensorDataFetch(IMethodResult^ oResult);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    };

    public interface class IBmpSingletonImpl
    {
    public:
        void enumerate(IMethodResult^ oResult);
    };
    public interface class IBmpFactoryImpl
    {
    public:
        IBmpImpl^ getImpl(Platform::String^ id);
        IBmpSingletonImpl^ getSingletonImpl();
    };

    public ref class BmpRuntimeComponent sealed
    {
    public:
        BmpRuntimeComponent(IBmpImpl^ impl);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    private:
        IBmpImpl^ _impl;
        int64 _cppImpl;
        int64 getCppImpl();
    };

    public ref class BmpSingletonComponent sealed: public IBmpSingletonImpl
    {
    public:
        BmpSingletonComponent(IBmpSingletonImpl^ impl);
        virtual void enumerate(IMethodResult^ oResult);
    private:
        IBmpSingletonImpl^ _impl;
    };

    public ref class BmpFactoryComponent sealed
    {
    public:
        static void setImpl(IBmpFactoryImpl^ impl);
    };
}
