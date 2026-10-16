package com.rho.fingerprint;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class FingerprintSingletonBase 
    extends RhoApiDefaultId<IFingerprint, IFingerprintFactory>  {

    public FingerprintSingletonBase(IFingerprintFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IFingerprintSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IFingerprintSingleton obj,         
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
