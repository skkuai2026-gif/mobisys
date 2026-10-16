package com.rho.htmltograph;



import java.util.Map;
import java.util.List;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.IRhoApiDefaultId;


public interface IHtmlToGraphSingleton
       extends IRhoApiDefaultId  {



  // hash keys used in properties and parameters

    static final String HK_GRAPH_CONTENT = "graphContent"; 
    static final String HK_STATUS = "status"; 
    static final String PROPERTY_SIMPLE_STRING_PROPERTY = "simpleStringProperty"; 


    void enumerate(IMethodResult result); 

}
