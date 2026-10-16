using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;

namespace rho {

namespace ApptrackingImpl
{
    public class Apptracking : ApptrackingBase
    {
        public Apptracking(string id) : base(id)
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

        public override void requestAppTrackingPermission(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class ApptrackingSingleton : ApptrackingSingletonBase
    {
        public ApptrackingSingleton()
        {
            // initialize singleton instance in C# here
        }

        public override void enumerate(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class ApptrackingFactory : ApptrackingFactoryBase
    {
    }
}

}
