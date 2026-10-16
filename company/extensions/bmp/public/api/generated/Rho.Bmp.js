
(function ($, rho, rhoUtil) {
    'use strict';

    var moduleNS = 'Rho.Bmp';
    var apiReq = rhoUtil.apiReqFor(moduleNS);


    // === Bmp class definition ===

    function Bmp() {
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

    // === Bmp instance properties ===

    rhoUtil.createPropsProxy(Bmp.prototype, [
        { propName: 'simpleStringProperty', propAccess: 'rw' }
    ], apiReq, function(){ return this.getId(); });

    // === Bmp instance methods ===

    rhoUtil.createMethodsProxy(Bmp.prototype, [
    
          // function(/* optional function */ oResult)
          { methodName: 'sensorDataFetch', nativeName: 'sensorDataFetch', valueCallbackIndex: 0 }
    
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

    

    rhoUtil.createRawPropsProxy(Bmp.prototype, [
    ]);

    // === Bmp constants ===

    



    // === Bmp static properties ===

    rhoUtil.createPropsProxy(Bmp, [
    ], apiReq);

    // === Bmp static methods ===

    rhoUtil.createMethodsProxy(Bmp, [
    
          // function(/* optional function */ oResult)
          { methodName: 'enumerate', nativeName: 'enumerate', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
    ], apiReq);

    // === Bmp default instance support ===
    

        rhoUtil.createPropsProxy(Bmp, [
            { propName: 'defaultInstance:getDefault:setDefault', propAccess: 'rw', customSet: function(obj) { if(!obj || 'function' != typeof obj.getId){ throw 'Default object should provide getId method!' }; Bmp.setDefaultID(obj.getId()); } }
          , { propName: 'defaultID:getDefaultID:setDefaultID', propAccess: 'rw' }
        ], apiReq);

        Bmp.getId = function() {
            return Bmp.getDefaultID();
        }

        // === Bmp default instance properties ===

        rhoUtil.createPropsProxy(Bmp, [
            { propName: 'simpleStringProperty', propAccess: 'rw' }
        ], apiReq, function(){ return this.getId(); });

        // === Bmp default instance methods ===

        rhoUtil.createMethodsProxy(Bmp, [
        
              // function(/* optional function */ oResult)
              { methodName: 'sensorDataFetch', nativeName: 'sensorDataFetch', valueCallbackIndex: 0 }
        
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
        rhoUtil.createRawPropsProxy(Bmp, [
        ]);

    

    rhoUtil.namespace(moduleNS, Bmp);

    

    

})(Rho.jQuery, Rho, Rho.util);
