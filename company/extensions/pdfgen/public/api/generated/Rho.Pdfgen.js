
(function ($, rho, rhoUtil) {
    'use strict';

    var moduleNS = 'Rho.Pdfgen';
    var apiReq = rhoUtil.apiReqFor(moduleNS);


    // === Pdfgen class definition ===

    function Pdfgen() {
        var id = null;
        this.getId = function () {return id;};

        if (1 == arguments.length && arguments[0][rhoUtil.rhoIdParam()]) {
            if (moduleNS != arguments[0][rhoUtil.rhoClassParam()]) {
                throw "Wrong class instantiation!";
            }
            id = arguments[0][rhoUtil.rhoIdParam()];
        } else {
            id = rhoUtil.nextId();
            // constructor methods are following:
            
        }
    };

    // === Pdfgen instance properties ===

    rhoUtil.createPropsProxy(Pdfgen.prototype, [
        { propName: 'simpleStringProperty', propAccess: 'rw' }
    ], apiReq, function(){ return this.getId(); });

    // === Pdfgen instance methods ===

    rhoUtil.createMethodsProxy(Pdfgen.prototype, [
    
          // function(/* const rho::String& */ inputHTMLFileName, /* const rho::String& */ orientation, /* const rho::String& */ isSinglePDFRequired, /* const rho::String& */ password, /* optional function */ oResult)
          { methodName: 'generateAndroidPDF', nativeName: 'generateAndroidPDF', valueCallbackIndex: 4 }
    
          // function(/* const rho::String& */ chartJSON, /* const rho::String& */ chartOutputFileName, /* const rho::String& */ chartType, /* optional function */ oResult)
        , { methodName: 'generateAndroidPDFCharts', nativeName: 'generateAndroidPDFCharts', valueCallbackIndex: 3 }
    
          // function(/* const rho::String& */ htmlContent, /* const rho::String& */ targetFilePath, /* optional function */ oResult)
        , { methodName: 'generateIOSPDF', nativeName: 'generateIOSPDF', valueCallbackIndex: 2 }
    
          // function(/* const rho::String& */ listOfPaths, /* const rho::String& */ targetFilePath, /* const rho::String& */ masterPassword, /* const rho::String& */ password, /* optional function */ oResult)
        , { methodName: 'mergeIOSPDF', nativeName: 'mergeIOSPDF', valueCallbackIndex: 4 }
    
          // function(/* const rho::String& */ propertyName, /* optional function */ oResult)
        , { methodName: 'getProperty', nativeName: 'getProperty', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
    
          // function(/* const rho::Vector<rho::String>& */ arrayofNames, /* optional function */ oResult)
        , { methodName: 'getProperties', nativeName: 'getProperties', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
    
          // function(/* optional function */ oResult)
        , { methodName: 'getAllProperties', nativeName: 'getAllProperties', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
          // function(/* const rho::String& */ propertyName, /* const rho::String& */ propertyValue, /* optional function */ oResult)
        , { methodName: 'setProperty', nativeName: 'setProperty', valueCallbackIndex: 2 }
    
          // function(/* const rho::Hashtable<rho::String, rho::String>& */ propertyMap, /* optional function */ oResult)
        , { methodName: 'setProperties', nativeName: 'setProperties', valueCallbackIndex: 1 }
    
    ], apiReq, function(){ return this.getId(); });

    

    rhoUtil.createRawPropsProxy(Pdfgen.prototype, [
    ]);

    // === Pdfgen constants ===

    



    // === Pdfgen static properties ===

    rhoUtil.createPropsProxy(Pdfgen, [
    ], apiReq);

    // === Pdfgen static methods ===

    rhoUtil.createMethodsProxy(Pdfgen, [
    
          // function(/* optional function */ oResult)
          { methodName: 'enumerate', nativeName: 'enumerate', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
    ], apiReq);

    // === Pdfgen default instance support ===
    

        rhoUtil.createPropsProxy(Pdfgen, [
            { propName: 'defaultInstance:getDefault:setDefault', propAccess: 'rw', customSet: function(obj) { if(!obj || 'function' != typeof obj.getId){ throw 'Default object should provide getId method!' }; Pdfgen.setDefaultID(obj.getId()); } }
          , { propName: 'defaultID:getDefaultID:setDefaultID', propAccess: 'rw' }
        ], apiReq);

        Pdfgen.getId = function() {
            return Pdfgen.getDefaultID();
        }

        // === Pdfgen default instance properties ===

        rhoUtil.createPropsProxy(Pdfgen, [
            { propName: 'simpleStringProperty', propAccess: 'rw' }
        ], apiReq, function(){ return this.getId(); });

        // === Pdfgen default instance methods ===

        rhoUtil.createMethodsProxy(Pdfgen, [
        
              // function(/* const rho::String& */ inputHTMLFileName, /* const rho::String& */ orientation, /* const rho::String& */ isSinglePDFRequired, /* const rho::String& */ password, /* optional function */ oResult)
              { methodName: 'generateAndroidPDF', nativeName: 'generateAndroidPDF', valueCallbackIndex: 4 }
        
              // function(/* const rho::String& */ chartJSON, /* const rho::String& */ chartOutputFileName, /* const rho::String& */ chartType, /* optional function */ oResult)
            , { methodName: 'generateAndroidPDFCharts', nativeName: 'generateAndroidPDFCharts', valueCallbackIndex: 3 }
        
              // function(/* const rho::String& */ htmlContent, /* const rho::String& */ targetFilePath, /* optional function */ oResult)
            , { methodName: 'generateIOSPDF', nativeName: 'generateIOSPDF', valueCallbackIndex: 2 }
        
              // function(/* const rho::String& */ listOfPaths, /* const rho::String& */ targetFilePath, /* const rho::String& */ masterPassword, /* const rho::String& */ password, /* optional function */ oResult)
            , { methodName: 'mergeIOSPDF', nativeName: 'mergeIOSPDF', valueCallbackIndex: 4 }
        
              // function(/* const rho::String& */ propertyName, /* optional function */ oResult)
            , { methodName: 'getProperty', nativeName: 'getProperty', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
        
              // function(/* const rho::Vector<rho::String>& */ arrayofNames, /* optional function */ oResult)
            , { methodName: 'getProperties', nativeName: 'getProperties', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
        
              // function(/* optional function */ oResult)
            , { methodName: 'getAllProperties', nativeName: 'getAllProperties', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
        
              // function(/* const rho::String& */ propertyName, /* const rho::String& */ propertyValue, /* optional function */ oResult)
            , { methodName: 'setProperty', nativeName: 'setProperty', valueCallbackIndex: 2 }
        
              // function(/* const rho::Hashtable<rho::String, rho::String>& */ propertyMap, /* optional function */ oResult)
            , { methodName: 'setProperties', nativeName: 'setProperties', valueCallbackIndex: 1 }
        
        ], apiReq, function(){ return this.getId(); });

        // will reuse already defined methods
        rhoUtil.createRawPropsProxy(Pdfgen, [
        ]);

    

    rhoUtil.namespace(moduleNS, Pdfgen);

    

    

})(Rho.jQuery, Rho, Rho.util);
