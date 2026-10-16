package com.rho.fingerprint;

import com.rhomobile.rhodes.api.RhoApiFactory;

public class FingerprintFactory
        extends RhoApiFactory< Fingerprint, FingerprintSingleton>
        implements IFingerprintFactory {

    @Override
    protected FingerprintSingleton createSingleton() {
        return new FingerprintSingleton(this);
    }

    @Override
    protected Fingerprint createApiObject(String id) {
        return new Fingerprint(id);
    }
}
