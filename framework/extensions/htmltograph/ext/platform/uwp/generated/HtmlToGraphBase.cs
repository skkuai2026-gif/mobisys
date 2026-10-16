using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;
using rhodes;

namespace rho {

namespace HtmlToGraphImpl
{
    abstract public class HtmlToGraphBase : IHtmlToGraphImpl
    {
        protected string _strID = "1";
        protected long _nativeImpl = 0;
        protected CoreDispatcher dispatcher = null;
        protected HtmlToGraphRuntimeComponent _runtime;

        public HtmlToGraphBase(string id)
        {
            _strID = id;
            _runtime = new HtmlToGraphRuntimeComponent(this);
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
        abstract public void getPlatformName(IMethodResult oResult);
        abstract public void getGraphIOS(string htmlString, IMethodResult oResult);
        abstract public void getGraphAndroid(string htmlString, IMethodResult oResult);
        abstract public void calcSumm(int a, int b, IMethodResult oResult);
        abstract public void joinStrings(string a, string b, IMethodResult oResult);
    }

    abstract public class HtmlToGraphSingletonBase : IHtmlToGraphSingletonImpl
    {

        protected SortedDictionary<string, HtmlToGraphBase> keeper = new SortedDictionary<string, HtmlToGraphBase>();

        public IHtmlToGraphImpl getHtmlToGraphByID(string id)
        {
            if (keeper.ContainsKey(id))
            {
                return keeper[id];
            }
            else
            {
                HtmlToGraphBase impl = new HtmlToGraph(id);
                keeper.Add(id, impl);
                return impl;
            }
        }

        protected HtmlToGraphSingletonComponent _runtime;

        public HtmlToGraphSingletonBase()
        {
              try{dispatcher = MainPage.getDispatcher();
              }catch(Exception e){deb("Can't get access to dispatcher");}
              _runtime = new HtmlToGraphSingletonComponent(this);
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

    public class HtmlToGraphFactoryBase : IHtmlToGraphFactoryImpl
    {
        protected static HtmlToGraphSingleton instance = null;
        public virtual IHtmlToGraphImpl getImpl(string id) {
            getSingletonImpl();
            return instance.getHtmlToGraphByID(id);
        }
        public IHtmlToGraphSingletonImpl getSingletonImpl() {
            if (instance == null){instance = new HtmlToGraphSingleton();}
            return instance;
          
        }
    }
}

}
