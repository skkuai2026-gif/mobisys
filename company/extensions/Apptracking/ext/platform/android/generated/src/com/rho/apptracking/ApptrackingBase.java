package com.rho.apptracking;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.RhoApiObject;

import com.rhomobile.rhodes.api.RhoApiPropertyBag; 

public class ApptrackingBase extends RhoApiObject {

    private RhoApiPropertyBag mPropertyBag;
    public Map<String, String> getPropertiesMap() {
        return mPropertyBag.getPropertiesMap();
    }
    public ApptrackingBase(String id) {
        super(id);

        mPropertyBag = new RhoApiPropertyBag(id);
    }

    public void getSimpleStringProperty(IMethodResult result) {
                     
        getProperty("simpleStringProperty", result);
    }

    public static class getSimpleStringPropertyTask implements Runnable {
        private IApptracking mApiObject; 
        private IMethodResult mResult;

        public getSimpleStringPropertyTask(IApptracking obj, 
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
        private IApptracking mApiObject; 
        private String simpleStringProperty;
        private IMethodResult mResult;

        public setSimpleStringPropertyTask(IApptracking obj, 
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


    public static class requestAppTrackingPermissionTask implements Runnable {
        private IApptracking mApiObject; 
        private IMethodResult mResult;

        public requestAppTrackingPermissionTask(IApptracking obj, 
                IMethodResult result) {
            this.mApiObject = obj; 
            this.mResult = result;
        }

        @Override
        public void run() {
            try {
                mApiObject.requestAppTrackingPermission(mResult);
            } catch (Throwable ex) {
                mResult.set(ex);
            }
        }
    }

    public void getProperty(String propertyName, IMethodResult result) { 
        mPropertyBag.getProperty(propertyName, result);
    }

    public static class getPropertyTask implements Runnable {
        private IApptracking mApiObject; 
        private String propertyName;
        private IMethodResult mResult;

        public getPropertyTask(IApptracking obj, 
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
        private IApptracking mApiObject; 
        private List<String> arrayofNames;
        private IMethodResult mResult;

        public getPropertiesTask(IApptracking obj, 
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
        private IApptracking mApiObject; 
        private IMethodResult mResult;

        public getAllPropertiesTask(IApptracking obj, 
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
        private IApptracking mApiObject; 
        private String propertyName;
        private String propertyValue;
        private IMethodResult mResult;

        public setPropertyTask(IApptracking obj, 
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
        private IApptracking mApiObject; 
        private Map<String, String> propertyMap;
        private IMethodResult mResult;

        public setPropertiesTask(IApptracking obj, 
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
