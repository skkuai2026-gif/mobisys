package com.rho.documentpicker;

import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;

import com.rhomobile.rhodes.api.RhoApiDefaultId;

public abstract class DocumentPickerSingletonBase 
    extends RhoApiDefaultId<IDocumentPicker, IDocumentPickerFactory>  {

    public DocumentPickerSingletonBase(IDocumentPickerFactory factory) {
        super(factory);
    } 

    public static class enumerateTask implements Runnable {
        private IDocumentPickerSingleton mApiSingleton; 
        private IMethodResult mResult;

        public enumerateTask(IDocumentPickerSingleton obj,         
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
