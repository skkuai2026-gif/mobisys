package com.rho.pdfgen;

public class PdfgenFactorySingleton {
    private static IPdfgenFactory mFactory;
    public static void setInstance(IPdfgenFactory factory) {
        mFactory = factory;
    }
    public static IPdfgenFactory getInstance() {
        return mFactory;
    }
}
