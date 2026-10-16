using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;

namespace rho {

namespace DocumentPickerImpl
{
    public class DocumentPicker : DocumentPickerBase
    {
        public DocumentPicker(string id) : base(id)
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

        public override void pickDocument(string supportedExtensionList, IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class DocumentPickerSingleton : DocumentPickerSingletonBase
    {
        public DocumentPickerSingleton()
        {
            // initialize singleton instance in C# here
        }

        public override void enumerate(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class DocumentPickerFactory : DocumentPickerFactoryBase
    {
    }
}

}
