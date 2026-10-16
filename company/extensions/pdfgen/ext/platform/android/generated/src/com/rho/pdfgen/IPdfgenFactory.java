package com.rho.pdfgen;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IPdfgenFactory
    extends IRhoApiFactory<IPdfgen>,
            IRhoApiSingletonFactory<IPdfgenSingleton> {

    @Override
    IPdfgenSingleton getApiSingleton();

    @Override
    IPdfgen getApiObject(String id);

}
