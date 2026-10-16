package com.rho.fingerprint;



import java.util.Map;
import java.util.List;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.IRhoApiDefaultId;


public interface IFingerprintSingleton
       extends IRhoApiDefaultId  {



  // hash keys used in properties and parameters

    static final String HK_AUTH_STATUS = "authStatus"; 
    static final String HK_STATUS_MESSAGE = "statusMessage"; 
    static final String PROPERTY_SIMPLE_STRING_PROPERTY = "simpleStringProperty"; 


    void enumerate(IMethodResult result); 

}
