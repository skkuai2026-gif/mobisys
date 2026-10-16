package com.rho.apptracking;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class ApptrackingSingletonBase 
    extends RhoApiDefaultId<IApptracking, IApptrackingFactory>  {

    public ApptrackingSingletonBase(IApptrackingFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IApptrackingSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IApptrackingSingleton obj,         
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
