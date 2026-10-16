package com.rho.pdfgen;

import com.rhomobile.rhodes.api.RhoApiFactory;

public class PdfgenFactory
        extends RhoApiFactory< Pdfgen, PdfgenSingleton>
        implements IPdfgenFactory {

    @Override
    protected PdfgenSingleton createSingleton() {
        return new PdfgenSingleton(this);
    }

    @Override
    protected Pdfgen createApiObject(String id) {
        return new Pdfgen(id);
    }
}
