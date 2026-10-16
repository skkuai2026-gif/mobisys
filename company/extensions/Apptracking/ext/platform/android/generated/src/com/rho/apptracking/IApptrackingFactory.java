package com.rho.apptracking;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IApptrackingFactory
    extends IRhoApiFactory<IApptracking>,
            IRhoApiSingletonFactory<IApptrackingSingleton> {

    @Override
    IApptrackingSingleton getApiSingleton();

    @Override
    IApptracking getApiObject(String id);

}
