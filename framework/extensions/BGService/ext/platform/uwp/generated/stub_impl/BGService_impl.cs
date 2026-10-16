using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;

namespace rho {

namespace BGServiceImpl
{
    public class BGService : BGServiceBase
    {
        public BGService(string id) : base(id)
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

        public override void startBackgroundService(string bgServiceRubyFunc, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void stopBackgroundService(IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void checkBackgroundServiceStatus(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class BGServiceSingleton : BGServiceSingletonBase
    {
        public BGServiceSingleton()
        {
            // initialize singleton instance in C# here
        }

        public override void enumerate(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class BGServiceFactory : BGServiceFactoryBase
    {
    }
}

}
