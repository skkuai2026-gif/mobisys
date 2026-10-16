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
    public class DocumentPicker : DocumentPickerBase
    {
        public DocumentPicker()
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
