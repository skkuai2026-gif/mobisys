using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;

namespace rho {

namespace HtmlToGraphImpl
{
    public class HtmlToGraph : HtmlToGraphBase
    {
        public HtmlToGraph(string id) : base(id)
        {
            // initialize class instance in C# here
        }

        public override void getSimpleStringProperty(IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void setSimpleStringProperty(string simpleStringProperty, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void getPlatformName(IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void getGraphIOS(string htmlString, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void getGraphAndroid(string htmlString, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void calcSumm(int a, int b, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void joinStrings(string a, string b, IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class HtmlToGraphSingleton : HtmlToGraphSingletonBase
    {
        public HtmlToGraphSingleton()
        {
            // initialize singleton instance in C# here
        }

        public override void enumerate(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class HtmlToGraphFactory : HtmlToGraphFactoryBase
    {
    }
}

}
