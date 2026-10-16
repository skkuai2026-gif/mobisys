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

namespace PdfgenImpl
{
    abstract public class PdfgenBase : IPdfgenImpl
    {
        protected string _strID = "1";
        protected long _nativeImpl = 0;
        protected PdfgenRuntimeComponent _runtime;

        public PdfgenBase()
        {
            _runtime = new PdfgenRuntimeComponent(this);
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
        abstract public void generatePDF(string htmlContent, string targetFilePath, IMethodResult oResult);
        abstract public void mergePDF(string listOfPaths, string targetFilePath, IMethodResult oResult);
    }

    abstract public class PdfgenSingletonBase : IPdfgenSingletonImpl
    {
        protected PdfgenSingletonComponent _runtime;

        public PdfgenSingletonBase()
        {
            _runtime = new PdfgenSingletonComponent(this);
        }

        abstract public void enumerate(IMethodResult oResult);
    }

    public class PdfgenFactoryBase : IPdfgenFactoryImpl
    {
        public virtual IPdfgenImpl getImpl() {
            return new Pdfgen();
        }
        public IPdfgenSingletonImpl getSingletonImpl() {
            return new PdfgenSingleton();
        }
    }
}

}
