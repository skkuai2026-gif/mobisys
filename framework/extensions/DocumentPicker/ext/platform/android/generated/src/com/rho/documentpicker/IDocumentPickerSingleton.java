package com.rho.documentpicker;



import java.util.Map;
import java.util.List;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.IRhoApiDefaultId;


public interface IDocumentPickerSingleton
       extends IRhoApiDefaultId  {



  // hash keys used in properties and parameters

    static final String HK_FILE_PATH = "filePath"; 
    static final String HK_STATUS = "status"; 
    static final String PROPERTY_SIMPLE_STRING_PROPERTY = "simpleStringProperty"; 


    void enumerate(IMethodResult result); 

}
