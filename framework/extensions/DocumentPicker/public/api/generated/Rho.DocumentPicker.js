
(function ($, rho, rhoUtil) {
    'use strict';

    var moduleNS = 'Rho.DocumentPicker';
    var apiReq = rhoUtil.apiReqFor(moduleNS);


    // === DocumentPicker class definition ===

    function DocumentPicker() {
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

    // === DocumentPicker instance properties ===

    rhoUtil.createPropsProxy(DocumentPicker.prototype, [
        { propName: 'simpleStringProperty', propAccess: 'rw' }
    ], apiReq, function(){ return this.getId(); });

    // === DocumentPicker instance methods ===

    rhoUtil.createMethodsProxy(DocumentPicker.prototype, [
    
          // function(/* const rho::String& */ supportedExtensionList, /* optional function */ oResult)
          { methodName: 'pickDocument', nativeName: 'pickDocument', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
    
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

    

    rhoUtil.createRawPropsProxy(DocumentPicker.prototype, [
    ]);

    // === DocumentPicker constants ===

    



    // === DocumentPicker static properties ===

    rhoUtil.createPropsProxy(DocumentPicker, [
    ], apiReq);

    // === DocumentPicker static methods ===

    rhoUtil.createMethodsProxy(DocumentPicker, [
    
          // function(/* optional function */ oResult)
          { methodName: 'enumerate', nativeName: 'enumerate', persistentCallbackIndex: 0, valueCallbackIndex: 2 }
    
    ], apiReq);

    // === DocumentPicker default instance support ===
    

        rhoUtil.createPropsProxy(DocumentPicker, [
            { propName: 'defaultInstance:getDefault:setDefault', propAccess: 'rw', customSet: function(obj) { if(!obj || 'function' != typeof obj.getId){ throw 'Default object should provide getId method!' }; DocumentPicker.setDefaultID(obj.getId()); } }
          , { propName: 'defaultID:getDefaultID:setDefaultID', propAccess: 'rw' }
        ], apiReq);

        DocumentPicker.getId = function() {
            return DocumentPicker.getDefaultID();
        }

        // === DocumentPicker default instance properties ===

        rhoUtil.createPropsProxy(DocumentPicker, [
            { propName: 'simpleStringProperty', propAccess: 'rw' }
        ], apiReq, function(){ return this.getId(); });

        // === DocumentPicker default instance methods ===

        rhoUtil.createMethodsProxy(DocumentPicker, [
        
              // function(/* const rho::String& */ supportedExtensionList, /* optional function */ oResult)
              { methodName: 'pickDocument', nativeName: 'pickDocument', persistentCallbackIndex: 1, valueCallbackIndex: 3 }
        
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
        rhoUtil.createRawPropsProxy(DocumentPicker, [
        ]);

    

    rhoUtil.namespace(moduleNS, DocumentPicker);

    

    

})(Rho.jQuery, Rho, Rho.util);
