#pragma once

#include "../../../../shared/generated/cpp/IPdfgen.h"
#include "api_generator/wp8/IMethodResult.h"

namespace rhoruntime
{
    public interface class IPdfgenImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void generatePDF(Platform::String^ htmlContent, Platform::String^ targetFilePath, IMethodResult^ oResult);
        void mergePDF(Platform::String^ listOfPaths, Platform::String^ targetFilePath, IMethodResult^ oResult);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    };

    public interface class IPdfgenSingletonImpl
    {
    public:
        void enumerate(IMethodResult^ oResult);
    };
    public interface class IPdfgenFactoryImpl
    {
    public:
        IPdfgenImpl^ getImpl();
        IPdfgenSingletonImpl^ getSingletonImpl();
    };

    public ref class PdfgenRuntimeComponent sealed
    {
    public:
        PdfgenRuntimeComponent(IPdfgenImpl^ impl);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    private:
        IPdfgenImpl^ _impl;
        int64 _cppImpl;
        int64 getCppImpl();
    };

    public ref class PdfgenSingletonComponent sealed: public IPdfgenSingletonImpl
    {
    public:
        PdfgenSingletonComponent(IPdfgenSingletonImpl^ impl);
        virtual void enumerate(IMethodResult^ oResult);
    private:
        IPdfgenSingletonImpl^ _impl;
    };

    public ref class PdfgenFactoryComponent sealed
    {
    public:
        static void setImpl(IPdfgenFactoryImpl^ impl);
    };
}
