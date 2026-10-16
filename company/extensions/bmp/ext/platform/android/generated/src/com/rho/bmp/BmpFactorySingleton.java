package com.rho.bmp;

public class BmpFactorySingleton {
    private static IBmpFactory mFactory;
    public static void setInstance(IBmpFactory factory) {
        mFactory = factory;
    }
    public static IBmpFactory getInstance() {
        return mFactory;
    }
}
