package com.rho.pdfgen;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.RhoApiObject;

import com.rhomobile.rhodes.api.RhoApiPropertyBag; 

public class PdfgenBase extends RhoApiObject {

    private RhoApiPropertyBag mPropertyBag;
    public Map<String, String> getPropertiesMap() {
        return mPropertyBag.getPropertiesMap();
    }
    public PdfgenBase(String id) {
        super(id);

        mPropertyBag = new RhoApiPropertyBag(id);
    }

    public void getSimpleStringProperty(IMethodResult result) {
                     
        getProperty("simpleStringProperty", result);
    }

    public static class getSimpleStringPropertyTask implements Runnable {
        private IPdfgen mApiObject; 
        private IMethodResult mResult;

        public getSimpleStringPropertyTask(IPdfgen obj, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.getSimpleStringProperty(mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void setSimpleStringProperty(String simpleStringProperty, IMethodResult result) {
                    
        setProperty("simpleStringProperty", String.valueOf(simpleStringProperty), result);
    }

    public static class setSimpleStringPropertyTask implements Runnable {
        private IPdfgen mApiObject; 
        private String simpleStringProperty;
        private IMethodResult mResult;

        public setSimpleStringPropertyTask(IPdfgen obj, 
                String simpleStringProperty, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.simpleStringProperty = simpleStringProperty;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.setSimpleStringProperty(
                    simpleStringProperty, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }


    public static class generateAndroidPDFTask implements Runnable {
        private IPdfgen mApiObject; 
        private String inputHTMLFileName;
        private String orientation;
        private String isSinglePDFRequired;
        private String password;
        private IMethodResult mResult;

        public generateAndroidPDFTask(IPdfgen obj, 
                String inputHTMLFileName, 
                String orientation, 
                String isSinglePDFRequired, 
                String password, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.inputHTMLFileName = inputHTMLFileName;
            this.orientation = orientation;
            this.isSinglePDFRequired = isSinglePDFRequired;
            this.password = password;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.generateAndroidPDF(
                    inputHTMLFileName, 
                    orientation, 
                    isSinglePDFRequired, 
                    password, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }


    public static class generateAndroidPDFChartsTask implements Runnable {
        private IPdfgen mApiObject; 
        private String chartJSON;
        private String chartOutputFileName;
        private String chartType;
        private IMethodResult mResult;

        public generateAndroidPDFChartsTask(IPdfgen obj, 
                String chartJSON, 
                String chartOutputFileName, 
                String chartType, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.chartJSON = chartJSON;
            this.chartOutputFileName = chartOutputFileName;
            this.chartType = chartType;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.generateAndroidPDFCharts(
                    chartJSON, 
                    chartOutputFileName, 
                    chartType, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }


    public static class generateIOSPDFTask implements Runnable {
        private IPdfgen mApiObject; 
        private String htmlContent;
        private String targetFilePath;
        private IMethodResult mResult;

        public generateIOSPDFTask(IPdfgen obj, 
                String htmlContent, 
                String targetFilePath, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.htmlContent = htmlContent;
            this.targetFilePath = targetFilePath;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.generateIOSPDF(
                    htmlContent, 
                    targetFilePath, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }


    public static class mergeIOSPDFTask implements Runnable {
        private IPdfgen mApiObject; 
        private String listOfPaths;
        private String targetFilePath;
        private String masterPassword;
        private String password;
        private IMethodResult mResult;

        public mergeIOSPDFTask(IPdfgen obj, 
                String listOfPaths, 
                String targetFilePath, 
                String masterPassword, 
                String password, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.listOfPaths = listOfPaths;
            this.targetFilePath = targetFilePath;
            this.masterPassword = masterPassword;
            this.password = password;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.mergeIOSPDF(
                    listOfPaths, 
                    targetFilePath, 
                    masterPassword, 
                    password, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void getProperty(String propertyName, IMethodResult result) { 
        mPropertyBag.getProperty(propertyName, result);
    }

    public static class getPropertyTask implements Runnable {
        private IPdfgen mApiObject; 
        private String propertyName;
        private IMethodResult mResult;

        public getPropertyTask(IPdfgen obj, 
                String propertyName, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.propertyName = propertyName;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.getProperty(
                    propertyName, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void getProperties(List<String> arrayofNames, IMethodResult result) { 
        mPropertyBag.getProperties(arrayofNames, result);
    }

    public static class getPropertiesTask implements Runnable {
        private IPdfgen mApiObject; 
        private List<String> arrayofNames;
        private IMethodResult mResult;

        public getPropertiesTask(IPdfgen obj, 
                List<String> arrayofNames, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.arrayofNames = arrayofNames;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.getProperties(
                    arrayofNames, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void getAllProperties(IMethodResult result) { 
        mPropertyBag.getAllProperties(result);
    }

    public static class getAllPropertiesTask implements Runnable {
        private IPdfgen mApiObject; 
        private IMethodResult mResult;

        public getAllPropertiesTask(IPdfgen obj, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.getAllProperties(mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void setProperty(String propertyName, String propertyValue, IMethodResult result) { 
        mPropertyBag.setProperty(propertyName, propertyValue, result);
    }

    public static class setPropertyTask implements Runnable {
        private IPdfgen mApiObject; 
        private String propertyName;
        private String propertyValue;
        private IMethodResult mResult;

        public setPropertyTask(IPdfgen obj, 
                String propertyName, 
                String propertyValue, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.propertyName = propertyName;
            this.propertyValue = propertyValue;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.setProperty(
                    propertyName, 
                    propertyValue, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void setProperties(Map<String, String> propertyMap, IMethodResult result) { 
        mPropertyBag.setProperties(propertyMap, result);
    }

    public static class setPropertiesTask implements Runnable {
        private IPdfgen mApiObject; 
        private Map<String, String> propertyMap;
        private IMethodResult mResult;

        public setPropertiesTask(IPdfgen obj, 
                Map<String, String> propertyMap, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.propertyMap = propertyMap;
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.setProperties(
                    propertyMap, mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

}
