package com.rho.apptracking;

public class ApptrackingFactorySingleton {
    private static IApptrackingFactory mFactory;
    public static void setInstance(IApptrackingFactory factory) {
        mFactory = factory;
    }
    public static IApptrackingFactory getInstance() {
        return mFactory;
    }
}
