package com.rho.htmltograph;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class HtmlToGraphSingletonBase 
    extends RhoApiDefaultId<IHtmlToGraph, IHtmlToGraphFactory>  {

    public HtmlToGraphSingletonBase(IHtmlToGraphFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IHtmlToGraphSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IHtmlToGraphSingleton obj,         
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
