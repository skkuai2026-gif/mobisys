package com.rho.bgservice;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IBGServiceFactory
    extends IRhoApiFactory<IBGService>,
            IRhoApiSingletonFactory<IBGServiceSingleton> {

    @Override
    IBGServiceSingleton getApiSingleton();

    @Override
    IBGService getApiObject(String id);

}
