package com.rho.pdfgen;



import java.util.Map;
import java.util.List;

import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.IRhoApiObject;

import com.rhomobile.rhodes.api.IRhoApiPropertyBag;

public interface IPdfgen extends IRhoApiObject, IRhoApiPropertyBag {

    void getSimpleStringProperty(IMethodResult result);
    void setSimpleStringProperty(String simpleStringProperty, IMethodResult result);
    void generateAndroidPDF(String inputHTMLFileName, String orientation, String isSinglePDFRequired, String password, IMethodResult result);
    void generateAndroidPDFCharts(String chartJSON, String chartOutputFileName, String chartType, IMethodResult result);
    void generateIOSPDF(String htmlContent, String targetFilePath, IMethodResult result);
    void mergeIOSPDF(String listOfPaths, String targetFilePath, String masterPassword, String password, IMethodResult result);
};
