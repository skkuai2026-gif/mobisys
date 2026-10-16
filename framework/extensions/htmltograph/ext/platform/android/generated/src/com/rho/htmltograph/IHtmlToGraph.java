package com.rho.htmltograph;



import java.util.Map;
import java.util.List;

import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.IRhoApiObject;

import com.rhomobile.rhodes.api.IRhoApiPropertyBag;

public interface IHtmlToGraph extends IRhoApiObject, IRhoApiPropertyBag {

    void getSimpleStringProperty(IMethodResult result);
    void setSimpleStringProperty(String simpleStringProperty, IMethodResult result);
    void getPlatformName(IMethodResult result);
    void getGraphIOS(String htmlString, IMethodResult result);
    void getGraphAndroid(String htmlString, IMethodResult result);
    void calcSumm(int a, int b, IMethodResult result);
    void joinStrings(String a, String b, IMethodResult result);
};
