package com.rho.bgservice;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class BGServiceSingletonBase 
    extends RhoApiDefaultId<IBGService, IBGServiceFactory>  {

    public BGServiceSingletonBase(IBGServiceFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IBGServiceSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IBGServiceSingleton obj,         
                IMethodResult result) {
            this.mApiSingleton = obj;         
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiSingleton.enumerate( mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    
}
