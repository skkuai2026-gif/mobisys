#pragma once

#include "../../../../shared/generated/cpp/IDocumentPicker.h"
#include "api_generator/wp8/IMethodResult.h"

namespace rhoruntime
{
    public interface class IDocumentPickerImpl
    {
    public:
        int64 getNativeImpl();
        void setNativeImpl(Platform::String^ strID, int64 native);


        void getSimpleStringProperty(IMethodResult^ oResult);
        void setSimpleStringProperty(Platform::String^ simpleStringProperty, IMethodResult^ oResult);
        void pickDocument(Platform::String^ supportedExtensionList, IMethodResult^ oResult);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    };

    public interface class IDocumentPickerSingletonImpl
    {
    public:
        void enumerate(IMethodResult^ oResult);
    };
    public interface class IDocumentPickerFactoryImpl
    {
    public:
        IDocumentPickerImpl^ getImpl();
        IDocumentPickerSingletonImpl^ getSingletonImpl();
    };

    public ref class DocumentPickerRuntimeComponent sealed
    {
    public:
        DocumentPickerRuntimeComponent(IDocumentPickerImpl^ impl);
        void getProperty(Platform::String^ propertyName, IMethodResult^ oResult);
        void getProperties(Windows::Foundation::Collections::IVectorView<Platform::String^>^ arrayofNames, IMethodResult^ oResult);
        void getAllProperties(IMethodResult^ oResult);
        void setProperty(Platform::String^ propertyName, Platform::String^ propertyValue, IMethodResult^ oResult);
        void setProperties(Windows::Foundation::Collections::IMapView<Platform::String^, Platform::String^>^ propertyMap, IMethodResult^ oResult);
    private:
        IDocumentPickerImpl^ _impl;
        int64 _cppImpl;
        int64 getCppImpl();
    };

    public ref class DocumentPickerSingletonComponent sealed: public IDocumentPickerSingletonImpl
    {
    public:
        DocumentPickerSingletonComponent(IDocumentPickerSingletonImpl^ impl);
        virtual void enumerate(IMethodResult^ oResult);
    private:
        IDocumentPickerSingletonImpl^ _impl;
    };

    public ref class DocumentPickerFactoryComponent sealed
    {
    public:
        static void setImpl(IDocumentPickerFactoryImpl^ impl);
    };
}
