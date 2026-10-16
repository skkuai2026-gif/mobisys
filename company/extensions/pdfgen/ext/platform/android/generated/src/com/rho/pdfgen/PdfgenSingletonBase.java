package com.rho.pdfgen;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class PdfgenSingletonBase 
    extends RhoApiDefaultId<IPdfgen, IPdfgenFactory>  {

    public PdfgenSingletonBase(IPdfgenFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IPdfgenSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IPdfgenSingleton obj,         
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
