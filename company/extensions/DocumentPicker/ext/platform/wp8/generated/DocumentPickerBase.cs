using System;
using System.Collections.Generic;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using rhoruntime;

namespace rho {

namespace DocumentPickerImpl
{
    abstract public class DocumentPickerBase : IDocumentPickerImpl
    {
        protected string _strID = "1";
        protected long _nativeImpl = 0;
        protected DocumentPickerRuntimeComponent _runtime;

        public DocumentPickerBase()
        {
            _runtime = new DocumentPickerRuntimeComponent(this);
        }

        public long getNativeImpl()
        {
            return _nativeImpl;
        }

        public virtual void setNativeImpl(string strID, long native)
        {
            _strID = strID;
            _nativeImpl = native;
        }

        public void DispatchInvoke(Action a)
        {
            if (Deployment.Current.Dispatcher != null)
                Deployment.Current.Dispatcher.BeginInvoke(a);
            else
                a();
        }

        public void getProperty(string propertyName, IMethodResult oResult)
        {
            _runtime.getProperty(propertyName, oResult);
        }

        public void getProperties(IReadOnlyList<string> arrayofNames, IMethodResult oResult)
        {
            _runtime.getProperties(arrayofNames, oResult);
        }

        public void getAllProperties(IMethodResult oResult)
        {
            _runtime.getAllProperties(oResult);
        }

        public void setProperty(string propertyName, string propertyValue, IMethodResult oResult)
        {
            _runtime.setProperty(propertyName, propertyValue, oResult);
        }

        public void setProperties(IReadOnlyDictionary<string, string> propertyMap, IMethodResult oResult)
        {
            _runtime.setProperties(propertyMap, oResult);
        }

        abstract public void getSimpleStringProperty(IMethodResult oResult);
        abstract public void setSimpleStringProperty(string simpleStringProperty, IMethodResult oResult);
        abstract public void pickDocument(string supportedExtensionList, IMethodResult oResult);
    }

    abstract public class DocumentPickerSingletonBase : IDocumentPickerSingletonImpl
    {
        protected DocumentPickerSingletonComponent _runtime;

        public DocumentPickerSingletonBase()
        {
            _runtime = new DocumentPickerSingletonComponent(this);
        }

        abstract public void enumerate(IMethodResult oResult);
    }

    public class DocumentPickerFactoryBase : IDocumentPickerFactoryImpl
    {
        public virtual IDocumentPickerImpl getImpl() {
            return new DocumentPicker();
        }
        public IDocumentPickerSingletonImpl getSingletonImpl() {
            return new DocumentPickerSingleton();
        }
    }
}

}
