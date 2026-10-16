package com.rho.documentpicker;

import com.rhomobile.rhodes.api.IRhoApiFactory;
import com.rhomobile.rhodes.api.IRhoApiSingletonFactory;

public interface IDocumentPickerFactory
    extends IRhoApiFactory<IDocumentPicker>,
            IRhoApiSingletonFactory<IDocumentPickerSingleton> {

    @Override
    IDocumentPickerSingleton getApiSingleton();

    @Override
    IDocumentPicker getApiObject(String id);

}
