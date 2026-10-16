
#include "BGServiceBase.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "BGService"

#include "api_generator/RubyResultConvertor.h"

#include "ruby/ext/rho/rhoruby.h"
#include "common/StringConverter.h"
#include "common/AutoPointer.h"

using namespace rho;
using namespace rho::common;
using namespace rho::apiGenerator;

extern "C"
{
void rho_os_impl_performOnUiThread(rho::common::IRhoRunnable* pTask);
VALUE getRuby_BGService_Module();


VALUE rb_BGService_s_default(VALUE klass)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();

    return rho_ruby_create_object_with_id( klass, strDefaultID.c_str() );
}

VALUE rb_BGService_s_setDefault(VALUE klass, VALUE valObj)
{
    const char* szID = rho_ruby_get_object_id( valObj );
    rho::CBGServiceFactoryBase::getBGServiceSingletonS()->setDefaultID(szID);

    return rho_ruby_get_NIL();
}


static void string_iter(const char* szVal, int valueLen, void* par)
{
    rho::Vector<rho::String>& ar = *((rho::Vector<rho::String>*)(par));
    ar.addElement( rho::String(szVal,valueLen) );
}

static void getStringArrayFromValue(VALUE val, rho::Vector<rho::String>& res)
{
    rho_ruby_enum_strary_json(val, string_iter, &res);
}

static void hash_eachstr(const char* szName, const char* szVal, int valueLen, void* par)
{
    rho::Hashtable<rho::String, rho::String>& hash = *((rho::Hashtable<rho::String, rho::String>*)(par));
    hash.put( szName, rho::String(szVal,valueLen) );
}

static void getStringHashFromValue(VALUE val, rho::Hashtable<rho::String, rho::String>& res)
{
    rho_ruby_enum_strhash_json(val, hash_eachstr, &res);
}
    
static rho::String getStringObjectFromValue(VALUE val)
{
    return rho::String(getStringFromValue(val),getStringLenFromValue(val));
}


static VALUE _api_generator_BGService_getSimpleStringProperty(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(0) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( pObj, &rho::IBGService::getSimpleStringProperty,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getSimpleStringProperty(  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_getSimpleStringProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_getSimpleStringProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_getSimpleStringProperty(argc, argv, pObj);
}


static VALUE _api_generator_BGService_setSimpleStringProperty(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IBGService::setSimpleStringProperty, arg0,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->setSimpleStringProperty( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_setSimpleStringProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_setSimpleStringProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_setSimpleStringProperty(argc, argv, pObj);
}


VALUE rb_s_BGService_enumerate(int argc, VALUE *argv)
{
    rho::apiGenerator::CMethodResult oRes;


    oRes.setParamName( "result" );
    oRes.setRubyObjectClass( getRuby_BGService_Module() );
    oRes.setRequestedType(CMethodResult::eStringArray);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( rho::CBGServiceFactoryBase::getBGServiceSingletonS(), &rho::IBGServiceSingleton::enumerate,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->enumerate(  oRes );
    }
    
    return oRes.toRuby();
}






static VALUE _api_generator_BGService_startBackgroundService(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IBGService::startBackgroundService, arg0,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->startBackgroundService( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_startBackgroundService(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_startBackgroundService(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_startBackgroundService(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_startBackgroundService(argc, argv, pObj);
}


static VALUE _api_generator_BGService_stopBackgroundService(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(0) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( pObj, &rho::IBGService::stopBackgroundService,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->stopBackgroundService(  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_stopBackgroundService(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_stopBackgroundService(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_stopBackgroundService(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_stopBackgroundService(argc, argv, pObj);
}


static VALUE _api_generator_BGService_checkBackgroundServiceStatus(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(0) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( pObj, &rho::IBGService::checkBackgroundServiceStatus,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->checkBackgroundServiceStatus(  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_checkBackgroundServiceStatus(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_checkBackgroundServiceStatus(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_checkBackgroundServiceStatus(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_checkBackgroundServiceStatus(argc, argv, pObj);
}


static VALUE _api_generator_BGService_getProperty(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IBGService::getProperty, arg0,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getProperty( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_getProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_getProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_getProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_getProperty(argc, argv, pObj);
}


static VALUE _api_generator_BGService_getProperties(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eStringHash);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::Vector<rho::String> arg0;
    if ( argc > 0 )
    {
        if ( rho_ruby_is_array(argv[0]) )
        {
            rho::String res;
            rho_value_to_typed_array<rho::String>(argv[0], arg0, res);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "array" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IBGService::getProperties, arg0,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getProperties( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_getProperties(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_getProperties(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_getProperties(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_getProperties(argc, argv, pObj);
}


static VALUE _api_generator_BGService_getAllProperties(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eStringHash);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( pObj, &rho::IBGService::getAllProperties,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getAllProperties(  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_getAllProperties(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_getAllProperties(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_getAllProperties(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_getAllProperties(argc, argv, pObj);
}


static VALUE _api_generator_BGService_setProperty(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 2;
    if ( argc == 1 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    rho::String arg1 = "";
    if ( argc > 1 )
    {
        if ( rho_ruby_is_string(argv[1]) )
        {
            arg1 = getStringObjectFromValue(argv[1]);
        }
        else if (!rho_ruby_is_NIL(argv[1]))
        {
            oRes.setArgError("Type error: argument " "1" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor3( pObj, &rho::IBGService::setProperty, arg0, arg1,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->setProperty( arg0, arg1,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_setProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_setProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_setProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_setProperty(argc, argv, pObj);
}


static VALUE _api_generator_BGService_setProperties(int argc, VALUE *argv, rho::IBGService* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::Hashtable<rho::String, rho::String> arg0;
    if ( argc > 0 )
    {
        if ( rho_ruby_is_hash(argv[0]) )
        {
            rho::String res;
            rho_value_to_typed_hash<rho::String, rho::String>(argv[0], arg0, res);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "hash" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IBGService::setProperties, arg0,  oRes );
        rho::CBGServiceFactoryBase::getBGServiceSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->setProperties( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_BGService_setProperties(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IBGService* pObj =  rho::CBGServiceFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_BGService_setProperties(argc, argv, pObj);

    return res;
}



VALUE rb_s_BGService_def_setProperties(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CBGServiceFactoryBase::getBGServiceSingletonS()->getDefaultID();
    rho::IBGService* pObj = rho::CBGServiceFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_BGService_setProperties(argc, argv, pObj);
}



}