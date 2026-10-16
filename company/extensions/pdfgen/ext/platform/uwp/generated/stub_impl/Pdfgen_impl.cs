using System;
using System.Collections.Generic;
using System.Net;
using Windows.UI.Core;
using System.Threading.Tasks;
using rhoruntime;

namespace rho {

namespace PdfgenImpl
{
    public class Pdfgen : PdfgenBase
    {
        public Pdfgen(string id) : base(id)
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

        public override void generateAndroidPDF(string inputHTMLFileName, string orientation, string isSinglePDFRequired, string password, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void generateAndroidPDFCharts(string chartJSON, string chartOutputFileName, string chartType, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void generateIOSPDF(string htmlContent, string targetFilePath, IMethodResult oResult)
        {
            // implement this method in C# here
        }

        public override void mergeIOSPDF(string listOfPaths, string targetFilePath, string masterPassword, string password, IMethodResult oResult)
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
