
(function ($, rho, rhoUtil) {
    'use strict';

    var moduleNS = 'Rho.BGService';
    var apiReq = rhoUtil.apiReqFor(moduleNS);


    // === BGService class definition ===

    function BGService() {
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

    // === BGService instance properties ===

    rhoUtil.createPropsProxy(BGService.prototype, [
        { propName: 'simpleStringProperty', propAccess: 'rw' }
    ], apiReq, function(){ return this.getId(); });

    // === BGService instance methods ===

    rhoUtil.createMethodsProxy(BGService.prototype, [
    
          // function(/* const rho::String& */ bgServiceRubyFunc, /* optional function */ oResult)
          { methodName: 'startBackgroundService', nativeName: 'startBackgroundService', valueCallbackIndex: 1 }
    
          // function(/* optional function */ oResult)
        , { methodName: 'stopBackgroundService', nativeName: 'stopBackgroundService', valueCallbackIndex: 0 }
    
          // function(/* optional function */ oResult)
        , { methodName: 'checkBackgroundServiceStatus', nativeName: 'checkBackgroundServiceStatus', valueCallbackIndex: 0 }
    
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

    

    rhoUtil.createRawPropsProxy(BGService.prototype, [
    ]);

    // === BGService constants ===

    



    // === BGService static properties ===

    rhoUtil.createPropsProxy(BGService, [
    ], apiReq);

    // === BGService static methods ===

    rhoUtil.createMethodsProxy(BGService, [
    
          // function(/* optional function */ oResult)
          { methodName: 'enumerate', nativeName: 'enumerate', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
    ], apiReq);

    // === BGService default instance support ===
    

        rhoUtil.createPropsProxy(BGService, [
            { propName: 'defaultInstance:getDefault:setDefault', propAccess: 'rw', customSet: function(obj) { if(!obj || 'function' != typeof obj.getId){ throw 'Default object should provide getId method!' }; BGService.setDefaultID(obj.getId()); } }
          , { propName: 'defaultID:getDefaultID:setDefaultID', propAccess: 'rw' }
        ], apiReq);

        BGService.getId = function() {
            return BGService.getDefaultID();
        }

        // === BGService default instance properties ===

        rhoUtil.createPropsProxy(BGService, [
            { propName: 'simpleStringProperty', propAccess: 'rw' }
        ], apiReq, function(){ return this.getId(); });

        // === BGService default instance methods ===

        rhoUtil.createMethodsProxy(BGService, [
        
              // function(/* const rho::String& */ bgServiceRubyFunc, /* optional function */ oResult)
              { methodName: 'startBackgroundService', nativeName: 'startBackgroundService', valueCallbackIndex: 1 }
        
              // function(/* optional function */ oResult)
            , { methodName: 'stopBackgroundService', nativeName: 'stopBackgroundService', valueCallbackIndex: 0 }
        
              // function(/* optional function */ oResult)
            , { methodName: 'checkBackgroundServiceStatus', nativeName: 'checkBackgroundServiceStatus', valueCallbackIndex: 0 }
        
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
        rhoUtil.createRawPropsProxy(BGService, [
        ]);

    

    rhoUtil.namespace(moduleNS, BGService);

    

    

})(Rho.jQuery, Rho, Rho.util);
