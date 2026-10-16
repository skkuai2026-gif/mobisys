package com.rho.htmltograph;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IHtmlToGraphFactory
    extends IRhoApiFactory<IHtmlToGraph>,
            IRhoApiSingletonFactory<IHtmlToGraphSingleton> {

    @Override
    IHtmlToGraphSingleton getApiSingleton();

    @Override
    IHtmlToGraph getApiObject(String id);

}
