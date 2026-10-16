package com.rho.bgservice;

import com.rhomobile.rhodes.api.RhoApiFactory;

public class BGServiceFactory
        extends RhoApiFactory< BGService, BGServiceSingleton>
        implements IBGServiceFactory {

    @Override
    protected BGServiceSingleton createSingleton() {
        return new BGServiceSingleton(this);
    }

    @Override
    protected BGService createApiObject(String id) {
        return new BGService(id);
    }
}
