#pragma once

#include "../../../../shared/generated/cpp/IPdfgen.h"
#include "api_generator/uwp/IMethodResult.h"

namespace rhoruntime
{
    public interface class IPdfgenImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void generateAndroidPDF(Platform::String^ inputHTMLFileName, Platform::String^ orientation, Platform::String^ isSinglePDFRequired, Platform::String^ password, IMethodResult^ oResult);
        void generateAndroidPDFCharts(Platform::String^ chartJSON, Platform::String^ chartOutputFileName, Platform::String^ chartType, IMethodResult^ oResult);
        void generateIOSPDF(Platform::String^ htmlContent, Platform::String^ targetFilePath, IMethodResult^ oResult);
        void mergeIOSPDF(Platform::String^ listOfPaths, Platform::String^ targetFilePath, Platform::String^ masterPassword, Platform::String^ password, IMethodResult^ oResult);
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
        IPdfgenImpl^ getImpl(Platform::String^ id);
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
