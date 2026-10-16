package com.rho.fingerprint;

public class FingerprintFactorySingleton {
    private static IFingerprintFactory mFactory;
    public static void setInstance(IFingerprintFactory factory) {
        mFactory = factory;
    }
    public static IFingerprintFactory getInstance() {
        return mFactory;
    }
}
