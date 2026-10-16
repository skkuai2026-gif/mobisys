package com.rho.fingerprint;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IFingerprintFactory
    extends IRhoApiFactory<IFingerprint>,
            IRhoApiSingletonFactory<IFingerprintSingleton> {

    @Override
    IFingerprintSingleton getApiSingleton();

    @Override
    IFingerprint getApiObject(String id);

}
