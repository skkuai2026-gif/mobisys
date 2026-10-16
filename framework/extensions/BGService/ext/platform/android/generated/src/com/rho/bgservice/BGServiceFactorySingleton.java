package com.rho.bgservice;

public class BGServiceFactorySingleton {
    private static IBGServiceFactory mFactory;
    public static void setInstance(IBGServiceFactory factory) {
        mFactory = factory;
    }
    public static IBGServiceFactory getInstance() {
        return mFactory;
    }
}
