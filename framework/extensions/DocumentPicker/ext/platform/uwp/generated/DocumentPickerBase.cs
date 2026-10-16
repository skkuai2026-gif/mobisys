using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;
using rhodes;

namespace rho {

namespace DocumentPickerImpl
{
    abstract public class DocumentPickerBase : IDocumentPickerImpl
    {
        protected string _strID = "1";
        protected long _nativeImpl = 0;
        protected CoreDispatcher dispatcher = null;
        protected DocumentPickerRuntimeComponent _runtime;

        public DocumentPickerBase(string id)
        {
            _strID = id;
            _runtime = new DocumentPickerRuntimeComponent(this);
            try{dispatcher = MainPage.getDispatcher();
            }catch(Exception e){deb("Can't get access to dispatcher");}
        }

        public static void deb(String s, [System.Runtime.CompilerServices.CallerMemberName] string memberName = "")
        {
            if (memberName.Length != 0) {memberName = memberName + " : ";}
            System.Diagnostics.Debug.WriteLine(memberName + s);
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

        public void dispatchInvoke(Action a)
        {
            if (dispatcher != null) {
              var ignore = dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
              {try{a();} catch (Exception ex) {System.Diagnostics.Debug.WriteLine("Invoke in UI Thread exception");} });
            }else{a();}
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

        protected SortedDictionary<string, DocumentPickerBase> keeper = new SortedDictionary<string, DocumentPickerBase>();

        public IDocumentPickerImpl getDocumentPickerByID(string id)
        {
            if (keeper.ContainsKey(id))
            {
                return keeper[id];
            }
            else
            {
                DocumentPickerBase impl = new DocumentPicker(id);
                keeper.Add(id, impl);
                return impl;
            }
        }

        protected DocumentPickerSingletonComponent _runtime;

        public DocumentPickerSingletonBase()
        {
              try{dispatcher = MainPage.getDispatcher();
              }catch(Exception e){deb("Can't get access to dispatcher");}
              _runtime = new DocumentPickerSingletonComponent(this);
        }

        public static void deb(String s, [System.Runtime.CompilerServices.CallerMemberName] string memberName = "")
        {
            if (memberName.Length != 0) {memberName = memberName + " : ";}
            System.Diagnostics.Debug.WriteLine(memberName + s);
        }

        public void dispatchInvoke(Action a)
        {
            if (dispatcher != null) {
              var ignore = dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
              {try{a();} catch (Exception ex) {System.Diagnostics.Debug.WriteLine("Invoke in UI Thread exception");} });
            }else{a();}
        }
        protected CoreDispatcher dispatcher = null;


        abstract public void enumerate(IMethodResult oResult);
    }

    public class DocumentPickerFactoryBase : IDocumentPickerFactoryImpl
    {
        protected static DocumentPickerSingleton instance = null;
        public virtual IDocumentPickerImpl getImpl(string id) {
            getSingletonImpl();
            return instance.getDocumentPickerByID(id);
        }
        public IDocumentPickerSingletonImpl getSingletonImpl() {
            if (instance == null){instance = new DocumentPickerSingleton();}
            return instance;
          
        }
    }
}

}
