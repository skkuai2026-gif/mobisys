package com.rho.documentpicker;

import com.rhomobile.rhodes.api.RhoApiFactory;

public class DocumentPickerFactory
        extends RhoApiFactory< DocumentPicker, DocumentPickerSingleton>
        implements IDocumentPickerFactory {

    @Override
    protected DocumentPickerSingleton createSingleton() {
        return new DocumentPickerSingleton(this);
    }

    @Override
    protected DocumentPicker createApiObject(String id) {
        return new DocumentPicker(id);
    }
}
