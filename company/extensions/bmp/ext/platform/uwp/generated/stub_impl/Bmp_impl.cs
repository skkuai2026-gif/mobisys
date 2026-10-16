using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;

namespace rho {

namespace BmpImpl
{
    public class Bmp : BmpBase
    {
        public Bmp(string id) : base(id)
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

        public override void sensorDataFetch(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class BmpSingleton : BmpSingletonBase
    {
        public BmpSingleton()
        {
            // initialize singleton instance in C# here
        }

        public override void enumerate(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class BmpFactory : BmpFactoryBase
    {
    }
}

}
