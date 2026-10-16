package com.rho.documentpicker;

public class DocumentPickerFactorySingleton {
    private static IDocumentPickerFactory mFactory;
    public static void setInstance(IDocumentPickerFactory factory) {
        mFactory = factory;
    }
    public static IDocumentPickerFactory getInstance() {
        return mFactory;
    }
}
