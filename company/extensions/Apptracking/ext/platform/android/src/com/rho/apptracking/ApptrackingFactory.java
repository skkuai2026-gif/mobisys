package com.rho.apptracking;

import com.rhomobile.rhodes.api.RhoApiFactory;

public class ApptrackingFactory
        extends RhoApiFactory< Apptracking, ApptrackingSingleton>
        implements IApptrackingFactory {

    @Override
    protected ApptrackingSingleton createSingleton() {
        return new ApptrackingSingleton(this);
    }

    @Override
    protected Apptracking createApiObject(String id) {
        return new Apptracking(id);
    }
}
