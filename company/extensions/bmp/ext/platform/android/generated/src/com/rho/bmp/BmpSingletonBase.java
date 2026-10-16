package com.rho.bmp;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class BmpSingletonBase 
    extends RhoApiDefaultId<IBmp, IBmpFactory>  {

    public BmpSingletonBase(IBmpFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IBmpSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IBmpSingleton obj,         
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
