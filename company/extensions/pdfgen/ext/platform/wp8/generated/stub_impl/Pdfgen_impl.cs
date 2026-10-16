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
    public class Pdfgen : PdfgenBase
    {
        public Pdfgen()
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

        public override void generatePDF(string htmlContent, string targetFilePath, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void mergePDF(string listOfPaths, string targetFilePath, IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class PdfgenSingleton : PdfgenSingletonBase
    {
        public PdfgenSingleton()
        {
            // initialize singleton instance in C# here
        }

        public override void enumerate(IMethodResult oResult)
        {
            // implement this method in C# here
        }
    }

    public class PdfgenFactory : PdfgenFactoryBase
    {
    }
}

}
