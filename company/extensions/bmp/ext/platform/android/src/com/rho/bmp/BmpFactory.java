package com.rho.bmp;

import com.rhomobile.rhodes.api.RhoApiFactory;

public class BmpFactory
        extends RhoApiFactory< Bmp, BmpSingleton>
        implements IBmpFactory {

    @Override
    protected BmpSingleton createSingleton() {
        return new BmpSingleton(this);
    }

    @Override
    protected Bmp createApiObject(String id) {
        return new Bmp(id);
    }
}
