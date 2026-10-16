package com.rho.htmltograph;

public class HtmlToGraphFactorySingleton {
    private static IHtmlToGraphFactory mFactory;
    public static void setInstance(IHtmlToGraphFactory factory) {
        mFactory = factory;
    }
    public static IHtmlToGraphFactory getInstance() {
        return mFactory;
    }
}
