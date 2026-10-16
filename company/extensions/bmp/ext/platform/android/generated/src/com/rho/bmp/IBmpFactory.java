package com.rho.bmp;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IBmpFactory
    extends IRhoApiFactory<IBmp>,
            IRhoApiSingletonFactory<IBmpSingleton> {

    @Override
    IBmpSingleton getApiSingleton();

    @Override
    IBmp getApiObject(String id);

}
