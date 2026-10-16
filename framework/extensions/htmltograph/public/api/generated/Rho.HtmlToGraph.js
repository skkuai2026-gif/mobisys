
(function ($, rho, rhoUtil) {
    'use strict';

    var moduleNS = 'Rho.HtmlToGraph';
    var apiReq = rhoUtil.apiReqFor(moduleNS);


    // === HtmlToGraph class definition ===

    function HtmlToGraph() {
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

    // === HtmlToGraph instance properties ===

    rhoUtil.createPropsProxy(HtmlToGraph.prototype, [
        { propName: 'simpleStringProperty', propAccess: 'rw' }
    ], apiReq, function(){ return this.getId(); });

    // === HtmlToGraph instance methods ===

    rhoUtil.createMethodsProxy(HtmlToGraph.prototype, [
    
          // function(/* optional function */ oResult)
          { methodName: 'getPlatformName', nativeName: 'getPlatformName', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
          // function(/* const rho::String& */ htmlString, /* optional function */ oResult)
        , { methodName: 'getGraphIOS', nativeName: 'getGraphIOS', valueCallbackIndex: 1 }
    
          // function(/* const rho::String& */ htmlString, /* optional function */ oResult)
        , { methodName: 'getGraphAndroid', nativeName: 'getGraphAndroid', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
    
          // function(/* int */ a, /* int */ b, /* optional function */ oResult)
        , { methodName: 'calcSumm', nativeName: 'calcSumm', valueCallbackIndex: 2 }
    
          // function(/* const rho::String& */ a, /* const rho::String& */ b, /* optional function */ oResult)
        , { methodName: 'joinStrings', nativeName: 'joinStrings', valueCallbackIndex: 2 }
    
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

    

    rhoUtil.createRawPropsProxy(HtmlToGraph.prototype, [
    ]);

    // === HtmlToGraph constants ===

    



    // === HtmlToGraph static properties ===

    rhoUtil.createPropsProxy(HtmlToGraph, [
    ], apiReq);

    // === HtmlToGraph static methods ===

    rhoUtil.createMethodsProxy(HtmlToGraph, [
    
          // function(/* optional function */ oResult)
          { methodName: 'enumerate', nativeName: 'enumerate', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
    ], apiReq);

    // === HtmlToGraph default instance support ===
    

        rhoUtil.createPropsProxy(HtmlToGraph, [
            { propName: 'defaultInstance:getDefault:setDefault', propAccess: 'rw', customSet: function(obj) { if(!obj || 'function' != typeof obj.getId){ throw 'Default object should provide getId method!' }; HtmlToGraph.setDefaultID(obj.getId()); } }
          , { propName: 'defaultID:getDefaultID:setDefaultID', propAccess: 'rw' }
        ], apiReq);

        HtmlToGraph.getId = function() {
            return HtmlToGraph.getDefaultID();
        }

        // === HtmlToGraph default instance properties ===

        rhoUtil.createPropsProxy(HtmlToGraph, [
            { propName: 'simpleStringProperty', propAccess: 'rw' }
        ], apiReq, function(){ return this.getId(); });

        // === HtmlToGraph default instance methods ===

        rhoUtil.createMethodsProxy(HtmlToGraph, [
        
              // function(/* optional function */ oResult)
              { methodName: 'getPlatformName', nativeName: 'getPlatformName', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
        
              // function(/* const rho::String& */ htmlString, /* optional function */ oResult)
            , { methodName: 'getGraphIOS', nativeName: 'getGraphIOS', valueCallbackIndex: 1 }
        
              // function(/* const rho::String& */ htmlString, /* optional function */ oResult)
            , { methodName: 'getGraphAndroid', nativeName: 'getGraphAndroid', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
        
              // function(/* int */ a, /* int */ b, /* optional function */ oResult)
            , { methodName: 'calcSumm', nativeName: 'calcSumm', valueCallbackIndex: 2 }
        
              // function(/* const rho::String& */ a, /* const rho::String& */ b, /* optional function */ oResult)
            , { methodName: 'joinStrings', nativeName: 'joinStrings', valueCallbackIndex: 2 }
        
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
        rhoUtil.createRawPropsProxy(HtmlToGraph, [
        ]);

    

    rhoUtil.namespace(moduleNS, HtmlToGraph);

    

    

})(Rho.jQuery, Rho, Rho.util);
